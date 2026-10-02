namespace Application.Reservations;

public interface IReservationService
{
    Task<bool> HasActiveReservationAsync(Guid chargerId, DateTimeOffset startTime, DateTimeOffset endTime, CancellationToken cancellationToken = default);
}
