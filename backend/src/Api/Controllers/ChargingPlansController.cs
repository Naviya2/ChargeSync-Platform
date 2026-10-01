using AgentClient;
using AgentClient.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Api.Authentication;
using Application.Common.Interfaces;
using Microsoft.EntityFrameworkCore;
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

            // Get Stations with Chargers, MaintenanceWindows, and OperatingHours
            var stationsQuery = _context.Stations
                .Include(s => s.Chargers)
                    .ThenInclude(c => c.MaintenanceWindows)
                .Include(s => s.OperatingHours);
            
            var stations = await stationsQuery.ToListAsync(cancellationToken);

            var now = DateTimeOffset.UtcNow;
            var upcomingLimit = now.AddMinutes(90);

            var activeReservations = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(
                _context.Reservations.Where(r => 
                    r.Status != Domain.Enums.ReservationStatus.Cancelled && 
                    r.Status != Domain.Enums.ReservationStatus.Completed &&
                    r.StartTime < upcomingLimit && 
                    r.EndTime > now.AddMinutes(-30)
                ), cancellationToken);

            var timeZoneOffset = TimeSpan.FromHours(5.5);
            var nowLocal = now.ToOffset(timeZoneOffset);
            var currentDayOfWeek = (int)nowLocal.DayOfWeek;
            var currentTimeOfDay = nowLocal.TimeOfDay;

            var agentStations = stations
                .Where(s => {
                    var opHour = s.OperatingHours.FirstOrDefault(o => o.DayOfWeek == currentDayOfWeek);
                    if (opHour == null || !opHour.IsEnabled) return false;
                    return currentTimeOfDay >= opHour.OpenTime && currentTimeOfDay <= opHour.CloseTime;
                })
                .Select(s => {
                    double distance = 0.0;
                    if (request.CurrentLat.HasValue && request.CurrentLon.HasValue)
                    {
                        distance = CalculateDistance(request.CurrentLat.Value, request.CurrentLon.Value, s.Latitude, s.Longitude);
                    }
                    
                    return new AgentStationInput
                    {
                        StationId = s.Id.ToString(),
                        Name = s.Name,
                        Address = s.Address,
                        Latitude = s.Latitude,
                        Longitude = s.Longitude,
                        DistanceKm = distance,
                        Chargers = s.Chargers
                            .Where(c => c.Status == Domain.Enums.ChargerStatus.Available && 
                                        !activeReservations.Any(r => r.ChargerId == c.Id) &&
                                        !c.MaintenanceWindows.Any(m => m.StartTime < upcomingLimit && m.EndTime > now))
                            .Select(c => new AgentChargerInput
                            {
                                ChargerId = c.Id.ToString(),
                                Identifier = c.Identifier,
                                Connector = c.Connector.ToString(),
                                PowerKw = c.PowerKw,
                                Tariff = c.Tariff,
                                Status = c.Status.ToString(),
                                BayLabel = c.BayLabel
                            }).ToList()
                    };
                })
                .Where(s => s.Chargers.Any()) // Only include stations with at least one available charger
                .Where(s => request.MaxDistanceKm == null || !request.CurrentLat.HasValue || !request.CurrentLon.HasValue || s.DistanceKm <= request.MaxDistanceKm.Value)
                .ToList();

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

    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371; // Radius of the earth in km
        var dLat = Deg2Rad(lat2 - lat1);
        var dLon = Deg2Rad(lon2 - lon1);
        var a =
            Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
            Math.Cos(Deg2Rad(lat1)) * Math.Cos(Deg2Rad(lat2)) *
            Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c; // Distance in km
    }

    private static double Deg2Rad(double deg)
    {
        return deg * (Math.PI / 180);
    }
}
