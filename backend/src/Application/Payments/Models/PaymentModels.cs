using Domain.Enums;

namespace Application.Payments.Models;

public sealed class SettleInvoiceRequest
{
    public PaymentMethod PaymentMethod { get; set; }
}

public sealed class InvoiceFilter
{
    public Guid? UserId { get; set; }
    public InvoiceStatus? Status { get; set; }
}

public sealed class PaymentInvoiceDto
{
    public Guid Id { get; set; }
    public Guid SessionId { get; set; }
    public Guid? DriverId { get; set; }
    public Guid ChargerId { get; set; }
    public string StationName { get; set; } = string.Empty;
    public string ChargerIdentifier { get; set; } = string.Empty;
    public string BayLabel { get; set; } = string.Empty;
    public decimal EnergyDeliveredKwh { get; set; }
    public decimal TariffPerKwh { get; set; }
    public decimal GrossAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DiscountPercentage { get; set; }
    public decimal AdvanceDeducted { get; set; }
    public decimal NetAmountDue { get; set; }
    public decimal RefundedAmount { get; set; }
    public PaymentMethod? PaymentMethod { get; set; }
    public InvoiceStatus Status { get; set; }
    public DateTimeOffset IssuedAt { get; set; }
    public DateTimeOffset? SettledAt { get; set; }
    public bool IsWalkIn => DriverId is null;
}
