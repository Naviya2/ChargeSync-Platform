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

    public ChargingPlansController(
        IPlanningAgentClient planningAgent,
        ICurrentUser currentUser,
        ILogger<ChargingPlansController> logger)
    {
        _planningAgent = planningAgent;
        _currentUser = currentUser;
        _logger = logger;
    }

    /// <summary>
    /// Generate an AI charging plan based on driver constraints.
    /// </summary>
    [HttpPost("generate")]
    public async Task<IActionResult> GenerateChargingPlan([FromBody] PlanningRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var driverId = _currentUser.Id?.ToString();
            
            // Override the driver_id with the authenticated user to ensure security
            var secureRequest = request with { DriverId = driverId };
            
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
