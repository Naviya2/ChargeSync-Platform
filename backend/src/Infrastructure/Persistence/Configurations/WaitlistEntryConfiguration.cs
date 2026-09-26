using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

/// <summary>
/// Maps <see cref="WaitlistEntry"/> to the <c>WaitlistEntries</c> table.
/// </summary>
public class WaitlistEntryConfiguration : IEntityTypeConfiguration<WaitlistEntry>
{
    public void Configure(EntityTypeBuilder<WaitlistEntry> builder)
    {
        builder.ToTable("WaitlistEntries", table =>
        {
            table.HasCheckConstraint(
                "CK_WaitlistEntries_Status",
                "\"Status\" IN ('Waiting', 'Promoted', 'Expired')");
        });

        builder.HasKey(w => w.Id);

        builder.Property(w => w.Id)
            .HasDefaultValueSql("gen_random_uuid()")
            .ValueGeneratedOnAdd();

        builder.Property(w => w.ChargerId)
            .IsRequired();

        builder.Property(w => w.DriverId)
            .IsRequired();

        builder.Property(w => w.RequestedStartTime)
            .IsRequired();

        builder.Property(w => w.Priority)
            .IsRequired()
            .HasDefaultValue(0);

        builder.Property(w => w.Status)
            .IsRequired()
            .HasMaxLength(20)
            .HasConversion<string>()
            .HasDefaultValue(WaitlistStatus.Waiting);

        // Navigation: driver who joined the waitlist
        builder.HasOne(w => w.Driver)
            .WithMany()
            .HasForeignKey(w => w.DriverId)
            .OnDelete(DeleteBehavior.Cascade);

        // Index to efficiently find the next entry to promote when a slot opens.
        // Ordered by Priority ascending, then CreatedAt ascending (FIFO within same priority).
        builder.HasIndex(w => new { w.ChargerId, w.Status, w.Priority });

        builder.Property(w => w.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();

        builder.Property(w => w.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("now()")
            .ValueGeneratedOnAdd();
    }
}
