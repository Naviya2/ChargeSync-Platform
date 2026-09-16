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

    public VehiclesController(IVehicleService vehicleService, ICurrentUser currentUser)
    {
        _vehicleService = vehicleService;
        _currentUser = currentUser;
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
            return Ok(await _vehicleService.FindCompatibleStationsAsync(OwnerId, id, request, cancellationToken));
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