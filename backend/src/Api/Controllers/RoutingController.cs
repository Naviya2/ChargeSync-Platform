using Application.ReservationPlanning.Models;
using Application.ReservationPlanning.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Driver")]
public sealed class RoutingController : ControllerBase
{
    private readonly IRoutingService _routingService;

    public RoutingController(IRoutingService routingService)
    {
        _routingService = routingService;
    }

    [HttpPost("matrix")]
    public async Task<ActionResult<RouteMatrixResponse>> GetMatrix([FromBody] RouteMatrixRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _routingService.GetMatrixAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (HttpRequestException ex)
        {
            return StatusCode(502, new { message = "External routing service unavailable or returned an error.", details = ex.Message });
        }
    }

    [HttpPost("directions")]
    public async Task<ActionResult<RouteDirectionsResponse>> GetDirections([FromBody] RouteDirectionsRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _routingService.GetDirectionsAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (HttpRequestException ex)
        {
            return StatusCode(502, new { message = "External routing service unavailable or returned an error.", details = ex.Message });
        }
    }
}
