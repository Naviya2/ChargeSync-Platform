using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

/// <summary>
/// Records a single status transition on a <see cref="Reservation"/>, forming an
/// immutable audit trail.
///
/// Entries are append-only — never updated or deleted.
/// <c>ChangedByUserId</c> is nullable because system-automated transitions
/// (e.g. waitlist promotion) have no human actor.
/// </summary>
public class ReservationStatusHistory : AuditableEntity
{
    private ReservationStatusHistory() { }

    private ReservationStatusHistory(
        Guid reservationId,
        ReservationStatus? oldStatus,
        ReservationStatus newStatus,
        Guid? changedByUserId)
    {
        ReservationId = reservationId;
        OldStatus = oldStatus;
        NewStatus = newStatus;
        ChangedByUserId = changedByUserId;
        ChangedAt = DateTimeOffset.UtcNow;
    }

    // ── Identity ─────────────────────────────────────────────────────────────
    public Guid Id { get; private set; }

    // ── Relationships ─────────────────────────────────────────────────────────
    public Guid ReservationId { get; private set; }

    /// <summary>
    /// User (driver, staff, or admin) who triggered the transition.
    /// <c>null</c> for automated system transitions (e.g. waitlist promotion, expiry).
    /// </summary>
    public Guid? ChangedByUserId { get; private set; }

    // ── Status snapshot ───────────────────────────────────────────────────────
    /// <summary>Status before the transition. <c>null</c> for the initial creation entry.</summary>
    public ReservationStatus? OldStatus { get; private set; }

    public ReservationStatus NewStatus { get; private set; }

    /// <summary>Exact timestamp of the transition (UTC).</summary>
    public DateTimeOffset ChangedAt { get; private set; }

    // ── Navigation properties (populated by EF Core) ──────────────────────────
    public Reservation Reservation { get; private set; } = null!;
    public User? ChangedBy { get; private set; }

    // ── Factory ───────────────────────────────────────────────────────────────

    /// <summary>
    /// Records a status change on a reservation.
    /// </summary>
    /// <param name="reservationId">The reservation being transitioned.</param>
    /// <param name="oldStatus">Status before the change; <c>null</c> only on initial creation.</param>
    /// <param name="newStatus">Status after the change.</param>
    /// <param name="changedByUserId">Actor who triggered the change; <c>null</c> for automated changes.</param>
    public static ReservationStatusHistory Record(
        Guid reservationId,
        ReservationStatus? oldStatus,
        ReservationStatus newStatus,
        Guid? changedByUserId = null)
    {
        return new ReservationStatusHistory(reservationId, oldStatus, newStatus, changedByUserId);
    }
}
