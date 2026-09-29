using AgentClient;
using AgentClient.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Api.Authentication;
using Application.Common.Interfaces;

namespace Api.Controllers;

[ApiController]
[Route("api/charging-plan")]
[Authorize(Policy = "Driver")]
public class ChargingPlansController : ControllerBase
{
    private readonly IPlanningAgentClient _planningAgent;
    private readonly ICurrentUser _currentUser;
    private readonly ILogger<ChargingPlansController> _logger;
    private readonly IAppDbContext _context;

    public ChargingPlansController(
        IPlanningAgentClient planningAgent,
        ICurrentUser currentUser,
        ILogger<ChargingPlansController> logger,
        IAppDbContext context)
    {
        _planningAgent = planningAgent;
        _currentUser = currentUser;
        _logger = logger;
        _context = context;
    }

    /// <summary>
    /// Generate an AI charging plan based on driver constraints.
    /// </summary>
    [HttpPost("generate")]
    public async Task<IActionResult> GenerateChargingPlan([FromBody] PlanningRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var driverIdStr = _currentUser.Id?.ToString();
            
            // Get Vehicle
            AgentVehicleInput? agentVehicle = null;
            if (Guid.TryParse(driverIdStr, out var dId))
            {
                var vehicle = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.FirstOrDefaultAsync(
                    _context.Vehicles, v => v.OwnerId == dId, cancellationToken);
                if (vehicle != null)
                {
                    agentVehicle = new AgentVehicleInput
                    {
                        VehicleId = vehicle.Id.ToString(),
                        Make = vehicle.Make,
                        Model = vehicle.Model,
                        Connector = vehicle.Connector.ToString(),
                        BatteryCapacityKwh = vehicle.BatteryCapacityKwh,
                        MaxChargeRateKw = vehicle.MaxChargeRateKw,
                        LicensePlate = vehicle.LicensePlate
                    };
                }
            }

            // Get Stations
            var stations = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(
                Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.Include(
                    _context.Stations, s => s.Chargers), cancellationToken);

            var agentStations = stations.Select(s => new AgentStationInput
            {
                StationId = s.Id.ToString(),
                Name = s.Name,
                Address = s.Address,
                Latitude = s.Latitude,
                Longitude = s.Longitude,
                Chargers = s.Chargers.Select(c => new AgentChargerInput
                {
                    ChargerId = c.Id.ToString(),
                    Identifier = c.Identifier,
                    Connector = c.Connector.ToString(),
                    PowerKw = c.PowerKw,
                    Tariff = c.Tariff,
                    Status = c.Status.ToString(),
                    BayLabel = c.BayLabel
                }).ToList()
            }).ToList();

            var secureRequest = request with 
            { 
                DriverId = driverIdStr,
                Vehicle = agentVehicle,
                CandidateStations = agentStations
            };
            
            var response = await _planningAgent.GenerateChargingPlanAsync(secureRequest, cancellationToken);
            
            if (response == null)
            {
                return StatusCode(503, "Agent AI service unavailable.");
            }

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating charging plan.");
            return StatusCode(500, "An error occurred while generating the charging plan.");
        }
    }
}
