using Application.Common.Interfaces;
using Application.Stations;
using Application.Stations.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "StationOwner,Admin")]
public class StationsController : ControllerBase
{
    private readonly IStationService _stationService;
    private readonly ICurrentUser _currentUser;

    public StationsController(IStationService stationService, ICurrentUser currentUser)
    {
        _stationService = stationService;
        _currentUser = currentUser;
    }

    private Guid OwnerId => _currentUser.Id ?? Guid.Empty;

    [HttpGet]
    public async Task<IActionResult> GetMyStations(CancellationToken cancellationToken)
    {
        var stations = await _stationService.GetMyStationsAsync(OwnerId, cancellationToken);
        return Ok(stations);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetStationById(Guid id, CancellationToken cancellationToken)
    {
        var station = await _stationService.GetStationByIdAsync(id, OwnerId, cancellationToken);
        if (station == null) return NotFound();
        return Ok(station);
    }

    [HttpPost]
    public async Task<IActionResult> RegisterStation([FromBody] RegisterStationRequest request, CancellationToken cancellationToken)
    {
        var station = await _stationService.RegisterStationAsync(OwnerId, request, cancellationToken);
        return CreatedAtAction(nameof(GetStationById), new { id = station.Id }, station);
    }

    [HttpPost("{id:guid}/chargers")]
    public async Task<IActionResult> AddCharger(Guid id, [FromBody] AddChargerRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var charger = await _stationService.AddChargerAsync(id, OwnerId, request, cancellationToken);
            return Ok(charger);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { Message = ex.Message });
        }
    }

    [HttpPut("{id:guid}/operating-hours")]
    public async Task<IActionResult> UpdateOperatingHours(Guid id, [FromBody] List<OperatingHourDto> hours, CancellationToken cancellationToken)
    {
        try
        {
            await _stationService.UpdateOperatingHoursAsync(id, OwnerId, hours, cancellationToken);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpPost("chargers/{chargerId:guid}/maintenance")]
    public async Task<IActionResult> AddMaintenanceWindow(Guid chargerId, [FromBody] MaintenanceWindowDto request, CancellationToken cancellationToken)
    {
        try
        {
            var mw = await _stationService.AddMaintenanceWindowAsync(chargerId, OwnerId, request, cancellationToken);
            return Ok(mw);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }
}
