namespace Domain.Memberships;

public sealed class Subscription
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DriverId { get; set; }
    public Guid PlanId { get; set; }
    public MembershipPlan Plan { get; set; } = null!;
    public DateTimeOffset StartDate { get; set; }
    public DateTimeOffset EndDate { get; set; }
    public string Status { get; set; } = "Active";
    public decimal FeePaid { get; set; }
    public decimal CreditApplied { get; set; }
    public decimal DiscountPercentage { get; set; }
    public Guid Version { get; set; } = Guid.NewGuid();
    public bool HasBenefits(DateTimeOffset now) => Status is "Active" or "Cancelled" && EndDate > now;
}
