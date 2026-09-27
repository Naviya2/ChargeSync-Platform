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
    [RequestSizeLimit(6 * 1024 * 1024)]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<SessionCompletionDto>> Stop(
        Guid id,
        [FromForm] StopSessionForm request,
        CancellationToken cancellationToken)
    {
        MeterPhotoUpload? photo = null;
        if (request.MeterPhoto is not null)
        {
            if (request.MeterPhoto.Length is <= 0 or > 5 * 1024 * 1024)
                return BadRequest(new ProblemDetails { Detail = "Meter photo must be between 1 byte and 5 MB." });
            using var stream = new MemoryStream();
            await request.MeterPhoto.CopyToAsync(stream, cancellationToken);
            var bytes = stream.ToArray();
            var png = bytes.Length >= 8 && bytes.AsSpan(0, 8).SequenceEqual(new byte[] {137,80,78,71,13,10,26,10});
            var jpeg = bytes.Length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
            if (!png && !jpeg)
                return BadRequest(new ProblemDetails { Detail = "Choose a JPEG or PNG meter photo." });
            photo = new MeterPhotoUpload(bytes, png ? "image/png" : "image/jpeg");
        }
        var session = await _sessions.StopAsync(
            RequesterId, RequesterRole, id, request.StaffOverriddenKwh, cancellationToken, photo);
        return Ok(session);
    }

    [HttpGet("{id:guid}/meter-photo")]
    public async Task<IActionResult> GetMeterPhoto(Guid id, CancellationToken cancellationToken)
    {
        var photo = await _sessions.GetMeterPhotoAsync(RequesterId, RequesterRole, id, cancellationToken);
        if (photo is null) return NotFound();
        Response.Headers.CacheControl = "no-store";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        return File(photo.Data, photo.ContentType);
    }
}

public sealed class StopSessionForm
{
    public decimal? StaffOverriddenKwh { get; set; }

    public IFormFile? MeterPhoto { get; set; }
}
