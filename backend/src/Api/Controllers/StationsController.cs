using AgentClient.Models;
using Api.Compatibility;
using Application.Common.Interfaces;
using Application.Stations;
using Application.Stations.Models;
using Application.Vehicles;
using Application.Vehicles.Models;
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
    [AllowAnonymous] // class-level StationOwner/Admin would otherwise 403 drivers
    public async Task<IActionResult> GetCompatibility(
        Guid id,
        [FromQuery] Guid? vehicleId,
        [FromQuery] double? latitude,
        [FromQuery] double? longitude,
        [FromServices] AgentClient.IVehicleAgentClient agentClient,
        [FromServices] IAppDbContext db,
        [FromServices] IVehicleService vehicleService,
        CancellationToken cancellationToken)
    {
        if (!_currentUser.IsAuthenticated || _currentUser.Id is null)
            return Unauthorized();

        var station = await db.Stations
            .Include(s => s.Chargers)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

        if (station == null) return NotFound();

        var ownerId = _currentUser.Id.Value;
        var isAdmin = _currentUser.IsAdmin;

        Domain.Entities.Vehicle? vehicle = null;
        if (vehicleId.HasValue && vehicleId.Value != Guid.Empty)
        {
            vehicle = await db.Vehicles.AsNoTracking()
                .FirstOrDefaultAsync(
                    v => v.Id == vehicleId.Value && (v.OwnerId == ownerId || isAdmin),
                    cancellationToken);
        }
        else
        {
            vehicle = await db.Vehicles.AsNoTracking()
                .Where(v => v.OwnerId == ownerId)
                .OrderBy(v => v.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);
        }

        if (vehicle == null)
            return BadRequest(new { message = "Register a vehicle before checking compatibility." });

        var originLat = latitude ?? station.Latitude;
        var originLng = longitude ?? station.Longitude;

        var nearby = await vehicleService.FindCompatibleStationsAsync(
            vehicle.OwnerId,
            vehicle.Id,
            new NearbyStationsRequest
            {
                Latitude = originLat,
                Longitude = originLng,
                RadiusKm = 25
            },
            cancellationToken);

        var candidateStations = (await db.Stations
                .Include(s => s.Chargers)
                .AsNoTracking()
                .Where(s => s.Status == Domain.Enums.StationStatus.Active && s.Id != station.Id)
                .ToListAsync(cancellationToken))
            .Select(s => (Station: s, Distance: VehicleCompatibilityMapper.DistanceKm(
                originLat, originLng, s.Latitude, s.Longitude)))
            .Where(x => x.Distance <= 25)
            .OrderBy(x => x.Distance)
            .Take(8)
            .ToList();

        var aiResult = await agentClient.EvaluateCompatibilityAsync(new AgentCompatibilityRequest
        {
            Vehicle = VehicleCompatibilityMapper.ToAgent(vehicle),
            TargetStation = VehicleCompatibilityMapper.ToAgent(
                station,
                VehicleCompatibilityMapper.DistanceKm(originLat, originLng, station.Latitude, station.Longitude)),
            CandidateAlternativeStations = candidateStations
                .Select(x => VehicleCompatibilityMapper.ToAgent(x.Station, x.Distance))
                .ToList()
        }, cancellationToken);

        if (aiResult != null)
            return Ok(VehicleCompatibilityMapper.ToDto(station.Id, aiResult));

        var local = nearby.FirstOrDefault(s => s.StationId == station.Id);
        if (local == null)
        {
            return Ok(new CompatibilityEvaluationDto
            {
                StationId = station.Id,
                IsCompatible = false,
                CompatibilityScore = 0,
                AiInsight = "Compatibility service is unavailable and this station is outside the local search set.",
                SuggestedAlternatives = nearby.Where(s => s.IsCompatible).Take(3).Select(s => new AlternativeStationDto
                {
                    StationId = s.StationId,
                    Name = s.Name,
                    Address = s.Address,
                    DistanceKm = s.DistanceKm,
                    CompatibilityScore = s.CompatibilityScore,
                    Reason = "Nearby compatible station"
                }).ToList()
            });
        }

        return Ok(VehicleCompatibilityMapper.FromLocal(local, nearby));
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
