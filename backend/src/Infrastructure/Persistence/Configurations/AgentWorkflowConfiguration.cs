using Domain.Support;
using Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Infrastructure.Persistence.Configurations;

public sealed class AgentWorkflowConfiguration : IEntityTypeConfiguration<AgentWorkflowRun>
{
    public void Configure(EntityTypeBuilder<AgentWorkflowRun> b)
    {
        b.ToTable("AgentWorkflowRuns");
        b.HasKey(x => x.Id);
        b.HasIndex(x => x.TicketId).IsUnique();
        b.HasIndex(x => new { x.Status, x.NextAttemptAt });
        b.HasOne<SupportTicket>().WithOne().HasForeignKey<AgentWorkflowRun>(x => x.TicketId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(x => x.ReviewedBy).OnDelete(DeleteBehavior.Restrict);
        b.Property(x => x.Version).IsConcurrencyToken();
        b.Property(x => x.Status).HasConversion<string>().HasMaxLength(30);
        b.Property(x => x.WorkflowType).HasMaxLength(40);
        b.Property(x => x.Objective).HasMaxLength(500);
        b.Property(x => x.Action).HasMaxLength(40);
        b.Property(x => x.Currency).HasMaxLength(3);
        b.Property(x => x.Amount).HasPrecision(10, 2);
        b.Property(x => x.Error).HasMaxLength(500);
        b.Property(x => x.RevisionNote).HasMaxLength(1000);
        b.Property(x => x.Decision).HasMaxLength(30);
        b.Property(x => x.InputJson).HasColumnType("jsonb");
        b.Property(x => x.ResultJson).HasColumnType("jsonb");
        b.Property(x => x.AuditJson).HasColumnType("jsonb");
    }
}
