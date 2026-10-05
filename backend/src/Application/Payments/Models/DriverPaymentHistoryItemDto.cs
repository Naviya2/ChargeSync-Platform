namespace Application.Payments.Models;

public sealed record DriverPaymentHistoryItemDto(
    Guid ReferenceId,
    string Type,
    string Description,
    decimal Amount,
    string Direction,
    DateTimeOffset OccurredAt,
    string Method,
    PaymentInvoiceDto? Invoice = null);
