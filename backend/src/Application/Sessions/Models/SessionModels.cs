using Domain.Enums;

namespace Application.Sessions.Models;

public sealed class StartSessionRequest
{
    public Guid ReservationId { get; set; }
}

public sealed class SessionFilter
{
    public ChargingSessionStatus? Status { get; set; }
}

public sealed class ChargingSessionDto
{
    public Guid Id { get; set; }
    public Guid ReservationId { get; set; }
    public Guid ChargerId { get; set; }
    public Guid? DriverId { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset? EndTime { get; set; }
    public decimal? AutoCalculatedKwh { get; set; }
    public decimal? StaffOverriddenKwh { get; set; }
    public decimal? FinalEnergyDeliveredKwh { get; set; }
    public Guid? StaffUserId { get; set; }
    public ChargingSessionStatus Status { get; set; }
}
