using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Entities;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Support;

public sealed record SupportAnalysisInput(string Subject, string Description, string[] Messages, string[] Findings);
public sealed record SupportSuggestion(string Category, string Priority, string Explanation, string DraftReply);
public interface ISupportAgentClient
{
    Task<SupportSuggestion?> AnalyzeAsync(SupportAnalysisInput input, CancellationToken ct);
}
public sealed record SupportAnalysisResult(SupportSuggestion Suggestion, string[] Findings, bool AiAvailable, string ApprovalStatus);

public sealed class SupportAnalysisService(IAppDbContext db, ISupportAgentClient agent)
{
    public async Task<string[]> ValidateInvoiceAsync(Guid id, UserRole role, CancellationToken ct)
    {
        if (role is not (UserRole.Admin or UserRole.SupportManager)) throw new ForbiddenAccessException();
        var invoice = await db.PaymentInvoices.AsNoTracking().Include(i => i.Session).SingleOrDefaultAsync(i => i.Id == id, ct)
            ?? throw new NotFoundException("PaymentInvoice", id);
        return await ValidateRecordsAsync(invoice, ct);
    }

    private async Task<string[]> ValidateRecordsAsync(PaymentInvoice invoice, CancellationToken ct)
    {
        var findings = Validate(invoice).ToList();
        var session = invoice.Session;
        if (session?.EndTime is not null)
        {
            var reservation = await db.Reservations.AsNoTracking().SingleOrDefaultAsync(r => r.Id == session.ReservationId, ct);
            var charger = reservation is null ? null : await db.Chargers.AsNoTracking().SingleOrDefaultAsync(c => c.Id == reservation.ChargerId, ct);
            if (charger is null) findings.Add("Reservation or charger is missing. Automatic energy cannot be recalculated.");
            else
            {
                var expected = decimal.Round(charger.PowerKw * (decimal)(session.EndTime.Value - session.StartTime).TotalHours, 2, MidpointRounding.AwayFromZero);
                findings.Add(expected == session.AutoCalculatedKwh ? "Automatic energy matches power × elapsed hours using current charger power."
                    : "Automatic energy differs from power × elapsed hours using current charger power. Verify the historical power setting before deciding.");
            }
        }
        return findings.ToArray();
    }
    public async Task<SupportAnalysisResult> AnalyzeAsync(Guid id, UserRole role, CancellationToken ct)
    {
        if (role is not (UserRole.Admin or UserRole.SupportManager)) throw new ForbiddenAccessException();
        var ticket = await db.SupportTickets.AsNoTracking().SingleOrDefaultAsync(t => t.Id == id, ct)
            ?? throw new NotFoundException("SupportTicket", id);
        var findings = new List<string>();
        if (ticket.InvoiceId is Guid invoiceId)
        {
            var invoice = await db.PaymentInvoices.AsNoTracking().Include(i => i.Session).SingleOrDefaultAsync(i => i.Id == invoiceId, ct);
            if (invoice is null) findings.Add("Linked invoice is missing. Manual investigation required.");
            else if (invoice.DriverId != ticket.DriverId) findings.Add("Invoice ownership does not match the ticket. Manual investigation required.");
            else findings.AddRange(await ValidateRecordsAsync(invoice, ct));
        }
        else findings.Add("No linked invoice or session. Billing and energy checks cannot be completed.");
        var messages = await db.SupportMessages.AsNoTracking().Where(m => m.TicketId == id && !m.IsSystem)
            .OrderByDescending(m => m.CreatedAt).Take(12).Select(m => m.Body).ToArrayAsync(ct);
        var suggestion = await agent.AnalyzeAsync(new(ticket.Subject, ticket.Description, messages, findings.ToArray()), ct);
        var available = suggestion is not null;
        suggestion ??= new(ticket.Category, ticket.Priority, "AI is unavailable. Review the backend findings manually.",
            "Thank you for contacting ChargeSync. We are reviewing your request and will follow up after checking the relevant records.");
        return new(suggestion, findings.ToArray(), available,
            ticket.RefundStatus == "PendingReview" ? "Pending approval — staff must verify the invoice before approving a wallet refund and loyalty reversal." : "Any refund or reward requires the existing backend review workflow.");
    }

    public static string[] Validate(PaymentInvoice invoice)
    {
        var findings = new List<string>();
        var s = invoice.Session;
        if (invoice.DriverId is null) findings.Add("Walk-in session: no driver account. Wallet refunds and loyalty rewards are unavailable.");
        if (s is null || s.FinalEnergyDeliveredKwh is null || s.AutoCalculatedKwh is null || s.EndTime is null)
        { findings.Add("Session data is incomplete. Energy and billing cannot be verified."); return findings.ToArray(); }
        if (s.EndTime <= s.StartTime || s.AutoCalculatedKwh < 0 || s.FinalEnergyDeliveredKwh < 0)
            findings.Add("Session duration or energy is invalid.");
        if (s.FinalEnergyDeliveredKwh != (s.StaffOverriddenKwh ?? s.AutoCalculatedKwh))
            findings.Add("Final energy does not match the automatic or overridden reading.");
        if (s.StaffOverriddenKwh is decimal meter &&
            (s.AutoCalculatedKwh == 0 ? meter != 0 : Math.Abs(meter - s.AutoCalculatedKwh.Value) / s.AutoCalculatedKwh.Value > .15m))
            findings.Add("Meter difference exceeds 15% of automatic energy. Staff investigation required.");
        var gross = decimal.Round(s.FinalEnergyDeliveredKwh.Value * invoice.TariffPerKwh, 2, MidpointRounding.AwayFromZero);
        var discount = decimal.Round(gross * invoice.DiscountPercentage / 100m, 2, MidpointRounding.AwayFromZero);
        if (invoice.TariffPerKwh < 0 || invoice.DiscountPercentage is < 0 or > 100 || invoice.GrossAmount != gross || invoice.DiscountAmount != discount ||
            invoice.AdvanceDeducted < 0 || invoice.AdvanceDeducted > gross - discount || invoice.NetAmountDue != gross - discount - invoice.AdvanceDeducted)
            findings.Add("Invoice totals do not match energy, tariff, discount and advance. Manual billing review required.");
        else findings.Add("Invoice arithmetic matches the recorded final energy and tariff.");
        findings.Add("Automatic energy uses recorded estimates; meter photos are not independently verified by this analysis.");
        return findings.ToArray();
    }
}

