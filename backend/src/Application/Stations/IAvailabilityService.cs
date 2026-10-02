namespace Application.Stations;

public interface IAvailabilityService
{
    Task<bool> IsChargerAvailableAsync(Guid chargerId, DateTimeOffset checkTime, CancellationToken cancellationToken = default);
    Task<bool> IsChargerAvailableForPeriodAsync(Guid chargerId, DateTimeOffset startTime, DateTimeOffset endTime, CancellationToken cancellationToken = default);
}
