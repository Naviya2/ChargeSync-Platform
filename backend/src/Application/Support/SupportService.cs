using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Enums;
using Domain.Support;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Support;

public sealed class SupportService(IAppDbContext db)
{
    public const decimal RefundApprovalThresholdLkr = 15m;
    private static readonly string[] Categories = ["Charging", "Reservation", "Payment", "Refund", "Technical", "Membership", "Other"];
    private static readonly string[] Statuses = ["Open", "InProgress", "Resolved", "Closed"];

    public async Task<List<SupportTicketDto>> ListAsync(Guid userId, UserRole role, string? status, CancellationToken ct)
    {
        IQueryable<SupportTicket> query = db.SupportTickets.AsNoTracking();
        if (role == UserRole.Driver) query = query.Where(t => t.DriverId == userId);
        else if (role is not (UserRole.SupportManager or UserRole.Admin)) throw new ForbiddenAccessException();
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(t => t.Status == status);
        var rows = await query.Include(t => t.Messages).OrderByDescending(t => t.UpdatedAt).Take(200).ToListAsync(ct);
        return await MapAsync(rows, ct);
    }

    public async Task<SupportTicketDto> GetAsync(Guid userId, UserRole role, Guid id, CancellationToken ct)
    {
        var ticket = await TicketAsync(id, ct);
        AuthorizeRead(ticket, userId, role);
        return (await MapAsync([ticket], ct))[0];
    }

    public async Task<SupportTicketDto> CreateAsync(Guid driverId, CreateTicketRequest request, CancellationToken ct)
    {
        await ActiveUser(driverId, UserRole.Driver, ct);
        var category = request.Category?.Trim();
        if (!Categories.Contains(category)) throw new ArgumentException("Choose a valid support category.");
        ValidateText(request.Subject, 5, 150, "Subject");
        ValidateText(request.Description, 10, 4000, "Description");
        if (category != "Refund" && request.RequestedRefundAmount != null)
            throw new ArgumentException("Refund amount is only valid for Refund tickets.");
        if (request.InvoiceId is Guid linkedInvoice && !await db.PaymentInvoices.AnyAsync(i => i.Id == linkedInvoice && i.DriverId == driverId, ct))
            throw new NotFoundException("PaymentInvoice", linkedInvoice);
        if (category == "Refund")
        {
            if (request.InvoiceId is null || request.RequestedRefundAmount is null or <= 0)
                throw new ArgumentException("A paid invoice and positive refund amount are required.");
            if (decimal.Round(request.RequestedRefundAmount.Value, 2) != request.RequestedRefundAmount.Value)
                throw new ArgumentException("Refund amounts must use whole cents.");
            var invoice = await db.PaymentInvoices.AsNoTracking().SingleOrDefaultAsync(i => i.Id == request.InvoiceId && i.DriverId == driverId, ct)
                ?? throw new NotFoundException("PaymentInvoice", request.InvoiceId.Value);
            var paidAmount = invoice.GrossAmount - invoice.DiscountAmount - invoice.RefundedAmount;
            if (invoice.Status != InvoiceStatus.Paid || request.RequestedRefundAmount > paidAmount)
                throw new ArgumentException("Refund must reference your paid invoice and cannot exceed its paid amount.");
            if (await db.SupportTickets.AnyAsync(t => t.InvoiceId == request.InvoiceId &&
                    (t.RefundStatus == "PendingReview" || t.RefundStatus == "Approved"), ct))
                throw new PaymentConflictException("A refund for this invoice is already pending or approved.");
        }
        var priority = Triage(category!, request.Subject, request.Description, request.RequestedRefundAmount);
        var ticket = new SupportTicket { DriverId = driverId, Category = category!, Subject = request.Subject.Trim(),
            Description = request.Description.Trim(), Priority = priority, InvoiceId = request.InvoiceId,
            RequestedRefundAmount = request.RequestedRefundAmount,
            RefundStatus = category == "Refund" ? "PendingReview" : "NotRequested" };
        ticket.Messages.Add(new SupportMessage { TicketId = ticket.Id, AuthorId = driverId, AuthorRole = "Driver", Body = ticket.Description });
        db.SupportTickets.Add(ticket);
        db.AgentWorkflowRuns.Add(new AgentWorkflowRun { TicketId = ticket.Id, DriverId = driverId });
        await Save(ct);
        return await GetAsync(driverId, UserRole.Driver, ticket.Id, ct);
    }

    public async Task<SupportTicketDto> AddMessageAsync(Guid userId, UserRole role, Guid id, string body, CancellationToken ct)
    {
        ValidateText(body, 1, 4000, "Message");
        var ticket = await TicketAsync(id, ct); AuthorizeRead(ticket, userId, role);
        if (ticket.Status is "Closed" or "Withdrawn") throw new InvalidOperationException("Closed or withdrawn tickets cannot receive messages.");
        var message = new SupportMessage { TicketId = id, AuthorId = userId, AuthorRole = role.ToString(), Body = body.Trim() };
        ticket.Messages.Add(message); db.SupportMessages.Add(message);
        if (role is UserRole.SupportManager or UserRole.Admin && ticket.Status == "Open") ticket.Status = "InProgress";
        Touch(ticket); await Save(ct); return await GetAsync(userId, role, id, ct);
    }

    public async Task<SupportTicketDto> SetStatusAsync(Guid actorId, UserRole role, Guid id, string status, CancellationToken ct)
    {
        Staff(role); if (!Statuses.Contains(status)) throw new ArgumentException("Invalid ticket status.");
        var ticket = await TicketAsync(id, ct);
        if (ticket.Status == "Withdrawn") throw new InvalidOperationException("A withdrawn ticket cannot be reopened.");
        if (ticket.RefundStatus == "PendingReview" && status is "Resolved" or "Closed")
            throw new InvalidOperationException("Review the refund before resolving this ticket.");
        ticket.Status = status; AddSystem(ticket, actorId, role, $"Status changed to {status}.");
        Touch(ticket); await Save(ct); return await GetAsync(actorId, role, id, ct);
    }

    public async Task<SupportTicketDto> AssignAsync(Guid actorId, UserRole role, Guid id, Guid? assigneeId, CancellationToken ct)
    {
        Staff(role); var ticket = await TicketAsync(id, ct);
        if (assigneeId.HasValue && !await db.Users.AnyAsync(u => u.Id == assigneeId.Value && u.IsActive &&
                (u.Role == UserRole.SupportManager || u.Role == UserRole.Admin), ct))
            throw new NotFoundException("Support assignee", assigneeId.Value);
        ticket.AssignedToUserId = assigneeId;
        AddSystem(ticket, actorId, role, assigneeId.HasValue ? "Ticket assigned to a support manager." : "Ticket returned to the unassigned queue.");
        Touch(ticket); await Save(ct); return await GetAsync(actorId, role, id, ct);
    }

    public async Task<SupportTicketDto> WithdrawAsync(Guid driverId, Guid id, CancellationToken ct)
    {
        var ticket = await TicketAsync(id, ct);
        if (ticket.DriverId != driverId) throw new NotFoundException(nameof(SupportTicket), id);
        if (ticket.Status != "Open" || ticket.AssignedToUserId != null)
            throw new InvalidOperationException("Only an unassigned open ticket can be withdrawn.");
        ticket.Status = "Withdrawn";
        if (ticket.RefundStatus == "PendingReview") ticket.RefundStatus = "Cancelled";
        Touch(ticket); await Save(ct); return await GetAsync(driverId, UserRole.Driver, id, ct);
    }

    public async Task<SupportTicketDto> ReviewRefundAsync(Guid actorId, UserRole role, Guid id, ReviewRefundRequest request, CancellationToken ct)
    {
        await ApplyRefundReviewAsync(actorId, role, id, request, ct);
        var run = await db.AgentWorkflowRuns.SingleOrDefaultAsync(r => r.TicketId == id, ct);
        if (run is not null)
        {
            run.Status = request.Approve ? AgentWorkflowStatus.Completed : AgentWorkflowStatus.Rejected;
            run.Decision = request.Approve ? "Approved" : "Rejected";
            run.ReviewedBy = actorId; run.ReviewedAt = run.CompletedAt = run.UpdatedAt = DateTimeOffset.UtcNow;
            run.LeaseUntil = null; run.Version = Guid.NewGuid();
            SupportWorkflowService.Audit(run, "ManualRefundDecision", "Existing support refund review: " + run.Decision, actorId);
        }
        await Save(ct);
        return await GetAsync(actorId, role, id, ct);
    }

    // Stages existing financial rules in the caller's unit of work. Workflow state
    // and financial changes are committed together, never in separate saves.
    internal async Task ApplyRefundReviewAsync(Guid actorId, UserRole role, Guid id, ReviewRefundRequest request, CancellationToken ct)
    {
        Staff(role); await ActiveUser(actorId, role, ct); var ticket = await TicketAsync(id, ct);
        if (ticket.RefundStatus != "PendingReview" || ticket.RequestedRefundAmount is null)
            throw new InvalidOperationException("This refund is not awaiting review.");
        if (request.Approve)
        {
            var invoice = await db.PaymentInvoices.Include(i => i.Session).SingleOrDefaultAsync(i => i.Id == ticket.InvoiceId, ct)
                ?? throw new NotFoundException("PaymentInvoice", ticket.InvoiceId ?? Guid.Empty);
            if (invoice.DriverId != ticket.DriverId) throw new InvalidOperationException("Invoice ownership does not match this ticket.");
            var findings = WorkflowValidation.Evaluate(ticket, invoice);
            if (findings.Any(f => f.Outcome == "Error")) throw new InvalidOperationException("Invoice or session validation failed. Correct the records before refunding.");
            if (findings.Any(f => f.Code == "METER_DISCREPANCY" && f.Outcome == "Review") && role != UserRole.Admin)
                throw new ForbiddenAccessException();
            var driver = await db.Users.SingleOrDefaultAsync(u => u.Id == ticket.DriverId && u.IsActive, ct)
                ?? throw new NotFoundException("Driver", ticket.DriverId);
            var amount = ticket.RequestedRefundAmount.Value;
            if (invoice.Status != InvoiceStatus.Paid || amount <= 0 || decimal.Round(amount, 2) != amount || amount > invoice.GrossAmount - invoice.DiscountAmount - invoice.RefundedAmount)
                throw new InvalidOperationException("Refund exceeds the remaining paid amount or has invalid precision.");
            // Preserve the original award as the invoice's unique ledger entry. Reversals
            // reference the audited ticket in Reason, allowing partial refund accounting.
            var award = await db.LoyaltyEntries.SingleOrDefaultAsync(e => e.InvoiceId == invoice.Id, ct);
            if (award is not null && award.Points > 0)
            {
                var paid = invoice.GrossAmount - invoice.DiscountAmount;
                var before = (int)decimal.Floor(award.Points * (paid - invoice.RefundedAmount) / paid);
                var after = (int)decimal.Floor(award.Points * (paid - invoice.RefundedAmount - amount) / paid);
                var reverse = before - after;
                var account = await db.LoyaltyAccounts.SingleOrDefaultAsync(a => a.DriverId == driver.Id, ct)
                    ?? throw new InvalidOperationException("Loyalty account is missing. Manual investigation required.");
                account.ReverseEarned(reverse);
                if (reverse > 0) db.LoyaltyEntries.Add(new Domain.Loyalty.LoyaltyEntry {
                    DriverId = driver.Id, Points = -reverse, Reason = $"Refund reversal: ticket {ticket.Id}, invoice {invoice.Id}" });
            }
            invoice.Refund(amount);
            driver.CreditBalance(amount);
        }
        ticket.RefundStatus = request.Approve ? "Approved" : "Rejected";
        ticket.RefundReviewedBy = actorId; ticket.RefundReviewedAt = DateTimeOffset.UtcNow;
        var note = string.IsNullOrWhiteSpace(request.Note) ? "" : $" Note: {request.Note.Trim()}";
        AddSystem(ticket, actorId, role, $"Refund {ticket.RefundStatus.ToLowerInvariant()} for LKR {ticket.RequestedRefundAmount:0.00}.{note}");
        Touch(ticket);
    }

    private async Task<SupportTicket> TicketAsync(Guid id, CancellationToken ct) =>
        await db.SupportTickets.SingleOrDefaultAsync(t => t.Id == id, ct)
        ?? throw new NotFoundException(nameof(SupportTicket), id);
    private static void AuthorizeRead(SupportTicket t, Guid id, UserRole role)
    { if (role == UserRole.Driver ? t.DriverId != id : role is not (UserRole.SupportManager or UserRole.Admin)) throw new ForbiddenAccessException(); }
    private async Task<User> ActiveUser(Guid id, UserRole role, CancellationToken ct) =>
        await db.Users.SingleOrDefaultAsync(u => u.Id == id && u.Role == role && u.IsActive, ct)
        ?? throw new NotFoundException(nameof(User), id);
    private static void Staff(UserRole role) { if (role is not (UserRole.SupportManager or UserRole.Admin)) throw new ForbiddenAccessException(); }
    private static void ValidateText(string? value, int min, int max, string name)
    { if (string.IsNullOrWhiteSpace(value) || value.Trim().Length < min || value.Trim().Length > max) throw new ArgumentException($"{name} must be {min}–{max} characters."); }
    private static string Triage(string category, string subject, string description, decimal? refund) =>
        refund > RefundApprovalThresholdLkr || (subject + " " + description).Contains("unsafe", StringComparison.OrdinalIgnoreCase) ? "Urgent"
        : category is "Refund" or "Payment" or "Charging" ? "High" : category == "Technical" ? "Medium" : "Low";
    private void AddSystem(SupportTicket t, Guid actor, UserRole role, string body)
    {
        var message = new SupportMessage { TicketId = t.Id, AuthorId = actor, AuthorRole = role.ToString(), Body = body, IsSystem = true };
        t.Messages.Add(message); db.SupportMessages.Add(message);
    }
    private static void Touch(SupportTicket t) { t.UpdatedAt = DateTimeOffset.UtcNow; t.Version = Guid.NewGuid(); }
    private async Task<List<SupportTicketDto>> MapAsync(List<SupportTicket> tickets, CancellationToken ct)
    {
        var ticketIds = tickets.Select(t => t.Id).ToList();
        var messages = await db.SupportMessages.AsNoTracking().Where(m => ticketIds.Contains(m.TicketId)).OrderBy(m => m.CreatedAt).ToListAsync(ct);
        var ids = tickets.SelectMany(t => messages.Where(m => m.TicketId == t.Id).Select(m => m.AuthorId).Append(t.DriverId).Append(t.AssignedToUserId ?? Guid.Empty)).Where(i => i != Guid.Empty).Distinct().ToList();
        var users = await db.Users.AsNoTracking().Where(u => ids.Contains(u.Id)).ToDictionaryAsync(u => u.Id, ct);
        return tickets.Select(t => new SupportTicketDto(t.Id, t.DriverId, users.GetValueOrDefault(t.DriverId)?.FullName ?? "Driver",
            users.GetValueOrDefault(t.DriverId)?.Email ?? "", t.AssignedToUserId, t.AssignedToUserId is Guid a ? users.GetValueOrDefault(a)?.FullName : null,
            t.InvoiceId, t.Category, t.Subject, t.Description, t.Priority, t.Status, t.RequestedRefundAmount, t.RefundStatus,
            t.CreatedAt, t.UpdatedAt, messages.Where(m => m.TicketId == t.Id).Select(m => new SupportMessageDto(m.Id, m.AuthorId, m.AuthorRole,
                users.GetValueOrDefault(m.AuthorId)?.FullName ?? m.AuthorRole, m.Body, m.IsSystem, m.CreatedAt)).ToList())).ToList();
    }
    private async Task Save(CancellationToken ct)
    {
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new PaymentConflictException("Ticket or wallet changed concurrently. Refresh and retry."); }
        catch (DbUpdateException ex) when (ex.InnerException?.GetType().GetProperty("SqlState")?.GetValue(ex.InnerException)?.ToString() == "23505")
        { throw new PaymentConflictException("A duplicate ticket or refund was submitted. Refresh and retry."); }
    }
}
