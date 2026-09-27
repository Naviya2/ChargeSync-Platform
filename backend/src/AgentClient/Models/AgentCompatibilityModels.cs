using System.Text.Json.Serialization;

namespace AgentClient.Models;

public sealed class AgentVehicleInput
{
    [JsonPropertyName("vehicle_id")]
    public string VehicleId { get; set; } = string.Empty;

    [JsonPropertyName("make")]
    public string Make { get; set; } = string.Empty;

    [JsonPropertyName("model")]
    public string Model { get; set; } = string.Empty;

    [JsonPropertyName("connector")]
    public string Connector { get; set; } = string.Empty;

    [JsonPropertyName("battery_capacity_kwh")]
    public decimal BatteryCapacityKwh { get; set; }

    [JsonPropertyName("max_charge_rate_kw")]
    public decimal MaxChargeRateKw { get; set; }

    [JsonPropertyName("license_plate")]
    public string? LicensePlate { get; set; }
}

public sealed class AgentChargerInput
{
    [JsonPropertyName("charger_id")]
    public string ChargerId { get; set; } = string.Empty;

    [JsonPropertyName("identifier")]
    public string Identifier { get; set; } = string.Empty;

    [JsonPropertyName("connector")]
    public string Connector { get; set; } = string.Empty;

    [JsonPropertyName("power_kw")]
    public decimal PowerKw { get; set; }

    [JsonPropertyName("tariff")]
    public decimal? Tariff { get; set; }
}

public sealed class AgentStationInput
{
    [JsonPropertyName("station_id")]
    public string StationId { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("distance_km")]
    public double? DistanceKm { get; set; }

    [JsonPropertyName("chargers")]
    public List<AgentChargerInput> Chargers { get; set; } = new();
}

public sealed class AgentCompatibilityRequest
{
    [JsonPropertyName("vehicle")]
    public AgentVehicleInput Vehicle { get; set; } = new();

    [JsonPropertyName("target_station")]
    public AgentStationInput TargetStation { get; set; } = new();

    [JsonPropertyName("candidate_alternative_stations")]
    public List<AgentStationInput> CandidateAlternativeStations { get; set; } = new();
}

public sealed class AgentChargerCompatibilityDetail
{
    [JsonPropertyName("charger_id")]
    public string ChargerId { get; set; } = string.Empty;

    [JsonPropertyName("identifier")]
    public string Identifier { get; set; } = string.Empty;

    [JsonPropertyName("connector")]
    public string Connector { get; set; } = string.Empty;

    [JsonPropertyName("power_kw")]
    public decimal PowerKw { get; set; }

    [JsonPropertyName("is_compatible")]
    public bool IsCompatible { get; set; }

    [JsonPropertyName("effective_power_kw")]
    public decimal EffectivePowerKw { get; set; }

    [JsonPropertyName("estimated_charge_time_minutes")]
    public double? EstimatedChargeTimeMinutes { get; set; }

    [JsonPropertyName("estimated_charge_time_formatted")]
    public string? EstimatedChargeTimeFormatted { get; set; }
}

public sealed class AgentAlternativeStationSuggestion
{
    [JsonPropertyName("station_id")]
    public string StationId { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("distance_km")]
    public double DistanceKm { get; set; }

    [JsonPropertyName("compatibility_score")]
    public int CompatibilityScore { get; set; }

    [JsonPropertyName("best_power_kw")]
    public decimal BestPowerKw { get; set; }

    [JsonPropertyName("estimated_charge_time_formatted")]
    public string? EstimatedChargeTimeFormatted { get; set; }

    [JsonPropertyName("reason")]
    public string Reason { get; set; } = string.Empty;
}

public sealed class AgentCompatibilityResponse
{
    [JsonPropertyName("is_compatible")]
    public bool IsCompatible { get; set; }

    [JsonPropertyName("compatibility_score")]
    public int CompatibilityScore { get; set; }

    [JsonPropertyName("best_charger_id")]
    public string? BestChargerId { get; set; }

    [JsonPropertyName("effective_charging_power_kw")]
    public decimal EffectiveChargingPowerKw { get; set; }

    [JsonPropertyName("estimated_charge_time_minutes")]
    public double? EstimatedChargeTimeMinutes { get; set; }

    [JsonPropertyName("estimated_charge_time_formatted")]
    public string? EstimatedChargeTimeFormatted { get; set; }

    [JsonPropertyName("chargers")]
    public List<AgentChargerCompatibilityDetail> Chargers { get; set; } = new();

    [JsonPropertyName("warnings")]
    public List<string> Warnings { get; set; } = new();

    [JsonPropertyName("suggested_alternatives")]
    public List<AgentAlternativeStationSuggestion> SuggestedAlternatives { get; set; } = new();

    [JsonPropertyName("ai_insight")]
    public string? AiInsight { get; set; }
}
