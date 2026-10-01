namespace Domain.Loyalty;

public sealed class LoyaltyAccount
{
    public Guid DriverId { get; set; }
    public int PointsBalance { get; private set; }
    public int LifetimePoints { get; private set; }
    public Guid Version { get; private set; } = Guid.NewGuid();
    public string Tier => LifetimePoints >= 5000 ? "Gold" : LifetimePoints >= 1000 ? "Silver" : "Bronze";

    public void Earn(int points)
    {
        if (points < 0) throw new ArgumentException("Points cannot be negative.");
        PointsBalance = checked(PointsBalance + points);
        LifetimePoints = checked(LifetimePoints + points);
        Version = Guid.NewGuid();
    }

    public void Spend(int points)
    {
        if (points <= 0) throw new ArgumentException("Reward cost must be positive.");
        if (PointsBalance < points) throw new InvalidOperationException("Insufficient loyalty points.");
        PointsBalance -= points;
        Version = Guid.NewGuid();
    }

    public void ReverseEarned(int points)
    {
        if (points < 0 || PointsBalance < points || LifetimePoints < points)
            throw new InvalidOperationException("Earned points have already been spent or reserved. Resolve loyalty accounting before approving this refund.");
        PointsBalance -= points;
        LifetimePoints -= points;
        Version = Guid.NewGuid();
    }

    public void Release(int points)
    {
        if (points <= 0) throw new ArgumentException("Released points must be positive.");
        PointsBalance = checked(PointsBalance + points);
        Version = Guid.NewGuid();
    }
}
