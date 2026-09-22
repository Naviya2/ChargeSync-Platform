using Api.Common;
using Application.Common.Interfaces;
using Application.ReservationPlanning;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AuthorizationPolicies.Driver)]
public sealed class WaitlistController : ControllerBase
{
    private readonly IWaitlistService _waitlistService;
    private readonly ICurrentUser _currentUser;

    public WaitlistController(IWaitlistService waitlistService, ICurrentUser currentUser)
    {
        _waitlistService = waitlistService;
        _currentUser = currentUser;
    }

    private Guid DriverId => _currentUser.Id ?? Guid.Empty;

    [HttpPost]
    public async Task<ActionResult<WaitlistEntryDto>> Join([FromBody] WaitlistRequest request, CancellationToken cancellationToken)
    {
        var entry = await _waitlistService.JoinAsync(DriverId, request, cancellationToken);
        // Waitlist entries don't have a specific GetById endpoint yet, so we just return Ok
        return Ok(entry);
    }

    [HttpGet("mine")]
    public async Task<ActionResult<IReadOnlyList<WaitlistEntryDto>>> GetMine(CancellationToken cancellationToken)
    {
        var entries = await _waitlistService.GetMineAsync(DriverId, cancellationToken);
        return Ok(entries);
    }
}
