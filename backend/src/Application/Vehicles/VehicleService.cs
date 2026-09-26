using Application.Common.Interfaces;
using Application.Vehicles.Models;
using Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Application.Vehicles;

public sealed class VehicleService : IVehicleService
{
    private readonly IAppDbContext _db;

    public VehicleService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<VehicleDto>> GetMineAsync(Guid ownerId, CancellationToken cancellationToken = default) =>
        (await _db.Vehicles.AsNoTracking().Where(v => v.OwnerId == ownerId).OrderBy(v => v.Make).ThenBy(v => v.Model).ToListAsync(cancellationToken)).Select(ToDto).ToList();

    public async Task<VehicleDto?> GetByIdAsync(Guid ownerId, Guid vehicleId, CancellationToken cancellationToken = default)
    {
        var vehicle = await _db.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == vehicleId && v.OwnerId == ownerId, cancellationToken);
        return vehicle is null ? null : ToDto(vehicle);
    }

    public async Task<VehicleDto> CreateAsync(Guid ownerId, VehicleRequest request, CancellationToken cancellationToken = default)
    {
        var vehicle = Vehicle.Create(ownerId, request.Make, request.Model, request.Connector, request.BatteryCapacityKwh, request.MaxChargeRateKw, request.LicensePlate);
        _db.Vehicles.Add(vehicle);
        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(vehicle);
    }

    public async Task<VehicleDto?> UpdateAsync(Guid ownerId, Guid vehicleId, VehicleRequest request, CancellationToken cancellationToken = default)
    {
        var vehicle = await _db.Vehicles.FirstOrDefaultAsync(v => v.Id == vehicleId && v.OwnerId == ownerId, cancellationToken);
        if (vehicle is null) return null;

        vehicle.UpdateDetails(request.Make, request.Model, request.Connector, request.BatteryCapacityKwh, request.MaxChargeRateKw, request.LicensePlate);
        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(vehicle);
    }

    public async Task<bool> DeleteAsync(Guid ownerId, Guid vehicleId, CancellationToken cancellationToken = default)
    {
        var vehicle = await _db.Vehicles.FirstOrDefaultAsync(v => v.Id == vehicleId && v.OwnerId == ownerId, cancellationToken);
        if (vehicle is null) return false;

        _db.Vehicles.Remove(vehicle);
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IReadOnlyList<CompatibleStationDto>> FindCompatibleStationsAsync(Guid ownerId, Guid vehicleId, NearbyStationsRequest request, CancellationToken cancellationToken = default)
    {
        var vehicle = await _db.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == vehicleId && v.OwnerId == ownerId, cancellationToken)
            ?? throw new KeyNotFoundException("Vehicle was not found.");

        if (request.RadiusKm <= 0 || request.RadiusKm > 500)
            throw new ArgumentException("Radius must be greater than 0 and no more than 500 km.", nameof(request.RadiusKm));

        if (request.Latitude is < -90 or > 90 || request.Longitude is < -180 or > 180)
            throw new ArgumentException("Latitude or longitude is outside the valid range.", nameof(request));

        var stations = await _db.Stations.AsNoTracking().Include(s => s.Chargers)
            .Where(s => s.Status == Domain.Enums.StationStatus.Active).ToListAsync(cancellationToken);

        return stations.Select(station =>
        {
            var distance = DistanceKm(request.Latitude, request.Longitude, station.Latitude, station.Longitude);
            var chargers = station.Chargers.Select(charger =>
            {
                var isCompatible = charger.Connector == vehicle.Connector;
                var effectivePower = Math.Min(charger.PowerKw, vehicle.MaxChargeRateKw);
                double? estimatedMins = null;
                string? estimatedFormatted = null;

                if (effectivePower > 0 && vehicle.BatteryCapacityKwh > 0)
                {
                    var mins = (double)(vehicle.BatteryCapacityKwh * 0.7m / effectivePower) * 60.0;
                    estimatedMins = Math.Round(mins, 1);
                    var totalMins = (int)Math.Round(mins);
                    var hours = totalMins / 60;
                    var remMins = totalMins % 60;
                    estimatedFormatted = hours > 0
                        ? $"{hours}h {remMins}m (10-80%)"
                        : $"{totalMins} mins (10-80%)";
                }

                return new CompatibleChargerDto
                {
                    ChargerId = charger.Id,
                    Identifier = charger.Identifier,
                    Connector = charger.Connector,
                    PowerKw = charger.PowerKw,
                    IsCompatible = isCompatible,
                    EffectiveChargingPowerKw = effectivePower,
                    EstimatedChargeTimeMinutes = estimatedMins,
                    EstimatedChargeTimeFormatted = estimatedFormatted
                };
            }).ToList();
            var compatibleCount = chargers.Count(c => c.IsCompatible);
            var bestPowerFit = chargers.Where(c => c.IsCompatible).Select(c => Math.Min(20, (double)c.PowerKw / (double)vehicle.MaxChargeRateKw * 20)).DefaultIfEmpty(0).Max();
            var score = compatibleCount == 0 ? 0 : Math.Min(100, (int)Math.Round(60 + bestPowerFit + Math.Max(0, 20 - distance)));

            return new CompatibleStationDto
            {
                StationId = station.Id,
                Name = station.Name,
                Address = station.Address,
                Latitude = station.Latitude,
                Longitude = station.Longitude,
                DistanceKm = Math.Round(distance, 2),
                CompatibilityScore = score,
                IsCompatible = compatibleCount > 0,
                Chargers = chargers
            };
        }).Where(s => s.DistanceKm <= request.RadiusKm).OrderByDescending(s => s.IsCompatible).ThenByDescending(s => s.CompatibilityScore).ThenBy(s => s.DistanceKm).ToList();
    }

    private static VehicleDto ToDto(Vehicle vehicle) => new()
    {
        Id = vehicle.Id,
        OwnerId = vehicle.OwnerId,
        Make = vehicle.Make,
        Model = vehicle.Model,
        LicensePlate = vehicle.LicensePlate,
        Connector = vehicle.Connector,
        BatteryCapacityKwh = vehicle.BatteryCapacityKwh,
        MaxChargeRateKw = vehicle.MaxChargeRateKw,
        CreatedAt = vehicle.CreatedAt
    };

    private static double DistanceKm(double latitude1, double longitude1, double latitude2, double longitude2)
    {
        const double earthRadiusKm = 6371;
        var latitude = DegreesToRadians(latitude2 - latitude1);
        var longitude = DegreesToRadians(longitude2 - longitude1);
        var a = Math.Pow(Math.Sin(latitude / 2), 2) + Math.Cos(DegreesToRadians(latitude1)) * Math.Cos(DegreesToRadians(latitude2)) * Math.Pow(Math.Sin(longitude / 2), 2);
        return earthRadiusKm * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double DegreesToRadians(double degrees) => degrees * Math.PI / 180;
}