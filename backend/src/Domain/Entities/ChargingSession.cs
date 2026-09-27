using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

public sealed class ChargingSession : AuditableEntity
{
    private ChargingSession() { }

    private ChargingSession(Reservation reservation, Guid staffUserId, DateTimeOffset startTime)
    {
        Reservation = reservation;
        ReservationId = reservation.Id;
        StaffUserId = staffUserId;
        StartTime = startTime;
        Status = ChargingSessionStatus.InProgress;
    }

    public Guid Id { get; private set; }
    public Guid ReservationId { get; private set; }
    public DateTimeOffset StartTime { get; private set; }
    public DateTimeOffset? EndTime { get; private set; }
    public decimal? AutoCalculatedKwh { get; private set; }
    public decimal? StaffOverriddenKwh { get; private set; }
    public decimal? FinalEnergyDeliveredKwh { get; private set; }
    public Guid? StaffUserId { get; private set; }
    public ChargingSessionStatus Status { get; private set; }

    public Reservation Reservation { get; private set; } = null!;
    public User? StaffUser { get; private set; }

    public static ChargingSession Start(
        Reservation reservation,
        Guid staffUserId,
        DateTimeOffset? startTime = null)
    {
        ArgumentNullException.ThrowIfNull(reservation);
        if (reservation.Status != ReservationStatus.CheckedIn)
            throw new InvalidOperationException("A session can only start for a checked-in reservation.");
        if (staffUserId == Guid.Empty)
            throw new ArgumentException("A staff user is required.", nameof(staffUserId));

        return new ChargingSession(reservation, staffUserId, startTime ?? DateTimeOffset.UtcNow);
    }

    public void Stop(DateTimeOffset endTime, decimal chargerPowerKw, decimal? staffOverriddenKwh)
    {
        if (Status != ChargingSessionStatus.InProgress)
            throw new InvalidOperationException("Only an in-progress session can be stopped.");
        if (endTime <= StartTime)
            throw new ArgumentException("Session end time must be after its start time.", nameof(endTime));
        if (chargerPowerKw <= 0)
            throw new ArgumentException("Charger power must be positive.", nameof(chargerPowerKw));
        if (staffOverriddenKwh is <= 0)
            throw new ArgumentException("Staff-overridden energy must be positive when supplied.", nameof(staffOverriddenKwh));

        var durationHours = (decimal)(endTime - StartTime).TotalHours;
        var automaticKwh = decimal.Round(chargerPowerKw * durationHours, 2, MidpointRounding.AwayFromZero);

        EndTime = endTime;
        AutoCalculatedKwh = automaticKwh;
        StaffOverriddenKwh = staffOverriddenKwh;
        FinalEnergyDeliveredKwh = staffOverriddenKwh ?? automaticKwh;

        var discrepancyRatio = automaticKwh == 0 || staffOverriddenKwh is null
            ? 0
            : Math.Abs(staffOverriddenKwh.Value - automaticKwh) / automaticKwh;

        Status = discrepancyRatio > 0.15m
            ? ChargingSessionStatus.DiscrepancyFlagged
            : ChargingSessionStatus.Completed;
    }
}
