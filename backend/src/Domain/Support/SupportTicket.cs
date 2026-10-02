namespace Domain.Support;

public sealed class SupportTicket
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DriverId { get; set; }
    public Guid? AssignedToUserId { get; set; }
    public Guid? InvoiceId { get; set; }
    public string Category { get; set; } = "General";
    public string Subject { get; set; } = "";
    public string Description { get; set; } = "";
    public string Priority { get; set; } = "Medium";
    public string Status { get; set; } = "Open";
    public decimal? RequestedRefundAmount { get; set; }
    public string RefundStatus { get; set; } = "NotRequested";
    public Guid? RefundReviewedBy { get; set; }
    public DateTimeOffset? RefundReviewedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid Version { get; set; } = Guid.NewGuid();
    public List<SupportMessage> Messages { get; set; } = [];
}
