using Domain.Enums;
using Application.Payments.Models;

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
    public string StationName { get; set; } = string.Empty;
    public string ChargerIdentifier { get; set; } = string.Empty;
    public string BayLabel { get; set; } = string.Empty;
    public decimal ChargerPowerKw { get; set; }
    public decimal TariffPerKwh { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset? EndTime { get; set; }
    public decimal? AutoCalculatedKwh { get; set; }
    public decimal? StaffOverriddenKwh { get; set; }
    public decimal? FinalEnergyDeliveredKwh { get; set; }
    public Guid? StaffUserId { get; set; }
    public ChargingSessionStatus Status { get; set; }
}

public sealed class SessionCompletionDto
{
    public ChargingSessionDto Session { get; set; } = null!;
    public PaymentInvoiceDto Invoice { get; set; } = null!;
}
