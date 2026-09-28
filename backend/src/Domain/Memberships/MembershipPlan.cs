namespace Domain.Memberships;

public sealed class MembershipPlan
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public decimal MonthlyFee { get; set; }
    public decimal DiscountPercentage { get; set; }
    public bool IsActive { get; set; } = true;
}
