using Application.Common.Interfaces;
using Application.Memberships;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Authorize(Roles = "Driver")]
public sealed class MembershipsController(MemberService members, ICurrentUser user) : ControllerBase
{
    private Guid DriverId => user.Id!.Value;
    [HttpGet("api/membership-plans")]
    public async Task<IActionResult> Plans(CancellationToken ct) => Ok(await members.PlansAsync(ct));
    [HttpGet("api/subscriptions")]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await members.SubscriptionsAsync(DriverId, ct));
    [HttpPost("api/subscriptions")]
    public async Task<IActionResult> Subscribe(SelectPlanRequest request, CancellationToken ct) => Ok(await members.SubscribeAsync(DriverId, request.PlanId, null, ct));
    [HttpPut("api/subscriptions/{id:guid}/change")]
    public async Task<IActionResult> Change(Guid id, SelectPlanRequest request, CancellationToken ct) => Ok(await members.SubscribeAsync(DriverId, request.PlanId, id, ct));
    [HttpDelete("api/subscriptions/{id:guid}")]
    public async Task<IActionResult> Cancel(Guid id, CancellationToken ct) => Ok(await members.CancelAsync(DriverId, id, ct));
}
