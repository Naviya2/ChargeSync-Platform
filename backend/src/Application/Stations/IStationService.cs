using Application.Stations.Models;

namespace Application.Stations;

public interface IStationService
{
    Task<List<StationDto>> GetMyStationsAsync(Guid ownerId, CancellationToken cancellationToken = default);
    Task<StationDto?> GetStationByIdAsync(Guid stationId, Guid ownerId, CancellationToken cancellationToken = default);
    Task<StationDto> RegisterStationAsync(Guid ownerId, RegisterStationRequest request, CancellationToken cancellationToken = default);
    Task<ChargerDto> AddChargerAsync(Guid stationId, Guid ownerId, AddChargerRequest request, CancellationToken cancellationToken = default);
    Task UpdateOperatingHoursAsync(Guid stationId, Guid ownerId, List<OperatingHourDto> hours, CancellationToken cancellationToken = default);
    Task<MaintenanceWindowDto> AddMaintenanceWindowAsync(Guid chargerId, Guid ownerId, MaintenanceWindowDto request, CancellationToken cancellationToken = default);
}
