namespace Domain.Wallets;

public sealed class WalletTopUp
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DriverId { get; set; }
    public Guid RequestId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "LKR";
    public string Status { get; set; } = "Pending";
    public bool Sandbox { get; set; }
    public string? PaymentId { get; set; }
    public string Phone { get; set; } = "";
    public string Address { get; set; } = "";
    public string City { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CreditedAt { get; set; }
    public Guid Version { get; set; } = Guid.NewGuid();
}
