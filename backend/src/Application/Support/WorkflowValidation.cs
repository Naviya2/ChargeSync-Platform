using Domain.Entities;
using Domain.Enums;
using Domain.Support;

namespace Application.Support;

public static class WorkflowValidation
{
    public static bool MeterFlagged(decimal automatic, decimal? meter) => meter.HasValue &&
        (automatic <= 0 ? meter.Value != automatic : Math.Abs(meter.Value - automatic) / automatic > .15m);

    public static ValidationFinding[] Evaluate(SupportTicket ticket, PaymentInvoice? invoice)
    {
        var result = new List<ValidationFinding>();
        if (ticket.InvoiceId is null)
            return ticket.RefundStatus == "PendingReview"
                ? [new("INVOICE_MISSING", "Error", "Refund requires a linked invoice.")]
                : [new("NO_LINKED_INVOICE", "Info", "No linked invoice; billing checks were not performed.")];
        if (invoice is null) return [new("INVOICE_MISSING", "Error", "The linked invoice could not be found.")];
        if (invoice.DriverId != ticket.DriverId)
            return [new("INVOICE_OWNERSHIP", "Error", "The invoice does not belong to the ticket owner.")];
        var s = invoice.Session;
        if (s is null || s.EndTime is null || s.AutoCalculatedKwh is null || s.FinalEnergyDeliveredKwh is null)
            return [new("SESSION_INCOMPLETE", "Error", "The linked session is missing or incomplete.")];
        if (s.EndTime <= s.StartTime || s.AutoCalculatedKwh < 0 || s.FinalEnergyDeliveredKwh < 0 ||
            s.FinalEnergyDeliveredKwh != (s.StaffOverriddenKwh ?? s.AutoCalculatedKwh))
            result.Add(new("ENERGY_INVALID", "Error", "Session duration or final energy is inconsistent."));
        result.Add(MeterFlagged(s.AutoCalculatedKwh.Value, s.StaffOverriddenKwh)
            ? new("METER_DISCREPANCY", "Review", "Meter difference exceeds 15% or the automatic baseline is zero; administrator review required.")
            : new("METER_DISCREPANCY", "Pass", "No recorded meter difference above 15%."));
        var gross = decimal.Round(s.FinalEnergyDeliveredKwh.Value * invoice.TariffPerKwh, 2, MidpointRounding.AwayFromZero);
        var discount = decimal.Round(gross * invoice.DiscountPercentage / 100m, 2, MidpointRounding.AwayFromZero);
        result.Add(invoice.TariffPerKwh < 0 || invoice.DiscountPercentage is < 0 or > 100 || invoice.GrossAmount != gross ||
            invoice.DiscountAmount != discount || invoice.AdvanceDeducted < 0 || invoice.AdvanceDeducted > gross - discount ||
            invoice.NetAmountDue != gross - discount - invoice.AdvanceDeducted
            ? new("INVOICE_TOTALS", "Error", "Invoice arithmetic does not match recorded energy, tariff, discount and deposit.")
            : new("INVOICE_TOTALS", "Pass", "Invoice arithmetic is consistent."));
        if (ticket.RefundStatus == "PendingReview" && (ticket.RequestedRefundAmount is not decimal amount ||
            amount <= 0 || decimal.Round(amount, 2) != amount || invoice.Status != InvoiceStatus.Paid ||
            amount > invoice.GrossAmount - invoice.DiscountAmount - invoice.RefundedAmount))
            result.Add(new("REFUND_INVALID", "Error", "Refund is not eligible for the remaining paid amount."));
        return result.ToArray();
    }
}
