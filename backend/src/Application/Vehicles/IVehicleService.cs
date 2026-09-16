using Application.Vehicles.Models;

namespace Application.Vehicles;

public interface IVehicleService
{
    Task<IReadOnlyList<VehicleDto>> GetMineAsync(Guid ownerId, CancellationToken cancellationToken = default);
    Task<VehicleDto?> GetByIdAsync(Guid ownerId, Guid vehicleId, CancellationToken cancellationToken = default);
    Task<VehicleDto> CreateAsync(Guid ownerId, VehicleRequest request, CancellationToken cancellationToken = default);
    Task<VehicleDto?> UpdateAsync(Guid ownerId, Guid vehicleId, VehicleRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid ownerId, Guid vehicleId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<CompatibleStationDto>> FindCompatibleStationsAsync(Guid ownerId, Guid vehicleId, NearbyStationsRequest request, CancellationToken cancellationToken = default);
}