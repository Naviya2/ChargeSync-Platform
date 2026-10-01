using Application.Common.Interfaces;
using Application.Support;
using Domain.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/agent-workflows")]
[Authorize(Roles = "Driver,SupportManager,Admin")]
public sealed class AgentWorkflowsController(SupportWorkflowService workflows, ICurrentUser user) : ControllerBase
{
    private Guid Actor => user.Id!.Value;
    private UserRole Role => user.Role!.Value;

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct) => Ok(await workflows.GetAsync(id, Actor, Role, ct));

    [HttpGet("support-ticket/{ticketId:guid}")]
    public async Task<IActionResult> ForTicket(Guid ticketId, CancellationToken ct)
    {
        var result = await workflows.ForTicketAsync(ticketId, Actor, Role, ct);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost("support-ticket/{ticketId:guid}")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Start(Guid ticketId, CancellationToken ct) => Ok(await workflows.StartAsync(ticketId, Actor, Role, ct));

    [HttpPost("{id:guid}/approve")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Approve(Guid id, WorkflowDecisionRequest request, CancellationToken ct) =>
        Ok(await workflows.DecideAsync(id, Actor, Role, request, true, ct));

    [HttpPost("{id:guid}/reject")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Reject(Guid id, WorkflowDecisionRequest request, CancellationToken ct) =>
        Ok(await workflows.DecideAsync(id, Actor, Role, request, false, ct));

    [HttpPost("{id:guid}/revise")]
    [Authorize(Roles = "SupportManager,Admin")]
    public async Task<IActionResult> Revise(Guid id, WorkflowDecisionRequest request, CancellationToken ct) =>
        Ok(await workflows.ReviseAsync(id, Actor, Role, request, ct));
}
