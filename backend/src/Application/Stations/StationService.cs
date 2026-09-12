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
        var station = Station.Create(request.Name, request.Address, request.Latitude, request.Longitude, ownerId);
        
        _context.Stations.Add(station);
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

        var maintenance = MaintenanceWindow.Create(charger.Id, request.Title, request.Reason, request.StartTime, request.EndTime);
        
        _context.MaintenanceWindows.Add(maintenance);
        await _context.SaveChangesAsync(cancellationToken);

        return new MaintenanceWindowDto
        {
            Id = maintenance.Id,
            Title = maintenance.Title,
            Reason = maintenance.Reason,
            StartTime = maintenance.StartTime,
            EndTime = maintenance.EndTime
        };
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
                Title = m.Title,
                Reason = m.Reason,
                StartTime = m.StartTime,
                EndTime = m.EndTime
            }).ToList() ?? new List<MaintenanceWindowDto>()
        };
    }
}
