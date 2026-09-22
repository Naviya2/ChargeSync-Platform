using Domain.Enums;

namespace Application.ReservationPlanning.Models;

/// <summary>
/// Payload a registered driver submits to book an advance reservation.
/// The advance deposit is deducted from the driver's wallet balance by the service.
/// </summary>
public sealed class CreateReservationRequest
{
    public Guid ChargerId { get; set; }

    /// <summary>Optional vehicle profile. Recommended but not mandatory.</summary>
    public Guid? VehicleId { get; set; }

    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset EndTime { get; set; }

    /// <summary>Advance deposit amount the driver agrees to pay from their wallet.</summary>
    public decimal AdvanceDepositAmount { get; set; }
}

/// <summary>
/// Payload station staff submits to admit an unregistered walk-in customer.
/// No driver account or advance payment is required.
/// </summary>
public sealed class WalkInRequest
{
    public Guid ChargerId { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset EndTime { get; set; }
}

/// <summary>
/// Payload for the staff QR-code scan check-in endpoint.
/// The staff member scans the driver's QR code; the system validates and checks in.
/// </summary>
public sealed class StaffCheckinRequest
{
    /// <summary>The QR token value read from the driver's mobile screen.</summary>
    public string QrCode { get; set; } = null!;
}

/// <summary>Query filters for the list reservations endpoint.</summary>
public sealed class ReservationFilter
{
    /// <summary>Filter by a specific charger. Null means all chargers.</summary>
    public Guid? ChargerId { get; set; }

    /// <summary>Filter by status. Null means all statuses.</summary>
    public ReservationStatus? Status { get; set; }

    /// <summary>Return only reservations starting on or after this time.</summary>
    public DateTimeOffset? From { get; set; }

    /// <summary>Return only reservations starting before this time.</summary>
    public DateTimeOffset? To { get; set; }

    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

/// <summary>Payload a driver submits to join a charger waitlist.</summary>
public sealed class WaitlistRequest
{
    public Guid ChargerId { get; set; }
    public DateTimeOffset RequestedStartTime { get; set; }
}
