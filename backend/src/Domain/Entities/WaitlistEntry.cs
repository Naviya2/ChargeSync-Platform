using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

/// <summary>
/// Queues a driver against a specific charger when their preferred slot is
/// unavailable.
///
/// When a reservation is cancelled the application service automatically promotes
/// the highest-priority <c>Waiting</c> entry for the same charger into a new
/// confirmed reservation.
/// </summary>
public class WaitlistEntry : AuditableEntity
{
    private WaitlistEntry() { }

    private WaitlistEntry(
        Guid chargerId,
        Guid driverId,
        DateTimeOffset requestedStartTime,
        int priority)
    {
        ChargerId = chargerId;
        DriverId = driverId;
        RequestedStartTime = requestedStartTime;
        Priority = priority;
        Status = WaitlistStatus.Waiting;
    }

    // ── Identity ─────────────────────────────────────────────────────────────
    public Guid Id { get; private set; }

    // ── Relationships ─────────────────────────────────────────────────────────
    /// <summary>The charger unit the driver is waiting for.</summary>
    public Guid ChargerId { get; private set; }

    /// <summary>The registered driver queued on the waitlist.</summary>
    public Guid DriverId { get; private set; }

    // ── Slot preference ───────────────────────────────────────────────────────
    /// <summary>The driver's preferred session start time.</summary>
    public DateTimeOffset RequestedStartTime { get; private set; }

    /// <summary>
    /// Lower value = higher priority. Zero is the default for new entries.
    /// The application service may assign a non-zero value based on
    /// membership tier or submission time.
    /// </summary>
    public int Priority { get; private set; }

    // ── Status ────────────────────────────────────────────────────────────────
    public WaitlistStatus Status { get; private set; }

    // ── Navigation properties (populated by EF Core) ──────────────────────────
    public User Driver { get; private set; } = null!;

    // ── Factory ───────────────────────────────────────────────────────────────

    /// <summary>
    /// Adds a driver to the waitlist for a charger.
    /// </summary>
    /// <param name="chargerId">Target charger unit.</param>
    /// <param name="driverId">Registered driver requesting the slot.</param>
    /// <param name="requestedStartTime">Preferred session start time (must be in the future).</param>
    /// <param name="priority">Lower = higher queue priority (default 0).</param>
    public static WaitlistEntry Create(
        Guid chargerId,
        Guid driverId,
        DateTimeOffset requestedStartTime,
        int priority = 0)
    {
        if (requestedStartTime < DateTimeOffset.UtcNow.AddMinutes(-1))
            throw new ArgumentException(
                "Requested start time cannot be in the past.", nameof(requestedStartTime));

        return new WaitlistEntry(chargerId, driverId, requestedStartTime, priority);
    }

    // ── State transitions ─────────────────────────────────────────────────────

    /// <summary>
    /// Promotes this entry when a slot becomes available.
    /// Called by the application service after a cancellation triggers waitlist evaluation.
    /// </summary>
    public void Promote()
    {
        if (Status != WaitlistStatus.Waiting)
            throw new InvalidOperationException(
                $"Only Waiting entries can be promoted. Current status: {Status}.");

        Status = WaitlistStatus.Promoted;
    }

    /// <summary>
    /// Expires this entry when the requested time window has passed without promotion.
    /// </summary>
    public void Expire()
    {
        if (Status != WaitlistStatus.Waiting)
            throw new InvalidOperationException(
                $"Only Waiting entries can be expired. Current status: {Status}.");

        Status = WaitlistStatus.Expired;
    }
}
