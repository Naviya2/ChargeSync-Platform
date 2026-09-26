using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;

namespace Application.ReservationPlanning;

/// <summary>
/// Core reservation operations: advance bookings, walk-in admissions,
/// QR-code check-ins, cancellations, and status history retrieval.
/// </summary>
public interface IReservationService
{
    /// <summary>
    /// Creates an advance reservation for a registered driver.
    /// Deducts the advance deposit from the driver's wallet balance.
    /// Generates and stores a signed QR token on the created reservation.
    /// </summary>
    Task<ReservationDto> CreateAsync(
        Guid driverId,
        CreateReservationRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates an immediate walk-in reservation initiated by station staff.
    /// No driver account or advance payment is required.
    /// The reservation is set to CheckedIn status immediately.
    /// </summary>
    Task<ReservationDto> CreateWalkInAsync(
        Guid staffUserId,
        WalkInRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns a paginated list of reservations filtered by the caller's role.
    /// Drivers see only their own reservations.
    /// Staff and Admins can see all reservations, optionally filtered.
    /// </summary>
    Task<PagedResult<ReservationSummaryDto>> GetListAsync(
        Guid requesterId,
        string requesterRole,
        ReservationFilter filter,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns full details for a single reservation including the QR code payload.
    /// Returns null if the reservation does not exist or the caller is not authorised.
    /// </summary>
    Task<ReservationDto?> GetByIdAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Cancels a reservation.
    /// Refunds the advance deposit to the driver's wallet.
    /// Automatically promotes the highest-priority waiting waitlist entry.
    /// </summary>
    Task CancelAsync(
        Guid requesterId,
        Guid id,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Validates a driver's QR token scanned by station staff and marks
    /// the reservation as CheckedIn.
    /// </summary>
    Task<ReservationDto> StaffCheckinAsync(
        Guid staffUserId,
        StaffCheckinRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the full status transition history for a reservation.
    /// </summary>
    Task<IReadOnlyList<ReservationHistoryDto>> GetHistoryAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates the time window of an existing reservation.
    /// </summary>
    Task<ReservationDto> UpdateAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        UpdateReservationRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Hard deletes a reservation from the database.
    /// Primarily for admin use or data cleanup.
    /// </summary>
    Task DeleteAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets available time slots for a specific charger on a specific date, for a given duration.
    /// </summary>
    Task<IReadOnlyList<TimeSlotDto>> GetAvailableTimeSlotsAsync(
        Guid chargerId,
        DateTime date,
        int durationMinutes,
        CancellationToken cancellationToken = default);
}
