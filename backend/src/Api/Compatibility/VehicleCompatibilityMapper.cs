using AgentClient.Models;
using Application.Vehicles.Models;
using Domain.Entities;
using Domain.Enums;

namespace Api.Compatibility;

internal static class VehicleCompatibilityMapper
{
    public static double DistanceKm(double latitude1, double longitude1, double latitude2, double longitude2)
    {
        const double earthRadiusKm = 6371;
        var latitude = DegreesToRadians(latitude2 - latitude1);
        var longitude = DegreesToRadians(longitude2 - longitude1);
        var a = Math.Pow(Math.Sin(latitude / 2), 2)
            + Math.Cos(DegreesToRadians(latitude1)) * Math.Cos(DegreesToRadians(latitude2)) * Math.Pow(Math.Sin(longitude / 2), 2);
        return earthRadiusKm * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double DegreesToRadians(double degrees) => degrees * Math.PI / 180;

    public static AgentVehicleInput ToAgent(Vehicle vehicle) => new()
    {
        VehicleId = vehicle.Id.ToString(),
        Make = vehicle.Make,
        Model = vehicle.Model,
        Connector = vehicle.Connector.ToString(),
        BatteryCapacityKwh = vehicle.BatteryCapacityKwh,
        MaxChargeRateKw = vehicle.MaxChargeRateKw,
        LicensePlate = vehicle.LicensePlate
    };

    public static AgentStationInput ToAgent(Station station, double? distanceKm = null) => new()
    {
        StationId = station.Id.ToString(),
        Name = station.Name,
        Address = station.Address,
        Latitude = station.Latitude,
        Longitude = station.Longitude,
        DistanceKm = distanceKm,
        Chargers = station.Chargers.Select(ToAgent).ToList()
    };

    public static AgentChargerInput ToAgent(Charger charger) => new()
    {
        ChargerId = charger.Id.ToString(),
        Identifier = charger.Identifier,
        Connector = charger.Connector.ToString(),
        PowerKw = charger.PowerKw,
        Tariff = charger.Tariff,
        Status = charger.Status.ToString(),
        BayLabel = charger.BayLabel
    };

    public static AgentStationInput ToAgent(CompatibleStationDto station) => new()
    {
        StationId = station.StationId.ToString(),
        Name = station.Name,
        Address = station.Address,
        Latitude = station.Latitude,
        Longitude = station.Longitude,
        DistanceKm = station.DistanceKm,
        Chargers = station.Chargers.Select(c => new AgentChargerInput
        {
            ChargerId = c.ChargerId.ToString(),
            Identifier = c.Identifier,
            Connector = c.Connector.ToString(),
            PowerKw = c.PowerKw
        }).ToList()
    };

    public static void Overlay(CompatibleStationDto local, AgentBatchStationScore ai)
    {
        local.CompatibilityScore = ai.CompatibilityScore;
        local.IsCompatible = ai.IsCompatible;
        if (ai.Chargers.Count == 0) return;

        local.Chargers = ai.Chargers.Select(ToDto).ToList();
    }

    public static CompatibleChargerDto ToDto(AgentChargerCompatibilityDetail charger)
    {
        Guid.TryParse(charger.ChargerId, out var chargerId);
        if (!Enum.TryParse<ConnectorType>(charger.Connector, ignoreCase: true, out var connector))
            connector = ConnectorType.CCS2;

        return new CompatibleChargerDto
        {
            ChargerId = chargerId,
            Identifier = charger.Identifier,
            Connector = connector,
            PowerKw = charger.PowerKw,
            IsCompatible = charger.IsCompatible,
            EffectiveChargingPowerKw = charger.EffectivePowerKw,
            EstimatedChargeTimeMinutes = charger.EstimatedChargeTimeMinutes,
            EstimatedChargeTimeFormatted = charger.EstimatedChargeTimeFormatted
        };
    }

    public static CompatibilityEvaluationDto ToDto(Guid stationId, AgentCompatibilityResponse ai)
    {
        Guid? bestChargerId = Guid.TryParse(ai.BestChargerId, out var parsed) ? parsed : null;

        return new CompatibilityEvaluationDto
        {
            StationId = stationId,
            IsCompatible = ai.IsCompatible,
            CompatibilityScore = ai.CompatibilityScore,
            BestChargerId = bestChargerId,
            EffectiveChargingPowerKw = ai.EffectiveChargingPowerKw,
            EstimatedChargeTimeMinutes = ai.EstimatedChargeTimeMinutes,
            EstimatedChargeTimeFormatted = ai.EstimatedChargeTimeFormatted,
            Chargers = ai.Chargers.Select(ToDto).ToList(),
            Warnings = ai.Warnings,
            SuggestedAlternatives = ai.SuggestedAlternatives.Select(ToDto).ToList(),
            AiInsight = ai.AiInsight
        };
    }

    public static AlternativeStationDto ToDto(AgentAlternativeStationSuggestion suggestion)
    {
        Guid.TryParse(suggestion.StationId, out var stationId);
        return new AlternativeStationDto
        {
            StationId = stationId,
            Name = suggestion.Name,
            Address = suggestion.Address,
            DistanceKm = suggestion.DistanceKm,
            CompatibilityScore = suggestion.CompatibilityScore,
            BestPowerKw = suggestion.BestPowerKw,
            EstimatedChargeTimeFormatted = suggestion.EstimatedChargeTimeFormatted,
            Reason = suggestion.Reason
        };
    }

    public static CompatibilityEvaluationDto FromLocal(CompatibleStationDto local, IReadOnlyList<CompatibleStationDto> nearby)
    {
        var alternatives = nearby
            .Where(s => s.StationId != local.StationId && s.IsCompatible)
            .OrderByDescending(s => s.CompatibilityScore)
            .ThenBy(s => s.DistanceKm)
            .Take(3)
            .Select(s =>
            {
                var best = s.Chargers.Where(c => c.IsCompatible)
                    .OrderByDescending(c => c.EffectiveChargingPowerKw)
                    .FirstOrDefault();
                return new AlternativeStationDto
                {
                    StationId = s.StationId,
                    Name = s.Name,
                    Address = s.Address,
                    DistanceKm = s.DistanceKm,
                    CompatibilityScore = s.CompatibilityScore,
                    BestPowerKw = best?.EffectiveChargingPowerKw ?? 0,
                    EstimatedChargeTimeFormatted = best?.EstimatedChargeTimeFormatted,
                    Reason = best == null
                        ? "Compatible charger available nearby."
                        : $"Provides compatible {best.Connector} at {best.EffectiveChargingPowerKw:0} kW."
                };
            })
            .ToList();

        var bestLocal = local.Chargers.Where(c => c.IsCompatible)
            .OrderByDescending(c => c.EffectiveChargingPowerKw)
            .FirstOrDefault();

        return new CompatibilityEvaluationDto
        {
            StationId = local.StationId,
            IsCompatible = local.IsCompatible,
            CompatibilityScore = local.CompatibilityScore,
            BestChargerId = bestLocal?.ChargerId,
            EffectiveChargingPowerKw = bestLocal?.EffectiveChargingPowerKw ?? 0,
            EstimatedChargeTimeMinutes = bestLocal?.EstimatedChargeTimeMinutes,
            EstimatedChargeTimeFormatted = bestLocal?.EstimatedChargeTimeFormatted,
            Chargers = local.Chargers,
            Warnings = local.IsCompatible
                ? new List<string>()
                : new List<string> { $"No matching {string.Join(", ", local.Chargers.Select(c => c.Connector).Distinct())} connector for this vehicle." },
            SuggestedAlternatives = alternatives,
            AiInsight = local.IsCompatible
                ? $"{local.Name} is compatible (score {local.CompatibilityScore}/100)."
                : $"{local.Name} is not compatible with this vehicle. Check suggested alternatives."
        };
    }
}
