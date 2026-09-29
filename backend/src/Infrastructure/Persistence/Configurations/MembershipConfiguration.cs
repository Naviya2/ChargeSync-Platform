using Domain.Memberships;
using Domain.Loyalty;
using Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class MembershipConfiguration : IEntityTypeConfiguration<MembershipPlan>,
    IEntityTypeConfiguration<Subscription>, IEntityTypeConfiguration<LoyaltyAccount>,
    IEntityTypeConfiguration<LoyaltyEntry>, IEntityTypeConfiguration<Reward>, IEntityTypeConfiguration<RewardRedemption>
{
    public void Configure(EntityTypeBuilder<MembershipPlan> b)
    {
        b.ToTable("MembershipPlans", t => t.HasCheckConstraint("CK_MembershipPlans_Amounts", "\"MonthlyFee\" >= 0 AND \"DiscountPercentage\" BETWEEN 0 AND 100")); b.HasKey(x => x.Id);
        b.Property(x => x.Name).HasMaxLength(50);
        b.Property(x => x.MonthlyFee).HasPrecision(10, 2);
        b.Property(x => x.DiscountPercentage).HasPrecision(5, 2);
        b.HasData(
            new MembershipPlan { Id = Guid.Parse("10000000-0000-0000-0000-000000000001"), Name = "Plus", Description = "30 days of 5% charging savings", MonthlyFee = 500m, DiscountPercentage = 5m },
            new MembershipPlan { Id = Guid.Parse("10000000-0000-0000-0000-000000000002"), Name = "Premium", Description = "30 days of 10% charging savings", MonthlyFee = 1000m, DiscountPercentage = 10m });
    }
    public void Configure(EntityTypeBuilder<Subscription> b)
    {
        b.ToTable("Subscriptions", t => {
            t.HasCheckConstraint("CK_Subscriptions_Status", "\"Status\" IN ('Active', 'Cancelled', 'Expired', 'Changed')");
            t.HasCheckConstraint("CK_Subscriptions_Amounts", "\"FeePaid\" >= 0 AND \"CreditApplied\" >= 0 AND \"DiscountPercentage\" BETWEEN 0 AND 100");
            t.HasCheckConstraint("CK_Subscriptions_Dates", "\"EndDate\" > \"StartDate\"");
        }); b.HasKey(x => x.Id);
        b.HasOne<User>().WithMany().HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.Plan).WithMany().HasForeignKey(x => x.PlanId).OnDelete(DeleteBehavior.Restrict);
        b.Property(x => x.FeePaid).HasPrecision(10, 2);
        b.Property(x => x.CreditApplied).HasPrecision(10, 2);
        b.Property(x => x.DiscountPercentage).HasPrecision(5, 2);
        b.Property(x => x.Version).IsConcurrencyToken();
        b.Property(x => x.Status).HasMaxLength(20);
        // The user MembershipVersion serializes subscriptions, including first enrollment.
        b.HasIndex(x => x.DriverId);
    }
    public void Configure(EntityTypeBuilder<LoyaltyAccount> b)
    {
        b.ToTable("LoyaltyAccounts", t => t.HasCheckConstraint("CK_Loyalty_Balances", "\"PointsBalance\" >= 0 AND \"LifetimePoints\" >= 0"));
        b.HasKey(x => x.DriverId);
        b.HasOne<User>().WithOne().HasForeignKey<LoyaltyAccount>(x => x.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.Property(x => x.Version).IsConcurrencyToken();
        b.Ignore(x => x.Tier);
    }
    public void Configure(EntityTypeBuilder<LoyaltyEntry> b)
    {
        b.ToTable("LoyaltyEntries"); b.HasKey(x => x.Id);
        b.HasOne<LoyaltyAccount>().WithMany().HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.Invoice).WithMany().HasForeignKey(x => x.InvoiceId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<RewardRedemption>().WithMany().HasForeignKey(x => x.RedemptionId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(x => x.InvoiceId).IsUnique();
        b.HasIndex(x => new { x.DriverId, x.CreatedAt });
        b.Property(x => x.Reason).HasMaxLength(255);
    }
    public void Configure(EntityTypeBuilder<Reward> b)
    {
        b.ToTable("Rewards", t => t.HasCheckConstraint("CK_Rewards_Values", "\"PointsCost\" > 0 AND \"WalletCredit\" > 0")); b.HasKey(x => x.Id);
        b.Property(x => x.WalletCredit).HasPrecision(10, 2);
        b.HasData(
            new Reward { Id = Guid.Parse("20000000-0000-0000-0000-000000000001"), Name = "LKR 100 wallet credit", PointsCost = 100, WalletCredit = 100m },
            new Reward { Id = Guid.Parse("20000000-0000-0000-0000-000000000002"), Name = "LKR 6,000 wallet credit", PointsCost = 6000, WalletCredit = 6000m, RequiresApproval = true });
    }
    public void Configure(EntityTypeBuilder<RewardRedemption> b)
    {
        b.ToTable("RewardRedemptions", t => {
            t.HasCheckConstraint("CK_Redemptions_Status", "\"Status\" IN ('Pending', 'Approved', 'Rejected')");
            t.HasCheckConstraint("CK_Redemptions_Values", "\"PointsRedeemed\" > 0 AND \"WalletCredit\" > 0");
        }); b.HasKey(x => x.Id);
        b.HasOne<LoyaltyAccount>().WithMany().HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<Reward>().WithMany().HasForeignKey(x => x.RewardId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(x => x.ReviewedBy).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(x => new { x.DriverId, x.RequestId }).IsUnique();
        b.Property(x => x.Status).HasMaxLength(20).IsConcurrencyToken();
        b.Property(x => x.WalletCredit).HasPrecision(10, 2);
    }
}
