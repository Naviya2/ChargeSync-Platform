namespace Domain.Loyalty;

public sealed class Reward
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public int PointsCost { get; set; }
    public decimal WalletCredit { get; set; }
    public bool RequiresApproval { get; set; }
    public bool IsActive { get; set; } = true;
}
