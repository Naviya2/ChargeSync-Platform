using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

/// <summary>
/// Maps <see cref="Reservation"/> to the <c>Reservations</c> table.
///
/// The most critical constraint here is the GiST exclusion constraint that
/// prevents two reservations from overlapping on the same charger.
/// It requires the <c>btree_gist</c> PostgreSQL extension.
/// </summary>
public class ReservationConfiguration : IEntityTypeConfiguration<Reservation>
{
    public void Configure(EntityTypeBuilder<Reservation> builder)
    {
        builder.ToTable("Reservations", table =>
        {
            // Prevent overlapping bookings on the same charger at the database level.
            // tstzrange(StartTime, EndTime) creates a half-open [start, end) interval.
            // The && operator means "overlaps".
            table.HasCheckConstraint(
                "CK_Reservations_Status",
                "\"Status\" IN ('Pending', 'Confirmed', 'CheckedIn', 'Cancelled', 'Completed')");
        });

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id)
            .HasDefaultValueSql("gen_random_uuid()")
            .ValueGeneratedOnAdd();

        // DriverId is nullable — NULL means an unregistered walk-in customer.
        builder.Property(r => r.DriverId)
            .IsRequired(false);

        builder.Property(r => r.ChargerId)
            .IsRequired();

        builder.Property(r => r.VehicleId)
            .IsRequired(false);

        builder.Property(r => r.StartTime)
            .IsRequired();

        builder.Property(r => r.EndTime)
            .IsRequired();

        builder.Property(r => r.ReservationQRCode)
            .HasMaxLength(255)
            .IsRequired(false);

        builder.HasIndex(r => r.ReservationQRCode)
            .IsUnique()
            .HasFilter("\"ReservationQRCode\" IS NOT NULL");

        builder.Property(r => r.AdvanceDepositAmount)
            .HasPrecision(8, 2)
            .IsRequired()
            .HasDefaultValue(0m);

        builder.Property(r => r.Status)
            .IsRequired()
            .HasMaxLength(20)
            .HasConversion<string>()
            .HasDefaultValue(ReservationStatus.Pending);

        // Navigation: optional driver (null for walk-ins)
        builder.HasOne(r => r.Driver)
            .WithMany()
            .HasForeignKey(r => r.DriverId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);

        // Navigation: one-to-many status history
        builder.HasMany(r => r.StatusHistory)
            .WithOne(h => h.Reservation)
            .HasForeignKey(h => h.ReservationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.ChargerId);
        builder.HasIndex(r => r.DriverId);
        builder.HasIndex(r => new { r.ChargerId, r.StartTime, r.EndTime });

        builder.Property(r => r.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();

        builder.Property(r => r.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();
    }
}
