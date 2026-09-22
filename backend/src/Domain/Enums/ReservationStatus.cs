namespace Domain.Enums;

/// <summary>
/// Lifecycle states for a <see cref="Domain.Entities.Reservation"/> record (SRS §4.2 Reservations).
/// </summary>
public enum ReservationStatus
{
    /// <summary>Reservation created; advance deposit deducted; QR token generated. Awaiting confirmation.</summary>
    Pending,

    /// <summary>Slot confirmed and locked; driver may travel to station.</summary>
    Confirmed,

    /// <summary>Station staff scanned the driver's QR code; charging session started.</summary>
    CheckedIn,

    /// <summary>Reservation cancelled by driver; refund policy applied.</summary>
    Cancelled,

    /// <summary>Charging session ended and invoice settled.</summary>
    Completed
}
