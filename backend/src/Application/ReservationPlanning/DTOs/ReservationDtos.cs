using Domain.Enums;

namespace Application.ReservationPlanning.DTOs;

/// <summary>Full reservation detail returned after create, check-in, or single fetch.</summary>
public sealed class ReservationDto
{
    public Guid Id { get; set; }
    public Guid? DriverId { get; set; }
    public Guid ChargerId { get; set; }
    public Guid? VehicleId { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset EndTime { get; set; }

    /// <summary>
    /// The signed QR token the driver presents on arrival.
    /// Null for walk-in reservations.
    /// </summary>
    public string? ReservationQRCode { get; set; }

    public decimal AdvanceDepositAmount { get; set; }
    public ReservationStatus Status { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>Lightweight item used in paginated list responses.</summary>
public sealed class ReservationSummaryDto
{
    public Guid Id { get; set; }
    public Guid? DriverId { get; set; }
    public Guid ChargerId { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset EndTime { get; set; }
    public ReservationStatus Status { get; set; }
    public bool IsWalkIn { get; set; }
}

/// <summary>A single entry in the reservation status audit trail.</summary>
public sealed class ReservationHistoryDto
{
    public Guid Id { get; set; }
    public ReservationStatus? OldStatus { get; set; }
    public ReservationStatus NewStatus { get; set; }
    public Guid? ChangedByUserId { get; set; }
    public DateTimeOffset ChangedAt { get; set; }
}

/// <summary>Waitlist entry details returned after joining or listing.</summary>
public sealed class WaitlistEntryDto
{
    public Guid Id { get; set; }
    public Guid ChargerId { get; set; }
    public Guid DriverId { get; set; }
    public DateTimeOffset RequestedStartTime { get; set; }
    public int Priority { get; set; }
    public WaitlistStatus Status { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>Generic paginated result wrapper used for list endpoints.</summary>
public sealed class PagedResult<T>
{
    public IReadOnlyList<T> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
}
