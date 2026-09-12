using Application.Common.Interfaces;
using Application.Stations.Models;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Application.Admin;

public class AdminStationService : IAdminStationService
{
    private readonly IAppDbContext _context;

    public AdminStationService(IAppDbContext context)
    {
        _context = context;
    }

    public async Task<List<StationDto>> GetPendingStationsAsync(CancellationToken cancellationToken = default)
    {
        var stations = await _context.Stations
            .Include(s => s.Chargers)
            .Include(s => s.OperatingHours)
            .Where(s => s.Status == StationStatus.Pending)
            .ToListAsync(cancellationToken);

        return stations.Select(MapToDto).ToList();
    }
    
    public async Task<StationDto?> GetStationByIdAsync(Guid stationId, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations
            .Include(s => s.Chargers)
            .Include(s => s.OperatingHours)
            .FirstOrDefaultAsync(s => s.Id == stationId, cancellationToken);
            
        return station == null ? null : MapToDto(station);
    }

    public async Task ApproveStationAsync(Guid stationId, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations.FindAsync(new object[] { stationId }, cancellationToken);
        if (station == null) throw new InvalidOperationException("Station not found.");

        station.Approve();
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task RejectStationAsync(Guid stationId, string reason, CancellationToken cancellationToken = default)
    {
        var station = await _context.Stations.FindAsync(new object[] { stationId }, cancellationToken);
        if (station == null) throw new InvalidOperationException("Station not found.");

        station.Reject(reason);
        await _context.SaveChangesAsync(cancellationToken);
    }

    private static StationDto MapToDto(Domain.Entities.Station station)
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
            Chargers = station.Chargers?.Select(c => new ChargerDto
            {
                Id = c.Id,
                StationId = c.StationId,
                Identifier = c.Identifier,
                Connector = c.Connector,
                PowerKw = c.PowerKw,
                Tariff = c.Tariff,
                Status = c.Status
            }).ToList() ?? new List<ChargerDto>()
        };
    }
}
