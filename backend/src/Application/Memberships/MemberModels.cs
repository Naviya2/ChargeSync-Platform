namespace Application.Memberships;

public sealed record SelectPlanRequest(Guid PlanId);
public sealed record RedeemRequest(Guid RewardId, Guid RequestId);
public sealed record ReviewRedemptionRequest(bool Approve);
public sealed record SubscriptionDto(Guid Id, Guid PlanId, string PlanName, string Status,
    DateTimeOffset StartDate, DateTimeOffset EndDate, decimal FeePaid, decimal CreditApplied, decimal DiscountPercentage);
public sealed record LoyaltyDto(int PointsBalance, int LifetimePoints, string Tier, int? NextTierPoints, decimal WalletBalance);
