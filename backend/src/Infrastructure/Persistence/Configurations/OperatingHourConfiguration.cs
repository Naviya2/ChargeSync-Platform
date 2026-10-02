using Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public class OperatingHourConfiguration : IEntityTypeConfiguration<OperatingHour>
{
    public void Configure(EntityTypeBuilder<OperatingHour> builder)
    {
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Id)
            .HasDefaultValueSql("gen_random_uuid()");

        builder.HasOne(o => o.Station)
            .WithMany(s => s.OperatingHours)
            .HasForeignKey(o => o.StationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(o => new { o.StationId, o.DayOfWeek }).IsUnique();

        builder.Property(o => o.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(o => o.UpdatedAt).HasDefaultValueSql("now()");
    }
}
