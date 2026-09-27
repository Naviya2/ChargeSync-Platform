using Api.Common;
using Application.Common.Interfaces;
using Application.Sessions;
using Application.Sessions.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class SessionsController : ControllerBase
{
    private readonly ISessionService _sessions;
    private readonly ICurrentUser _currentUser;

    public SessionsController(ISessionService sessions, ICurrentUser currentUser)
    {
        _sessions = sessions;
        _currentUser = currentUser;
    }

    private Guid RequesterId => _currentUser.Id ?? Guid.Empty;
    private string RequesterRole => _currentUser.Role?.ToString() ?? string.Empty;

    [HttpPost("start")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    public async Task<ActionResult<ChargingSessionDto>> Start(
        [FromBody] StartSessionRequest request,
        CancellationToken cancellationToken)
    {
        var session = await _sessions.StartAsync(
            RequesterId, RequesterRole, request.ReservationId, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = session.Id }, session);
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ChargingSessionDto>>> GetList(
        [FromQuery] SessionFilter filter,
        CancellationToken cancellationToken)
    {
        var sessions = await _sessions.GetListAsync(RequesterId, RequesterRole, filter, cancellationToken);
        return Ok(sessions);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ChargingSessionDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var session = await _sessions.GetByIdAsync(RequesterId, RequesterRole, id, cancellationToken);
        return session is null ? NotFound() : Ok(session);
    }

    [HttpPut("{id:guid}/stop")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ChargingSessionDto>> Stop(
        Guid id,
        [FromForm] StopSessionForm request,
        CancellationToken cancellationToken)
    {
        var session = await _sessions.StopAsync(
            RequesterId, RequesterRole, id, request.StaffOverriddenKwh, cancellationToken);
        return Ok(session);
    }
}

public sealed class StopSessionForm
{
    public decimal? StaffOverriddenKwh { get; set; }

    // Accepted for compatibility with the staff mobile workflow. Persistent photo
    // storage will be added with invoice evidence in the payment milestone.
    public IFormFile? MeterPhoto { get; set; }
}
