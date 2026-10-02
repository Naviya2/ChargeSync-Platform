using Application.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/admin/stations")]
[Authorize(Roles = "Admin")]
public class AdminStationsController : ControllerBase
{
    private readonly IAdminStationService _adminStationService;

    public AdminStationsController(IAdminStationService adminStationService)
    {
        _adminStationService = adminStationService;
    }

    [HttpGet("pending")]
    public async Task<IActionResult> GetPendingStations(CancellationToken cancellationToken)
    {
        var stations = await _adminStationService.GetPendingStationsAsync(cancellationToken);
        return Ok(stations);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetStationById(Guid id, CancellationToken cancellationToken)
    {
        var station = await _adminStationService.GetStationByIdAsync(id, cancellationToken);
        if (station == null) return NotFound();
        return Ok(station);
    }

    [HttpPut("{id:guid}/approve")]
    public async Task<IActionResult> ApproveStation(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            await _adminStationService.ApproveStationAsync(id, cancellationToken);
            return NoContent();
        }
        catch (InvalidOperationException)
        {
            return NotFound();
        }
    }

    [HttpPut("{id:guid}/reject")]
    public async Task<IActionResult> RejectStation(Guid id, [FromBody] RejectStationRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Reason))
            return BadRequest(new { Message = "Rejection reason is required." });

        try
        {
            await _adminStationService.RejectStationAsync(id, request.Reason, cancellationToken);
            return NoContent();
        }
        catch (InvalidOperationException)
        {
            return NotFound();
        }
    }
}

public class RejectStationRequest
{
    public string Reason { get; set; } = null!;
}
