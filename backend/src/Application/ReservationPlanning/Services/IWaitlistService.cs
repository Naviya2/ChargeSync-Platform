using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;

namespace Application.ReservationPlanning;

/// <summary>
/// Manages the per-charger waitlist: joining, listing, and automatic promotion
/// when a reservation slot opens up due to cancellation.
/// </summary>
public interface IWaitlistService
{
    /// <summary>
    /// Adds a driver to the waitlist for a specific charger at their preferred time.
    /// </summary>
    Task<WaitlistEntryDto> JoinAsync(
        Guid driverId,
        WaitlistRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns all active waitlist entries for the calling driver.
    /// </summary>
    Task<IReadOnlyList<WaitlistEntryDto>> GetMineAsync(
        Guid driverId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Attempts to promote the highest-priority waiting entry for a charger
    /// into a confirmed reservation after a slot opens.
    /// Called internally by <see cref="IReservationService.CancelAsync"/>.
    /// Returns true if a waitlist entry was promoted, false if the waitlist was empty.
    /// </summary>
    Task<bool> TryPromoteNextAsync(
        Guid chargerId,
        DateTimeOffset slotStart,
        DateTimeOffset slotEnd,
        CancellationToken cancellationToken = default);
}
