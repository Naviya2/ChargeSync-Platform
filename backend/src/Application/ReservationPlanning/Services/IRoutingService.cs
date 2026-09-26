using Application.ReservationPlanning.Models;

namespace Application.ReservationPlanning.Services;

/// <summary>
/// Provides routing functionality using openrouteservice.
/// Used by the driver application for displaying routes to stations and
/// by the AI Agent for calculating travel constraints.
/// </summary>
public interface IRoutingService
{
    Task<RouteMatrixResponse> GetMatrixAsync(RouteMatrixRequest request, CancellationToken cancellationToken = default);
    Task<RouteDirectionsResponse> GetDirectionsAsync(RouteDirectionsRequest request, CancellationToken cancellationToken = default);
}
