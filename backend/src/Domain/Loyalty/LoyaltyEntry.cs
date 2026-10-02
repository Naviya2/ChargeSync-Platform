using Domain.Entities;

namespace Domain.Loyalty;

public sealed class LoyaltyEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DriverId { get; set; }
    public Guid? InvoiceId { get; set; }
    public PaymentInvoice? Invoice { get; set; }
    public Guid? RedemptionId { get; set; }
    public int Points { get; set; }
    public string Reason { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
