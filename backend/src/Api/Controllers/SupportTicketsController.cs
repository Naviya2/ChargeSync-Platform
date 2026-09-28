using Application.Common.Interfaces;
using Application.Support;
using Domain.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/support-tickets")]
[Authorize(Roles = "Driver,SupportManager,Admin")]
public sealed class SupportTicketsController(SupportService support, ICurrentUser current) : ControllerBase
{
    private Guid UserId => current.Id!.Value;
    private UserRole Role => current.Role!.Value;

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? status, CancellationToken ct) => Ok(await support.ListAsync(UserId, Role, status, ct));
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct) => Ok(await support.GetAsync(UserId, Role, id, ct));
    [HttpPost]
    [Authorize(Roles = "Driver")]
    public async Task<IActionResult> Create(CreateTicketRequest request, CancellationToken ct) => Ok(await support.CreateAsync(UserId, request, ct));
    [HttpPost("{id:guid}/messages")]
    public async Task<IActionResult> Message(Guid id, AddMessageRequest request, CancellationToken ct) => Ok(await support.AddMessageAsync(UserId, Role, id, request.Body, ct));
    [HttpPut("{id:guid}/status")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Status(Guid id, UpdateTicketStatusRequest request, CancellationToken ct) => Ok(await support.SetStatusAsync(UserId, Role, id, request.Status, ct));
    [HttpPut("{id:guid}/assignee")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Assign(Guid id, AssignTicketRequest request, CancellationToken ct) => Ok(await support.AssignAsync(UserId, Role, id, request.AssigneeId, ct));
    [HttpPost("{id:guid}/refund-review")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Refund(Guid id, ReviewRefundRequest request, CancellationToken ct) => Ok(await support.ReviewRefundAsync(UserId, Role, id, request, ct));
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Driver")]
    public async Task<IActionResult> Withdraw(Guid id, CancellationToken ct) => Ok(await support.WithdrawAsync(UserId, id, ct));
}
