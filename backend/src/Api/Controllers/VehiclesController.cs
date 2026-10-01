using AgentClient;
using AgentClient.Models;
using Api.Compatibility;
using Application.Common.Interfaces;
using Application.Vehicles;
using Application.Vehicles.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Driver")]
public sealed class VehiclesController : ControllerBase
{
    private readonly IVehicleService _vehicleService;
    private readonly ICurrentUser _currentUser;
    private readonly IVehicleAgentClient _vehicleAgentClient;

    public VehiclesController(
        IVehicleService vehicleService,
        ICurrentUser currentUser,
        IVehicleAgentClient vehicleAgentClient)
    {
        _vehicleService = vehicleService;
        _currentUser = currentUser;
        _vehicleAgentClient = vehicleAgentClient;
    }

    private Guid OwnerId => _currentUser.Id ?? Guid.Empty;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<VehicleDto>>> GetMine(CancellationToken cancellationToken) =>
        Ok(await _vehicleService.GetMineAsync(OwnerId, cancellationToken));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<VehicleDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var vehicle = await _vehicleService.GetByIdAsync(OwnerId, id, cancellationToken);
        return vehicle is null ? NotFound() : Ok(vehicle);
    }

    [HttpPost]
    public async Task<ActionResult<VehicleDto>> Create([FromBody] VehicleRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var vehicle = await _vehicleService.CreateAsync(OwnerId, request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = vehicle.Id }, vehicle);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<VehicleDto>> Update(Guid id, [FromBody] VehicleRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var vehicle = await _vehicleService.UpdateAsync(OwnerId, id, request, cancellationToken);
            return vehicle is null ? NotFound() : Ok(vehicle);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken) =>
        await _vehicleService.DeleteAsync(OwnerId, id, cancellationToken) ? NoContent() : NotFound();

    [HttpGet("{id:guid}/compatible-stations")]
    public async Task<ActionResult<IReadOnlyList<CompatibleStationDto>>> FindCompatibleStations(
        Guid id,
        [FromQuery] NearbyStationsRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var local = (await _vehicleService.FindCompatibleStationsAsync(OwnerId, id, request, cancellationToken)).ToList();
            var vehicle = await _vehicleService.GetByIdAsync(OwnerId, id, cancellationToken);
            if (vehicle is null || local.Count == 0)
                return Ok(local);

            var ai = await _vehicleAgentClient.BatchEvaluateCompatibilityAsync(new AgentBatchCompatibilityRequest
            {
                Vehicle = new AgentVehicleInput
                {
                    VehicleId = vehicle.Id.ToString(),
                    Make = vehicle.Make,
                    Model = vehicle.Model,
                    Connector = vehicle.Connector.ToString(),
                    BatteryCapacityKwh = vehicle.BatteryCapacityKwh,
                    MaxChargeRateKw = vehicle.MaxChargeRateKw,
                    LicensePlate = vehicle.LicensePlate
                },
                Stations = local.Select(VehicleCompatibilityMapper.ToAgent).ToList()
            }, cancellationToken);

            if (ai?.Stations is { Count: > 0 })
            {
                var byId = ai.Stations
                    .GroupBy(s => s.StationId, StringComparer.OrdinalIgnoreCase)
                    .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

                foreach (var station in local)
                {
                    if (byId.TryGetValue(station.StationId.ToString(), out var scored))
                        VehicleCompatibilityMapper.Overlay(station, scored);
                }

                local = local
                    .OrderByDescending(s => s.IsCompatible)
                    .ThenByDescending(s => s.CompatibilityScore)
                    .ThenBy(s => s.DistanceKm)
                    .ToList();
            }

            return Ok(local);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}