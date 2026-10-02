using Domain.Entities;
using Domain.Support;
using Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class SupportTicketConfiguration : IEntityTypeConfiguration<SupportTicket>
{
    public void Configure(EntityTypeBuilder<SupportTicket> b)
    {
        b.ToTable("SupportTickets", t =>
        {
            t.HasCheckConstraint("CK_SupportTickets_Category", "\"Category\" IN ('Charging','Reservation','Payment','Refund','Technical','Membership','Other')");
            t.HasCheckConstraint("CK_SupportTickets_Priority", "\"Priority\" IN ('Low','Medium','High','Urgent')");
            t.HasCheckConstraint("CK_SupportTickets_Status", "\"Status\" IN ('Open','InProgress','Resolved','Closed','Withdrawn')");
            t.HasCheckConstraint("CK_SupportTickets_RefundStatus", "\"RefundStatus\" IN ('NotRequested','PendingReview','Approved','Rejected','Cancelled')");
            t.HasCheckConstraint("CK_SupportTickets_RefundAmount", "\"RequestedRefundAmount\" IS NULL OR \"RequestedRefundAmount\" > 0");
        });
        b.HasKey(t => t.Id);
        b.Property(t => t.Category).HasMaxLength(50);
        b.Property(t => t.Subject).HasMaxLength(150);
        b.Property(t => t.Description).HasMaxLength(4000);
        b.Property(t => t.Priority).HasMaxLength(20);
        b.Property(t => t.Status).HasMaxLength(20);
        b.Property(t => t.RefundStatus).HasMaxLength(30);
        b.Property(t => t.RequestedRefundAmount).HasPrecision(10, 2);
        b.Property(t => t.Version).IsConcurrencyToken();
        b.HasIndex(t => new { t.Status, t.Priority, t.UpdatedAt });
        b.HasIndex(t => t.InvoiceId).IsUnique()
            .HasFilter("\"InvoiceId\" IS NOT NULL AND \"RefundStatus\" IN ('PendingReview','Approved')");
        b.HasOne<User>().WithMany().HasForeignKey(t => t.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(t => t.AssignedToUserId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(t => t.RefundReviewedBy).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<PaymentInvoice>().WithMany().HasForeignKey(t => t.InvoiceId).OnDelete(DeleteBehavior.Restrict);
        b.HasMany(t => t.Messages).WithOne(m => m.Ticket).HasForeignKey(m => m.TicketId).OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class SupportMessageConfiguration : IEntityTypeConfiguration<SupportMessage>
{
    public void Configure(EntityTypeBuilder<SupportMessage> b)
    {
        b.ToTable("SupportMessages"); b.HasKey(m => m.Id);
        b.Property(m => m.AuthorRole).HasMaxLength(30);
        b.Property(m => m.Body).HasMaxLength(4000);
        b.HasIndex(m => new { m.TicketId, m.CreatedAt });
        b.HasOne<User>().WithMany().HasForeignKey(m => m.AuthorId).OnDelete(DeleteBehavior.Restrict);
    }
}
