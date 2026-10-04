namespace Application.Support;

public sealed record ValidationFinding(string Code, string Outcome, string Message);
public sealed record WorkflowTicket(Guid Id, Guid DriverId, string Subject, string Description, string Category,
    string Priority, string[] Messages, Guid? InvoiceId, decimal? RequestedRefundAmount, string RefundStatus);
public sealed record WorkflowSession(Guid Id, decimal? AutomaticKwh, decimal? MeterKwh, decimal? FinalKwh,
    DateTimeOffset StartTime, DateTimeOffset? EndTime);
public sealed record WorkflowInvoice(Guid Id, Guid SessionId, Guid? DriverId, string Status, decimal Gross,
    decimal Discount, decimal Advance, decimal NetDue, decimal RefundedAmount, decimal Tariff);
public sealed record WorkflowLoyalty(Guid DriverId, int PointsBalance);
public sealed record SupportWorkflowInput(Guid WorkflowId, int Revision, string Objective, WorkflowTicket Ticket,
    WorkflowSession? Session, WorkflowInvoice? Invoice, WorkflowLoyalty? Loyalty,
    ValidationFinding[] ValidationResults, bool ApprovalRequired, string Action, string? RevisionNote);
public sealed record WorkflowStep(string Agent, string Step, string? Tool, DateTimeOffset StartedAt,
    DateTimeOffset CompletedAt, string Outcome);
public sealed record WorkflowPlanStep(string Agent, string Tool);
public sealed record WorkflowToolResult(string Tool, string Outcome);
public sealed record SupportWorkflowOutput(Guid WorkflowId, int Revision, WorkflowPlanStep[] Plan,
    WorkflowStep[] CompletedSteps, WorkflowToolResult[] ToolResults, SupportSuggestion Suggestion);
public interface ISupportWorkflowClient
{
    Task<SupportWorkflowOutput?> RunAsync(SupportWorkflowInput input, CancellationToken ct);
}
public sealed record WorkflowAudit(DateTimeOffset At, int Revision, string Event, string Detail, Guid? ActorId = null);
public sealed record WorkflowDto(Guid Id, Guid TicketId, string Status, int Revision, bool ApprovalRequired,
    string Action, decimal? Amount, string Currency, DateTimeOffset UpdatedAt, string? Error,
    string? Decision, SupportWorkflowOutput? Analysis, ValidationFinding[]? ValidationResults,
    WorkflowAudit[]? Audit);
public sealed record WorkflowDecisionRequest(Guid Version, string? Note);
public sealed record WorkflowReviewDto(WorkflowDto Workflow, Guid Version);

public sealed class SupportWorkflowPolicy
{
    // Optional stricter policy. The default applies the selected LKR 15 threshold.
    // A read-only recommendation never authorizes an LLM financial action.
    public bool RequireAllRefundsApproval { get; set; }
    public decimal RefundApprovalThresholdLkr { get; set; } = 15m;
    public bool RefundRequiresApproval(decimal amount) => RequireAllRefundsApproval || amount > RefundApprovalThresholdLkr;
    public static bool LoyaltyRequiresApproval(int points, bool rewardRequiresApproval = false) => rewardRequiresApproval || points > 5000;
}
