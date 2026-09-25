using Application.Common.Interfaces;
using Application.Stations.Models;
using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Application.Stations;

public class StationService : IStationService
{
    private readonly IAppDbContext _context;

    public StationService(IAppDbContext context)
    {
        _context = context;
    }

    public async Task<List<StationDto>> GetMyStationsAsync(Guid ownerId, CancellationToken cancellationToken = default)
    {
        var stations = await _context.Stations
            .Include(s => s.Chargers)
                .ThenInclude(c => c.MaintenanceWindows)
            .Include(s => s.OperatingHours)
            .Where(s => s.OwnerId == ownerId)
            .ToListAsync(cancellationToken);

        return stations.Select(MapToDto).ToList();
    }

    public async Task<List<StationDto>> GetAllStationsAsync(CancellationToken cancellationToken = default)
    {
        var stations = await _context.Stations
            .Include(s => s.Chargers)
                .ThenInclude(c => c.MaintenanceWindows)
            .Include(s => s.OperatingHours)
            .OrderBy(s => s.Id)
            .ToListAsync(cancellationToken);

        return stations.Select(MapToDto).ToList();
    }

    public async Task<List<StationDto>> SearchStationsAsync(double? latitude, double? longitude, double radiusKm, ConnectorType? connector, string? query, CancellationToken cancellationToken = default)
    {
        var queryable = _context.Stations
            .Include(s => s.Chargers)
                .ThenInclude(c => c.MaintenanceWindows)
            .Include(s => s.OperatingHours)
            .Where(s => s.Status == StationStatus.Active);

        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLower();
            queryable = queryable.Where(s => s.Name.ToLower().Contains(q) || s.Address.ToLower().Contains(q));
        }

        if (connector.HasValue)
        {
            queryable = queryable.Where(s => s.Chargers.Any(c => c.Connector == connector.Value));
        }

        var list = await queryable.ToListAsync(cancellationToken);

        if (latitude.HasValue && longitude.HasValue)
        {
            list = list.Where(s => DistanceKm(latitude.Value, longitude.Value, s.Latitude, s.Longitude) <= radiusKm)
                       .OrderBy(s => DistanceKm(latitude.Value, longitude.Value, s.Latitude, s.Longitude))
                       .ToList();
        }

        return list.Select(MapToDto).ToList();
    }

    private static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double r = 6371;
        var dLat = (lat2 - lat1) * Math.PI / 180;
        var dLon = (lon2 - lon1) * Math.PI / 180;
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(lat1 * Math.PI / 180) * Math.Cos(lat2 * Math.PI / 180) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return r * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    public async Task<StationDto?> GetStationByIdAsync(Guid stationId, Guid ownerId, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations
            .Include(s => s.Chargers)
                .ThenInclude(c => c.MaintenanceWindows)
            .Include(s => s.OperatingHours)
            .FirstOrDefaultAsync(s => s.Id == stationId && s.OwnerId == ownerId, cancellationToken);

        if (station == null) return null;

        return MapToDto(station);
    }

    public async Task<StationDto> RegisterStationAsync(Guid ownerId, RegisterStationRequest request, CancellationToken cancellationToken = default)
    {
        var station = Station.Create(request.Name, request.Address, request.Latitude, request.Longitude, ownerId, request.DocumentUrls);
        
        _context.Stations.Add(station);
        await _context.SaveChangesAsync(cancellationToken);

        return MapToDto(station);
    }

    public async Task<StationDto> UpdateStationAsync(Guid stationId, Guid ownerId, UpdateStationRequest request, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations
            .Include(s => s.Chargers)
                .ThenInclude(c => c.MaintenanceWindows)
            .Include(s => s.OperatingHours)
            .FirstOrDefaultAsync(s => s.Id == stationId && s.OwnerId == ownerId, cancellationToken);

        if (station == null)
            throw new UnauthorizedAccessException("Station not found or you are not the owner.");

        station.UpdateDetails(request.Name, request.Address, request.Latitude, request.Longitude);
        
        await _context.SaveChangesAsync(cancellationToken);

        return MapToDto(station);
    }


    public async Task<ChargerDto> AddChargerAsync(Guid stationId, Guid ownerId, AddChargerRequest request, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations
            .FirstOrDefaultAsync(s => s.Id == stationId && s.OwnerId == ownerId, cancellationToken);

        if (station == null)
            throw new UnauthorizedAccessException("Station not found or you are not the owner.");

        if (station.Status != StationStatus.Active)
            throw new InvalidOperationException("Cannot add chargers to a station that is not active.");

        var charger = Charger.Create(station.Id, request.Identifier, request.BayLabel, request.Connector, request.PowerKw, request.Tariff);
        
        station.AddCharger(charger);
        await _context.SaveChangesAsync(cancellationToken);

        return MapChargerToDto(charger);
    }

    public async Task<ChargerDto> UpdateChargerAsync(Guid stationId, Guid chargerId, Guid ownerId, UpdateChargerRequest request, CancellationToken cancellationToken = default)
    {
        var charger = await _context.Chargers
            .Include(c => c.Station)
            .FirstOrDefaultAsync(c => c.Id == chargerId && c.StationId == stationId && c.Station.OwnerId == ownerId, cancellationToken);

        if (charger == null)
            throw new UnauthorizedAccessException("Charger not found or you are not the owner.");

        charger.UpdateDetails(request.Identifier, request.BayLabel, request.Connector, request.PowerKw, request.Tariff);
        
        await _context.SaveChangesAsync(cancellationToken);

        return MapChargerToDto(charger);
    }

    public async Task DeleteChargerAsync(Guid stationId, Guid chargerId, Guid ownerId, CancellationToken cancellationToken = default)
    {
        var charger = await _context.Chargers
            .Include(c => c.Station)
            .FirstOrDefaultAsync(c => c.Id == chargerId && c.StationId == stationId && c.Station.OwnerId == ownerId, cancellationToken);

        if (charger == null)
            throw new UnauthorizedAccessException("Charger not found or you are not the owner.");

        _context.Chargers.Remove(charger);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateOperatingHoursAsync(Guid stationId, Guid ownerId, List<OperatingHourDto> hours, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations
            .Include(s => s.OperatingHours)
            .FirstOrDefaultAsync(s => s.Id == stationId && s.OwnerId == ownerId, cancellationToken);

        if (station == null)
            throw new UnauthorizedAccessException("Station not found or you are not the owner.");

        var updatedHours = hours.Select(h => OperatingHour.Create(station.Id, h.DayOfWeek, h.IsEnabled, h.OpenTime, h.CloseTime)).ToList();
        
        station.UpdateOperatingHours(updatedHours);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<MaintenanceWindowDto> AddMaintenanceWindowAsync(Guid chargerId, Guid ownerId, MaintenanceWindowDto request, CancellationToken cancellationToken = default)
    {
        var charger = await _context.Chargers
            .Include(c => c.Station)
            .FirstOrDefaultAsync(c => c.Id == chargerId && c.Station.OwnerId == ownerId, cancellationToken);

        if (charger == null)
            throw new UnauthorizedAccessException("Charger not found or you are not the owner.");

        var maintenance = MaintenanceWindow.Create(charger.Id, request.Reason, request.StartTime, request.EndTime);
        
        _context.MaintenanceWindows.Add(maintenance);
        await _context.SaveChangesAsync(cancellationToken);

        return new MaintenanceWindowDto
        {
            Id = maintenance.Id,
            Reason = maintenance.Reason,
            StartTime = maintenance.StartTime,
            EndTime = maintenance.EndTime
        };
    }

    public async Task<MaintenanceWindowDto> UpdateMaintenanceWindowAsync(Guid maintenanceId, Guid ownerId, MaintenanceWindowDto request, CancellationToken cancellationToken = default)
    {
        var maintenance = await _context.MaintenanceWindows
            .Include(m => m.Charger)
                .ThenInclude(c => c.Station)
            .FirstOrDefaultAsync(m => m.Id == maintenanceId && m.Charger.Station.OwnerId == ownerId, cancellationToken);

        if (maintenance == null)
            throw new UnauthorizedAccessException("Maintenance window not found or you are not the owner.");

        maintenance.Update(request.Reason, request.StartTime, request.EndTime);
        
        await _context.SaveChangesAsync(cancellationToken);

        return new MaintenanceWindowDto
        {
            Id = maintenance.Id,
            Reason = maintenance.Reason,
            StartTime = maintenance.StartTime,
            EndTime = maintenance.EndTime
        };
    }

    public async Task DeleteMaintenanceWindowAsync(Guid maintenanceId, Guid ownerId, CancellationToken cancellationToken = default)
    {
        var maintenance = await _context.MaintenanceWindows
            .Include(m => m.Charger)
                .ThenInclude(c => c.Station)
            .FirstOrDefaultAsync(m => m.Id == maintenanceId && m.Charger.Station.OwnerId == ownerId, cancellationToken);

        if (maintenance == null)
            throw new UnauthorizedAccessException("Maintenance window not found or you are not the owner.");

        _context.MaintenanceWindows.Remove(maintenance);
        await _context.SaveChangesAsync(cancellationToken);
    }

    private static StationDto MapToDto(Station station)
    {
        return new StationDto
        {
            Id = station.Id,
            Name = station.Name,
            Address = station.Address,
            Latitude = station.Latitude,
            Longitude = station.Longitude,
            Status = station.Status,
            RejectionReason = station.RejectionReason,
            OwnerId = station.OwnerId,
            DocumentUrls = station.DocumentUrls,
            CreatedAt = station.CreatedAt,
            Chargers = station.Chargers?.Select(MapChargerToDto).ToList() ?? new List<ChargerDto>(),
            OperatingHours = station.OperatingHours?.Select(h => new OperatingHourDto
            {
                Id = h.Id,
                DayOfWeek = h.DayOfWeek,
                IsEnabled = h.IsEnabled,
                OpenTime = h.OpenTime,
                CloseTime = h.CloseTime
            }).ToList() ?? new List<OperatingHourDto>()
        };
    }

    private static ChargerDto MapChargerToDto(Charger charger)
    {
        return new ChargerDto
        {
            Id = charger.Id,
            StationId = charger.StationId,
            Identifier = charger.Identifier,
            BayLabel = charger.BayLabel,
            Connector = charger.Connector,
            PowerKw = charger.PowerKw,
            Tariff = charger.Tariff,
            Status = charger.Status,
            MaintenanceWindows = charger.MaintenanceWindows?.Select(m => new MaintenanceWindowDto
            {
                Id = m.Id,
                Reason = m.Reason,
                StartTime = m.StartTime,
                EndTime = m.EndTime
            }).ToList() ?? new List<MaintenanceWindowDto>()
        };
    }
}
