namespace Application.Support;

public sealed record CreateTicketRequest(string Category, string Subject, string Description,
    Guid? InvoiceId = null, decimal? RequestedRefundAmount = null);
public sealed record AddMessageRequest(string Body);
public sealed record UpdateTicketStatusRequest(string Status);
public sealed record AssignTicketRequest(Guid? AssigneeId);
public sealed record ReviewRefundRequest(bool Approve, string? Note);
public sealed record SupportMessageDto(Guid Id, Guid AuthorId, string AuthorRole, string AuthorName,
    string Body, bool IsSystem, DateTimeOffset CreatedAt);
public sealed record SupportTicketDto(Guid Id, Guid DriverId, string DriverName, string DriverEmail,
    Guid? AssignedToUserId, string? AssigneeName, Guid? InvoiceId, string Category, string Subject,
    string Description, string Priority, string Status, decimal? RequestedRefundAmount,
    string RefundStatus, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt,
    IReadOnlyList<SupportMessageDto> Messages);
