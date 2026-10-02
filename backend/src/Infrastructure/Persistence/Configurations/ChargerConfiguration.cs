using Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public class ChargerConfiguration : IEntityTypeConfiguration<Charger>
{
    public void Configure(EntityTypeBuilder<Charger> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id)
            .HasDefaultValueSql("gen_random_uuid()");

        builder.Property(c => c.Identifier)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(c => c.BayLabel)
            .HasMaxLength(100);

        builder.Property(c => c.Connector)
            .HasConversion<string>()
            .IsRequired();

        builder.Property(c => c.Status)
            .HasConversion<string>()
            .IsRequired();

        builder.Property(c => c.PowerKw)
            .HasPrecision(8, 2);

        builder.Property(c => c.Tariff)
            .HasPrecision(10, 2);

        builder.HasOne(c => c.Station)
            .WithMany(s => s.Chargers)
            .HasForeignKey(c => c.StationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(c => c.UpdatedAt).HasDefaultValueSql("now()");
    }
}
