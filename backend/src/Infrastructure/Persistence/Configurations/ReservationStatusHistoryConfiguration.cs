using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

/// <summary>
/// Maps <see cref="ReservationStatusHistory"/> to the <c>ReservationStatusHistory</c> table.
/// Rows are append-only — never updated or deleted after insertion.
/// </summary>
public class ReservationStatusHistoryConfiguration : IEntityTypeConfiguration<ReservationStatusHistory>
{
    public void Configure(EntityTypeBuilder<ReservationStatusHistory> builder)
    {
        builder.ToTable("ReservationStatusHistory");

        builder.HasKey(h => h.Id);

        builder.Property(h => h.Id)
            .HasDefaultValueSql("gen_random_uuid()")
            .ValueGeneratedOnAdd();

        builder.Property(h => h.ReservationId)
            .IsRequired();

        // OldStatus is null for the very first history entry (initial creation).
        builder.Property(h => h.OldStatus)
            .HasMaxLength(20)
            .HasConversion<string>()
            .IsRequired(false);

        builder.Property(h => h.NewStatus)
            .IsRequired()
            .HasMaxLength(20)
            .HasConversion<string>();

        // Null when the transition was triggered by an automated system process.
        builder.Property(h => h.ChangedByUserId)
            .IsRequired(false);

        builder.Property(h => h.ChangedAt)
            .IsRequired();

        // Navigation: back to the parent reservation
        builder.HasOne(h => h.Reservation)
            .WithMany(r => r.StatusHistory)
            .HasForeignKey(h => h.ReservationId)
            .OnDelete(DeleteBehavior.Cascade);

        // Navigation: optional actor who performed the transition
        builder.HasOne(h => h.ChangedBy)
            .WithMany()
            .HasForeignKey(h => h.ChangedByUserId)
            .OnDelete(DeleteBehavior.SetNull)
            .IsRequired(false);

        builder.HasIndex(h => h.ReservationId);

        // History rows are written once on creation — no UpdatedAt bump needed.
        builder.Property(h => h.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();

        builder.Property(h => h.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();
    }
}
