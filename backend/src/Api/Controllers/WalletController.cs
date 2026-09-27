using Application.Common.Interfaces;
using Domain.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

public sealed record TopUpWalletRequest(decimal Amount = 50.00m);
public sealed record WalletBalanceResponse(decimal Balance, string Currency = "USD");

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class WalletController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public WalletController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    private Guid UserId => _currentUser.Id ?? Guid.Empty;

    /// <summary>Gets the current driver's virtual wallet balance.</summary>
    [HttpGet("balance")]
    public async Task<ActionResult<WalletBalanceResponse>> GetBalance(CancellationToken cancellationToken)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == UserId, cancellationToken);
        if (user is null)
            return NotFound(new { message = "User not found." });

        return Ok(new WalletBalanceResponse(user.WalletBalance));
    }

    /// <summary>Credits the driver's virtual wallet with the requested amount.</summary>
    [HttpPost("topup")]
    public async Task<ActionResult<WalletBalanceResponse>> TopUp(
        [FromBody] TopUpWalletRequest? request,
        CancellationToken cancellationToken)
    {
        var amount = request?.Amount ?? 50.00m;
        if (amount <= 0)
            return BadRequest(new { message = "Top-up amount must be greater than $0." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == UserId, cancellationToken);
        if (user is null)
            return NotFound(new { message = "User not found." });

        user.CreditBalance(amount);
        await _db.SaveChangesAsync(cancellationToken);

        return Ok(new WalletBalanceResponse(user.WalletBalance));
    }
}
