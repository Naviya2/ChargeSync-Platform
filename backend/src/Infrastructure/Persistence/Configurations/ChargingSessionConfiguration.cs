using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class ChargingSessionConfiguration : IEntityTypeConfiguration<ChargingSession>
{
    public void Configure(EntityTypeBuilder<ChargingSession> builder)
    {
        builder.ToTable("ChargingSessions", table => table.HasCheckConstraint(
            "CK_ChargingSessions_Status",
            "\"Status\" IN ('InProgress', 'Completed', 'DiscrepancyFlagged')"));

        builder.HasKey(s => s.Id);
        builder.Property(s => s.Id).HasDefaultValueSql("gen_random_uuid()").ValueGeneratedOnAdd();
        builder.Property(s => s.StartTime).IsRequired();
        builder.Property(s => s.AutoCalculatedKwh).HasPrecision(8, 2);
        builder.Property(s => s.StaffOverriddenKwh).HasPrecision(8, 2);
        builder.Property(s => s.FinalEnergyDeliveredKwh).HasPrecision(8, 2);
        builder.Property(s => s.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasDefaultValue(ChargingSessionStatus.InProgress)
            .IsRequired();

        builder.HasOne(s => s.Reservation)
            .WithOne(r => r.ChargingSession)
            .HasForeignKey<ChargingSession>(s => s.ReservationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.StaffUser)
            .WithMany()
            .HasForeignKey(s => s.StaffUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(s => s.ReservationId).IsUnique();
        builder.HasIndex(s => s.Status);
        builder.Property(s => s.CreatedAt).HasDefaultValueSql("now()").ValueGeneratedOnAdd();
        builder.Property(s => s.UpdatedAt).HasDefaultValueSql("now()").ValueGeneratedOnAdd();
    }
}
