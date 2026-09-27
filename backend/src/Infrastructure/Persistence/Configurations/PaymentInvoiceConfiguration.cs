using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class PaymentInvoiceConfiguration : IEntityTypeConfiguration<PaymentInvoice>
{
    public void Configure(EntityTypeBuilder<PaymentInvoice> builder)
    {
        builder.ToTable("PaymentInvoices", table =>
        {
            table.HasCheckConstraint(
                "CK_PaymentInvoices_Status",
                "\"Status\" IN ('Pending', 'Paid', 'Refunded')");
            table.HasCheckConstraint(
                "CK_PaymentInvoices_PaymentMethod",
                "\"PaymentMethod\" IS NULL OR \"PaymentMethod\" IN ('Wallet', 'Cash')");
            table.HasCheckConstraint(
                "CK_PaymentInvoices_Amounts",
                "\"GrossAmount\" >= 0 AND \"AdvanceDeducted\" >= 0 AND \"NetAmountDue\" >= 0");
        });

        builder.HasKey(i => i.Id);
        builder.Property(i => i.Id).HasDefaultValueSql("gen_random_uuid()").ValueGeneratedOnAdd();
        builder.Property(i => i.TariffPerKwh).HasPrecision(10, 2).IsRequired();
        builder.Property(i => i.GrossAmount).HasPrecision(10, 2).IsRequired();
        builder.Property(i => i.AdvanceDeducted).HasPrecision(10, 2).IsRequired();
        builder.Property(i => i.NetAmountDue).HasPrecision(10, 2).IsRequired();
        builder.Property(i => i.PaymentMethod).HasConversion<string>().HasMaxLength(20);
        builder.Property(i => i.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasDefaultValue(InvoiceStatus.Pending)
            .IsConcurrencyToken()
            .IsRequired();
        builder.Property(i => i.IssuedAt).IsRequired();

        builder.HasOne(i => i.Session)
            .WithOne(s => s.Invoice)
            .HasForeignKey<PaymentInvoice>(i => i.SessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.Driver)
            .WithMany()
            .HasForeignKey(i => i.DriverId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);

        builder.HasIndex(i => i.SessionId).IsUnique();
        builder.HasIndex(i => i.DriverId);
        builder.HasIndex(i => i.Status);
        builder.Property(i => i.CreatedAt).HasDefaultValueSql("now()").ValueGeneratedOnAdd();
        builder.Property(i => i.UpdatedAt).HasDefaultValueSql("now()").ValueGeneratedOnAdd();
    }
}
