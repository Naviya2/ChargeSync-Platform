using Application.Payments.Models;
using Domain.Entities;

namespace Application.Payments;

public interface IPaymentService
{
    Task<PaymentInvoice> IssueForSessionAsync(
        ChargingSession session,
        Charger charger,
        CancellationToken cancellationToken = default);

    Task<PaymentInvoiceDto> SettleAsync(
        Guid requesterId,
        string requesterRole,
        Guid invoiceId,
        SettleInvoiceRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PaymentInvoiceDto>> GetInvoicesAsync(
        Guid requesterId,
        string requesterRole,
        InvoiceFilter filter,
        CancellationToken cancellationToken = default);

    Task<PaymentInvoiceDto> ToDtoAsync(
        PaymentInvoice invoice,
        CancellationToken cancellationToken = default);
}
