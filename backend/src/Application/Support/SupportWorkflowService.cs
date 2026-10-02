using System.Text.Json;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Support;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Support;

public sealed class SupportWorkflowService(IAppDbContext db, ISupportWorkflowClient agent,
    SupportService support, SupportWorkflowPolicy policy)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    public const int MaxAttempts = 3;

    public async Task<WorkflowReviewDto> GetAsync(Guid id, Guid actor, UserRole role, CancellationToken ct)
    {
        var run = await Run(id, ct);
        AuthorizeRead(run, actor, role);
        return View(run, role);
    }

    public async Task<WorkflowReviewDto?> ForTicketAsync(Guid ticketId, Guid actor, UserRole role, CancellationToken ct)
    {
        await support.GetAsync(actor, role, ticketId, ct);
        var run = await db.AgentWorkflowRuns.SingleOrDefaultAsync(r => r.TicketId == ticketId, ct);
        return run is null ? null : View(run, role);
    }

    public async Task<WorkflowReviewDto> StartAsync(Guid ticketId, Guid actor, UserRole role, CancellationToken ct)
    {
        await Staff(actor, role, ct);
        var ticket = await db.SupportTickets.SingleOrDefaultAsync(t => t.Id == ticketId, ct)
            ?? throw new NotFoundException("SupportTicket", ticketId);
        var run = await db.AgentWorkflowRuns.SingleOrDefaultAsync(r => r.TicketId == ticketId, ct);
        if (run is null)
        {
            run = new AgentWorkflowRun { TicketId = ticket.Id, DriverId = ticket.DriverId };
            db.AgentWorkflowRuns.Add(run);
            Audit(run, "Created", "Staff requested support analysis.", actor);
            await Save(ct);
        }
        return View(run, role);
    }

    // Claim is persisted before contacting Python. A crash leaves a lease that
    // expires; only read-only analysis is replayed, never financial execution.
    public async Task ProcessAsync(Guid id, CancellationToken ct)
    {
        var run = await Run(id, ct);
        var now = DateTimeOffset.UtcNow;
        if (run.Status != AgentWorkflowStatus.Running || run.NextAttemptAt > now || run.LeaseUntil > now) return;
        if (run.Attempts >= MaxAttempts)
        {
            Fail(run, "Analysis could not complete after three attempts."); await Save(ct); return;
        }
        run.Attempts++; run.LeaseUntil = now.AddSeconds(90);
        Audit(run, "AttemptStarted", $"ValidationSupportAgent attempt {run.Attempts}.");
        await Save(ct);

        var ticket = await db.SupportTickets.AsNoTracking().SingleOrDefaultAsync(t => t.Id == run.TicketId, ct);
        if (ticket is null) { Fail(run, "Support ticket is missing."); await Save(ct); return; }
        if (ticket.Status is "Withdrawn" or "Closed")
        { Fail(run, "Ticket is closed or withdrawn."); await Save(ct); return; }
        var input = await Input(run, ticket, ct);
        run.TicketVersion = ticket.Version;
        run.InputJson = JsonSerializer.Serialize(input, Json);
        run.Action = input.Action;
        run.Amount = input.Action == "Refund" ? ticket.RequestedRefundAmount : null;
        run.ApprovalRequired = input.ApprovalRequired;
        Audit(run, "Validated", "Backend record checks completed.");
        await Save(ct);
        if (input.ValidationResults.Any(f => f.Outcome == "Error"))
        { Fail(run, "Linked records failed validation. Correct the records and request revision."); await Save(ct); return; }

        var output = await agent.RunAsync(input, ct);
        // Never overwrite a ticket decision made while the model was running.
        var currentTicket = await db.SupportTickets.AsNoTracking().SingleAsync(t => t.Id == ticket.Id, ct);
        if (currentTicket.Version != run.TicketVersion)
        {
            run.Status = AgentWorkflowStatus.RevisionRequested; run.LeaseUntil = null;
            Audit(run, "StaleInput", "Ticket changed during analysis; revision required.");
            await Save(ct); return;
        }
        if (!ValidOutput(output, run))
        {
            run.LeaseUntil = null;
            run.Error = "Agent unavailable or returned an invalid result. Ordinary support actions remain available.";
            if (run.Attempts >= MaxAttempts) Fail(run, run.Error);
            else
            {
                run.NextAttemptAt = DateTimeOffset.UtcNow.AddSeconds(5 * run.Attempts);
                Audit(run, "RetryScheduled", run.Error);
            }
            await Save(ct); return;
        }
        run.ResultJson = JsonSerializer.Serialize(output, Json);
        run.Error = null; run.LeaseUntil = null;
        // The agent's prose cannot set status, approval, action or amount.
        run.Status = run.ApprovalRequired ? AgentWorkflowStatus.PendingApproval : AgentWorkflowStatus.Completed;
        run.CompletedAt = run.ApprovalRequired ? null : DateTimeOffset.UtcNow;
        Audit(run, "AnalysisCompleted", run.ApprovalRequired ? "Awaiting human approval." : "Read-only analysis completed; no financial action executed.");
        await Save(ct);
    }

    public async Task<WorkflowReviewDto> DecideAsync(Guid id, Guid actor, UserRole role,
        WorkflowDecisionRequest request, bool approve, CancellationToken ct)
    {
        await Staff(actor, role, ct);
        ValidateNote(request.Note);
        var run = await Run(id, ct);
        CheckVersion(run, request.Version);
        if (run.Status != AgentWorkflowStatus.PendingApproval)
            throw new PaymentConflictException("This workflow is not awaiting approval.");
        var ticket = await db.SupportTickets.SingleAsync(t => t.Id == run.TicketId, ct);
        var fresh = await Input(run, ticket, ct);
        var original = Deserialize<SupportWorkflowInput>(run.InputJson)!;
        if (ticket.Version != run.TicketVersion || ticket.Status is "Closed" or "Withdrawn" ||
            JsonSerializer.Serialize(fresh.Invoice, Json) != JsonSerializer.Serialize(original.Invoice, Json) ||
            JsonSerializer.Serialize(fresh.Session, Json) != JsonSerializer.Serialize(original.Session, Json))
        {
            run.Status = AgentWorkflowStatus.RevisionRequested;
            Audit(run, "StaleApproval", "Records changed; reanalysis is required.", actor);
            await Save(ct);
            throw new PaymentConflictException("Records changed since analysis. Request revision before reviewing.");
        }
        if (approve && fresh.ValidationResults.Any(f => f.Outcome == "Error"))
            throw new InvalidOperationException("Record validation failed. Request revision.");
        if (approve && fresh.ValidationResults.Any(f => f.Code == "METER_DISCREPANCY" && f.Outcome == "Review") && role != UserRole.Admin)
            throw new ForbiddenAccessException();
        // Stage the same audited refund operation used by the normal support UI.
        if (run.Action == "Refund")
            await support.ApplyRefundReviewAsync(actor, role, ticket.Id, new(approve, request.Note), ct);
        run.Decision = approve ? "Approved" : "Rejected";
        run.ReviewedBy = actor; run.ReviewedAt = DateTimeOffset.UtcNow;
        if (approve) { run.Status = AgentWorkflowStatus.Approved; Audit(run, "Approved", "Human decision recorded.", actor); }
        run.Status = approve ? AgentWorkflowStatus.Completed : AgentWorkflowStatus.Rejected;
        run.CompletedAt = DateTimeOffset.UtcNow;
        Audit(run, "DecisionApplied", approve && run.Action == "Refund" ? "Refund, invoice accounting and loyalty reversal applied." : run.Decision, actor);
        await Save(ct);
        return View(run, role);
    }

    public async Task<WorkflowReviewDto> ReviseAsync(Guid id, Guid actor, UserRole role,
        WorkflowDecisionRequest request, CancellationToken ct)
    {
        await Staff(actor, role, ct); ValidateNote(request.Note);
        if (string.IsNullOrWhiteSpace(request.Note)) throw new ArgumentException("Explain what should be revised.");
        var run = await Run(id, ct); CheckVersion(run, request.Version);
        if (run.Status is not (AgentWorkflowStatus.PendingApproval or AgentWorkflowStatus.Failed or AgentWorkflowStatus.RevisionRequested))
            throw new PaymentConflictException("Only pending, failed or stale workflows can be revised.");
        run.Status = AgentWorkflowStatus.RevisionRequested;
        Audit(run, "RevisionRequested", request.Note.Trim(), actor);
        run.Revision++; run.RevisionNote = request.Note.Trim(); run.Attempts = 0;
        run.Status = AgentWorkflowStatus.Running; run.NextAttemptAt = DateTimeOffset.UtcNow;
        run.LeaseUntil = null; run.Error = null; run.ResultJson = null; run.InputJson = null;
        run.CompletedAt = null; run.Decision = null; run.ReviewedAt = null; run.ReviewedBy = null;
        run.Action = "None"; run.Amount = null; run.ApprovalRequired = false;
        Audit(run, "RevisionQueued", "Read-only analysis queued for the revised records.", actor);
        await Save(ct); return View(run, role);
    }

    private async Task<SupportWorkflowInput> Input(AgentWorkflowRun run, SupportTicket ticket, CancellationToken ct)
    {
        var invoice = ticket.InvoiceId is Guid id ? await db.PaymentInvoices.AsNoTracking().Include(i => i.Session)
            .SingleOrDefaultAsync(i => i.Id == id, ct) : null;
        var findings = WorkflowValidation.Evaluate(ticket, invoice).ToList();
        if (invoice?.Session is { EndTime: not null } recordedSession && invoice.DriverId == ticket.DriverId)
        {
            var reservation = await db.Reservations.AsNoTracking().SingleOrDefaultAsync(r => r.Id == recordedSession.ReservationId, ct);
            var charger = reservation is null ? null : await db.Chargers.AsNoTracking().SingleOrDefaultAsync(c => c.Id == reservation.ChargerId, ct);
            if (charger is null) findings.Add(new("ENERGY_BASELINE", "Info", "Charger record unavailable; automatic energy cannot be independently recalculated."));
            else
            {
                var expected = decimal.Round(charger.PowerKw * (decimal)(recordedSession.EndTime.Value - recordedSession.StartTime).TotalHours, 2, MidpointRounding.AwayFromZero);
                findings.Add(expected == recordedSession.AutoCalculatedKwh
                    ? new("ENERGY_BASELINE", "Pass", "Automatic energy matches current charger power multiplied by duration.")
                    : new("ENERGY_BASELINE", "Review", "Automatic energy differs from current charger power multiplied by duration. Verify historical power before approval."));
            }
        }
        // Never send another customer's record, even if corrupted linking data exists.
        if (invoice?.DriverId != ticket.DriverId) invoice = null;
        var session = invoice?.Session;
        var loyalty = await db.LoyaltyAccounts.AsNoTracking().SingleOrDefaultAsync(a => a.DriverId == ticket.DriverId, ct);
        var messages = await db.SupportMessages.AsNoTracking().Where(m => m.TicketId == ticket.Id && !m.IsSystem)
            .OrderByDescending(m => m.CreatedAt).Take(12).Select(m => m.Body).ToArrayAsync(ct);
        var refund = ticket.RefundStatus == "PendingReview" && ticket.RequestedRefundAmount is > 0;
        var required = (refund && policy.RefundRequiresApproval(ticket.RequestedRefundAmount!.Value)) || findings.Any(f => f.Outcome == "Review");
        return new(run.Id, run.Revision, run.Objective,
            new(ticket.Id, ticket.DriverId, ticket.Subject, ticket.Description, ticket.Category, ticket.Priority, messages, ticket.InvoiceId, ticket.RequestedRefundAmount, ticket.RefundStatus),
            session is null ? null : new(session.Id, session.AutoCalculatedKwh, session.StaffOverriddenKwh, session.FinalEnergyDeliveredKwh, session.StartTime, session.EndTime),
            invoice is null ? null : new(invoice.Id, invoice.SessionId, invoice.DriverId, invoice.Status.ToString(), invoice.GrossAmount, invoice.DiscountAmount, invoice.AdvanceDeducted, invoice.NetAmountDue, invoice.RefundedAmount, invoice.TariffPerKwh),
            loyalty is null ? null : new(loyalty.DriverId, loyalty.PointsBalance), findings.ToArray(), required, refund ? "Refund" : "None", run.RevisionNote);
    }

    public static bool ValidOutput(SupportWorkflowOutput? output, AgentWorkflowRun run)
    {
        var s = output?.Suggestion;
        return output?.WorkflowId == run.Id && output.Revision == run.Revision && s is not null &&
            new[] { "Charging", "Reservation", "Payment", "Refund", "Technical", "Membership", "Other" }.Contains(s.Category) &&
            new[] { "Low", "Medium", "High", "Urgent" }.Contains(s.Priority) &&
            !string.IsNullOrWhiteSpace(s.Explanation) && s.Explanation.Length <= 4000 &&
            !string.IsNullOrWhiteSpace(s.DraftReply) && s.DraftReply.Length <= 4000 &&
            output.Plan is { Length: > 0 and <= 10 } && output.CompletedSteps is { Length: > 0 and <= 15 } &&
            output.ToolResults is { Length: > 0 and <= 10 } &&
            output.Plan.All(p => p is not null && p.Agent == "ValidationSupportAgent" && AllowedTool(p.Tool)) &&
            output.ToolResults.All(t => t is not null && AllowedTool(t.Tool) && !string.IsNullOrWhiteSpace(t.Outcome) && t.Outcome.Length <= 1000) &&
            output.CompletedSteps.All(s => s is not null && s.Agent is "CoordinatorAgent" or "ValidationSupportAgent" &&
                (s.Tool is null || AllowedTool(s.Tool)) && s.Step is { Length: > 0 and <= 100 } &&
                s.Outcome is { Length: > 0 and <= 1000 } && s.CompletedAt >= s.StartedAt);
    }
    private static bool AllowedTool(string tool) => tool is "get_support_ticket" or "get_charging_session" or "get_invoice" or "get_payment" or "calculate_meter_discrepancy" or "get_loyalty_account";
    private static WorkflowReviewDto View(AgentWorkflowRun run, UserRole role)
    {
        var staff = role is UserRole.Admin or UserRole.SupportManager;
        return new(new(run.Id, run.TicketId, run.Status.ToString(), run.Revision, run.ApprovalRequired,
            run.Action, run.Amount, run.Currency, run.UpdatedAt,
            run.Error is null ? null : staff ? run.Error : "Analysis needs staff attention. You can continue using support.",
            run.Decision, staff ? Deserialize<SupportWorkflowOutput>(run.ResultJson) : null,
            staff ? Deserialize<SupportWorkflowInput>(run.InputJson)?.ValidationResults : null,
            staff ? Deserialize<WorkflowAudit[]>(run.AuditJson) : null), run.Version);
    }
    private static T? Deserialize<T>(string? value) => value is null ? default : JsonSerializer.Deserialize<T>(value, Json);
    private async Task<AgentWorkflowRun> Run(Guid id, CancellationToken ct) =>
        await db.AgentWorkflowRuns.SingleOrDefaultAsync(r => r.Id == id, ct) ?? throw new NotFoundException("AgentWorkflowRun", id);
    private async Task Staff(Guid actor, UserRole role, CancellationToken ct)
    {
        if (role is not (UserRole.Admin or UserRole.SupportManager) ||
            !await db.Users.AnyAsync(u => u.Id == actor && u.Role == role && u.IsActive, ct)) throw new ForbiddenAccessException();
    }
    private static void AuthorizeRead(AgentWorkflowRun run, Guid actor, UserRole role)
    { if (role == UserRole.Driver ? run.DriverId != actor : role is not (UserRole.Admin or UserRole.SupportManager)) throw new ForbiddenAccessException(); }
    private static void ValidateNote(string? note) { if (note?.Length > 1000) throw new ArgumentException("Notes must be at most 1000 characters."); }
    private static void CheckVersion(AgentWorkflowRun run, Guid version)
    { if (version != run.Version) throw new PaymentConflictException("Workflow changed. Refresh before reviewing."); }
    public static void Audit(AgentWorkflowRun run, string name, string detail, Guid? actor = null)
    {
        var entries = Deserialize<List<WorkflowAudit>>(run.AuditJson) ?? [];
        entries.Add(new(DateTimeOffset.UtcNow, run.Revision, name, detail, actor));
        run.AuditJson = JsonSerializer.Serialize(entries, Json);
        run.Version = Guid.NewGuid(); run.UpdatedAt = DateTimeOffset.UtcNow;
    }
    private static void Fail(AgentWorkflowRun run, string error)
    { run.Status = AgentWorkflowStatus.Failed; run.Error = error; run.LeaseUntil = null; run.CompletedAt = DateTimeOffset.UtcNow; Audit(run, "Failed", error); }
    private async Task Save(CancellationToken ct)
    {
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new PaymentConflictException("Workflow or financial records changed concurrently. Refresh and retry."); }
        catch (DbUpdateException ex) when (ex.InnerException?.GetType().GetProperty("SqlState")?.GetValue(ex.InnerException)?.ToString() == "23505")
        { throw new PaymentConflictException("Workflow already exists for this ticket. Refresh to retrieve it."); }
    }
}
