using Application.Sessions.Models;
using Domain.Entities;

namespace Application.Sessions;

public interface ISessionService
{
    Task<ChargingSessionDto> StartAsync(
        Guid requesterId,
        string requesterRole,
        Guid reservationId,
        CancellationToken cancellationToken = default);

    Task StartForCheckedInReservationAsync(
        Reservation reservation,
        Guid staffUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ChargingSessionDto>> GetListAsync(
        Guid requesterId,
        string requesterRole,
        SessionFilter filter,
        CancellationToken cancellationToken = default);

    Task<ChargingSessionDto?> GetByIdAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default);

    Task<ChargingSessionDto> StopAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        decimal? staffOverriddenKwh,
        CancellationToken cancellationToken = default);
}
