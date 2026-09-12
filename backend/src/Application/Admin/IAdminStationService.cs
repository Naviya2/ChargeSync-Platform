using Application.Stations.Models;

namespace Application.Admin;

public interface IAdminStationService
{
    Task<List<StationDto>> GetPendingStationsAsync(CancellationToken cancellationToken = default);
    Task<StationDto?> GetStationByIdAsync(Guid stationId, CancellationToken cancellationToken = default);
    Task ApproveStationAsync(Guid stationId, CancellationToken cancellationToken = default);
    Task RejectStationAsync(Guid stationId, string reason, CancellationToken cancellationToken = default);
}
