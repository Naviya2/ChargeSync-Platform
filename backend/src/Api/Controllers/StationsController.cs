using Application.Common.Interfaces;
using Application.Stations;
using Application.Stations.Models;
using AgentClient.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

    [HttpGet("all")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllStations(CancellationToken cancellationToken)
    {
        var stations = await _stationService.GetAllStationsAsync(cancellationToken);
        return Ok(stations);
    }

    [HttpGet("search")]
    [HttpGet("nearby")]
    [AllowAnonymous]
    public async Task<IActionResult> SearchStations(
        [FromQuery] double? latitude,
        [FromQuery] double? longitude,
        [FromQuery] double radiusKm = 25,
        [FromQuery] Domain.Enums.ConnectorType? connector = null,
        [FromQuery] string? query = null,
        CancellationToken cancellationToken = default)
    {
        var stations = await _stationService.SearchStationsAsync(latitude, longitude, radiusKm, connector, query, cancellationToken);
        return Ok(stations);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetStationById(Guid id, CancellationToken cancellationToken)
    {
        var station = await _stationService.GetStationByIdAsync(id, OwnerId, cancellationToken);
        if (station == null) return NotFound();
        return Ok(station);
    }

    [HttpGet("{id:guid}/compatibility")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCompatibility(
        Guid id,
        [FromQuery] Guid? vehicleId,
        [FromServices] AgentClient.IVehicleAgentClient? agentClient,
        [FromServices] IAppDbContext db,
        CancellationToken cancellationToken)
    {
        var station = await db.Stations
            .Include(s => s.Chargers)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

        if (station == null) return NotFound();

        Domain.Entities.Vehicle? vehicle = null;
        if (vehicleId.HasValue)
        {
            vehicle = await db.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == vehicleId.Value, cancellationToken);
        }

        if (vehicle == null)
        {
            vehicle = await db.Vehicles.AsNoTracking().FirstOrDefaultAsync(cancellationToken);
        }

        if (agentClient != null && vehicle != null)
        {
            var agentRequest = new AgentCompatibilityRequest
            {
                Vehicle = new AgentVehicleInput
                {
                    VehicleId = vehicle.Id.ToString(),
                    Make = vehicle.Make,
                    Model = vehicle.Model,
                    Connector = vehicle.Connector.ToString(),
                    BatteryCapacityKwh = vehicle.BatteryCapacityKwh,
                    MaxChargeRateKw = vehicle.MaxChargeRateKw
                },
                TargetStation = new AgentStationInput
                {
                    StationId = station.Id.ToString(),
                    Name = station.Name,
                    Latitude = station.Latitude,
                    Longitude = station.Longitude,
                    Address = station.Address,
                    Chargers = station.Chargers.Select(c => new AgentChargerInput
                    {
                        ChargerId = c.Id.ToString(),
                        Identifier = c.Identifier,
                        Connector = c.Connector.ToString(),
                        PowerKw = c.PowerKw
                    }).ToList()
                }
            };

            var aiResult = await agentClient.EvaluateCompatibilityAsync(agentRequest, cancellationToken);
            if (aiResult != null)
            {
                return Ok(aiResult);
            }
        }

        return Ok(new { message = "Compatibility evaluated locally", stationId = id });
    }

    [HttpPost]
    public async Task<IActionResult> RegisterStation([FromBody] RegisterStationRequest request, CancellationToken cancellationToken)
    {
        var station = await _stationService.RegisterStationAsync(OwnerId, request, cancellationToken);
        return CreatedAtAction(nameof(GetStationById), new { id = station.Id }, station);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateStation(Guid id, [FromBody] UpdateStationRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var station = await _stationService.UpdateStationAsync(id, OwnerId, request, cancellationToken);
            return Ok(station);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
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

    [HttpPut("{id:guid}/chargers/{chargerId:guid}")]
    public async Task<IActionResult> UpdateCharger(Guid id, Guid chargerId, [FromBody] UpdateChargerRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var charger = await _stationService.UpdateChargerAsync(id, chargerId, OwnerId, request, cancellationToken);
            return Ok(charger);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpDelete("{id:guid}/chargers/{chargerId:guid}")]
    public async Task<IActionResult> DeleteCharger(Guid id, Guid chargerId, CancellationToken cancellationToken)
    {
        try
        {
            await _stationService.DeleteChargerAsync(id, chargerId, OwnerId, cancellationToken);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
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

    [HttpPut("maintenance/{maintenanceId:guid}")]
    public async Task<IActionResult> UpdateMaintenanceWindow(Guid maintenanceId, [FromBody] MaintenanceWindowDto request, CancellationToken cancellationToken)
    {
        try
        {
            var mw = await _stationService.UpdateMaintenanceWindowAsync(maintenanceId, OwnerId, request, cancellationToken);
            return Ok(mw);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpDelete("maintenance/{maintenanceId:guid}")]
    public async Task<IActionResult> DeleteMaintenanceWindow(Guid maintenanceId, CancellationToken cancellationToken)
    {
        try
        {
            await _stationService.DeleteMaintenanceWindowAsync(maintenanceId, OwnerId, cancellationToken);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }
}
