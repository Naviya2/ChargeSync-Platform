using Domain.Users;
using Domain.Wallets;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class WalletTopUpConfiguration : IEntityTypeConfiguration<WalletTopUp>
{
    public void Configure(EntityTypeBuilder<WalletTopUp> b)
    {
        b.ToTable("WalletTopUps", t =>
        {
            t.HasCheckConstraint("CK_WalletTopUps_Amount", "\"Amount\" >= 100 AND \"Amount\" <= 50000");
            t.HasCheckConstraint("CK_WalletTopUps_Currency", "\"Currency\" = 'LKR'");
        });
        b.HasKey(t => t.Id);
        b.Property(t => t.Amount).HasPrecision(10, 2);
        b.Property(t => t.Currency).HasMaxLength(3);
        b.Property(t => t.Status).HasMaxLength(30);
        b.Property(t => t.PaymentId).HasMaxLength(100);
        b.Property(t => t.Phone).HasMaxLength(25);
        b.Property(t => t.Address).HasMaxLength(200);
        b.Property(t => t.City).HasMaxLength(100);
        b.Property(t => t.Version).IsConcurrencyToken();
        b.HasIndex(t => new { t.DriverId, t.RequestId }).IsUnique();
        b.HasIndex(t => t.PaymentId).IsUnique();
        b.HasOne<User>().WithMany().HasForeignKey(t => t.DriverId).OnDelete(DeleteBehavior.Restrict);
    }
}
