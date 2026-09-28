using Application.Common.Interfaces;
using Application.Memberships;
using Domain.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/loyalty")]
[Authorize]
public sealed class LoyaltyController(MemberService members, ICurrentUser user) : ControllerBase
{
    private Guid UserId => user.Id!.Value;
    [HttpGet("me")]
    [Authorize(Roles = "Driver")]
    public async Task<IActionResult> Me(CancellationToken ct) => Ok(await members.BalanceAsync(UserId, ct));
    [HttpGet("{userId:guid}")]
    [HttpGet("balance/{userId:guid}")]
    public async Task<IActionResult> Balance(Guid userId, CancellationToken ct)
    {
        if (user.Role != UserRole.Admin && (user.Role != UserRole.Driver || userId != UserId)) return Forbid();
        return Ok(await members.BalanceAsync(userId, ct));
    }
    [HttpGet("history")]
    [Authorize(Roles = "Driver")]
    public async Task<IActionResult> History(CancellationToken ct) => Ok(await members.HistoryAsync(UserId, ct));
    [HttpGet("rewards")]
    public async Task<IActionResult> Rewards(CancellationToken ct) => Ok(await members.RewardsAsync(ct));
    [HttpPost("redeem")]
    [Authorize(Roles = "Driver")]
    public async Task<IActionResult> Redeem(RedeemRequest request, CancellationToken ct) => Ok(await members.RedeemAsync(UserId, request, ct));
    [HttpGet("redemptions")]
    [Authorize(Roles = "Driver,Admin")]
    public async Task<IActionResult> Redemptions(CancellationToken ct) => Ok(await members.RedemptionsAsync(user.Role == UserRole.Admin ? null : UserId, ct));
    [HttpPost("redemptions/{id:guid}/review")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Review(Guid id, ReviewRedemptionRequest request, CancellationToken ct) => Ok(await members.ReviewAsync(UserId, id, request.Approve, ct));
}
