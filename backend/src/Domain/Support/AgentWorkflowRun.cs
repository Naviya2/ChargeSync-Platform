namespace Domain.Support;

public enum AgentWorkflowStatus { Running, PendingApproval, Approved, Rejected, RevisionRequested, Completed, Failed }

/// <summary>Durable work item and audit record. No model reasoning or credentials are stored.</summary>
public sealed class AgentWorkflowRun
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TicketId { get; set; }
    public Guid DriverId { get; set; }
    public string WorkflowType { get; set; } = "SupportTicket";
    public string Objective { get; set; } = "Validate the support request and recommend a safe staff response.";
    public AgentWorkflowStatus Status { get; set; } = AgentWorkflowStatus.Running;
    public Guid Version { get; set; } = Guid.NewGuid();
    public Guid? TicketVersion { get; set; }
    public int Revision { get; set; } = 1;
    public int Attempts { get; set; }
    public DateTimeOffset NextAttemptAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LeaseUntil { get; set; }
    public string? InputJson { get; set; }
    public string? ResultJson { get; set; }
    public string AuditJson { get; set; } = "[]";
    public string? Error { get; set; }
    public string? RevisionNote { get; set; }
    public bool ApprovalRequired { get; set; }
    public string Action { get; set; } = "None";
    public decimal? Amount { get; set; }
    public string Currency { get; set; } = "LKR";
    public Guid? ReviewedBy { get; set; }
    public string? Decision { get; set; }
    public DateTimeOffset? ReviewedAt { get; set; }
    public DateTimeOffset StartedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CompletedAt { get; set; }
}
