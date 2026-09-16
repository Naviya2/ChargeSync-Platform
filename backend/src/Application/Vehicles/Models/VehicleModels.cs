using Domain.Enums;

namespace Application.Vehicles.Models;

public sealed class VehicleDto
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public string Make { get; set; } = null!;
    public string Model { get; set; } = null!;
    public string? LicensePlate { get; set; }
    public ConnectorType Connector { get; set; }
    public decimal BatteryCapacityKwh { get; set; }
    public decimal MaxChargeRateKw { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class VehicleRequest
{
    public string Make { get; set; } = null!;
    public string Model { get; set; } = null!;
    public string? LicensePlate { get; set; }
    public ConnectorType Connector { get; set; }
    public decimal BatteryCapacityKwh { get; set; }
    public decimal MaxChargeRateKw { get; set; }
}

public sealed class CompatibleStationDto
{
    public Guid StationId { get; set; }
    public string Name { get; set; } = null!;
    public string Address { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double DistanceKm { get; set; }
    public int CompatibilityScore { get; set; }
    public bool IsCompatible { get; set; }
    public List<CompatibleChargerDto> Chargers { get; set; } = new();
}

public sealed class CompatibleChargerDto
{
    public Guid ChargerId { get; set; }
    public string Identifier { get; set; } = null!;
    public ConnectorType Connector { get; set; }
    public decimal PowerKw { get; set; }
    public bool IsCompatible { get; set; }
}

public sealed class NearbyStationsRequest
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double RadiusKm { get; set; } = 25;
}