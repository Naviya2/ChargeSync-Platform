namespace Domain.Loyalty;

public sealed class RewardRedemption
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DriverId { get; set; }
    public Guid RewardId { get; set; }
    public Guid RequestId { get; set; }
    public string RewardDescription { get; set; } = "";
    public int PointsRedeemed { get; set; }
    public decimal WalletCredit { get; set; }
    public string Status { get; set; } = "Pending";
    public Guid? ReviewedBy { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ReviewedAt { get; set; }
}
