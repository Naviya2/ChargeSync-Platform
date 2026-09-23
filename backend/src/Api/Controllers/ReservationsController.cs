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
[Authorize]
public sealed class ReservationsController : ControllerBase
{
    private readonly IReservationService _reservationService;
    private readonly ICurrentUser _currentUser;

    public ReservationsController(IReservationService reservationService, ICurrentUser currentUser)
    {
        _reservationService = reservationService;
        _currentUser = currentUser;
    }

    private Guid RequesterId => _currentUser.Id ?? Guid.Empty;
    private string RequesterRole => _currentUser.Role?.ToString() ?? string.Empty;

    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.Driver)]
    public async Task<ActionResult<ReservationDto>> Create([FromBody] CreateReservationRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var reservation = await _reservationService.CreateAsync(RequesterId, request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = reservation.Id }, reservation);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("walk-in")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    public async Task<ActionResult<ReservationDto>> CreateWalkIn([FromBody] WalkInRequest request, CancellationToken cancellationToken)
    {
        var reservation = await _reservationService.CreateWalkInAsync(RequesterId, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = reservation.Id }, reservation);
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<ReservationSummaryDto>>> GetList([FromQuery] ReservationFilter filter, CancellationToken cancellationToken)
    {
        var result = await _reservationService.GetListAsync(RequesterId, RequesterRole, filter, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ReservationDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var reservation = await _reservationService.GetByIdAsync(RequesterId, RequesterRole, id, cancellationToken);
        return reservation is null ? NotFound() : Ok(reservation);
    }

    [HttpPut("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, CancellationToken cancellationToken)
    {
        await _reservationService.CancelAsync(RequesterId, id, cancellationToken);
        return NoContent();
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    public async Task<ActionResult<ReservationDto>> Update(Guid id, [FromBody] UpdateReservationRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var reservation = await _reservationService.UpdateAsync(RequesterId, RequesterRole, id, request, cancellationToken);
            return Ok(reservation);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _reservationService.DeleteAsync(RequesterId, RequesterRole, id, cancellationToken);
        return NoContent();
    }

    [HttpPost("staff-checkin")]
    [Authorize(Policy = AuthorizationPolicies.StationOwner)]
    public async Task<ActionResult<ReservationDto>> StaffCheckin([FromBody] StaffCheckinRequest request, CancellationToken cancellationToken)
    {
        var reservation = await _reservationService.StaffCheckinAsync(RequesterId, request, cancellationToken);
        return Ok(reservation);
    }

    [HttpGet("{id:guid}/history")]
    public async Task<ActionResult<IReadOnlyList<ReservationHistoryDto>>> GetHistory(Guid id, CancellationToken cancellationToken)
    {
        var history = await _reservationService.GetHistoryAsync(RequesterId, RequesterRole, id, cancellationToken);
        return Ok(history);
    }
}
