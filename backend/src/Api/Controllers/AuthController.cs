using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Application.Authentication;
using Application.Authentication.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService) => _authService = authService;

    /// <summary>Registers a new Driver or StationOwner account and returns a signed-in session.</summary>
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<AuthResult>> Register(RegisterRequest request, CancellationToken cancellationToken)
        => Ok(await _authService.RegisterAsync(request, cancellationToken));

    /// <summary>Authenticates by email and password.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResult>> Login(LoginRequest request, CancellationToken cancellationToken)
        => Ok(await _authService.LoginAsync(request, cancellationToken));

    /// <summary>Exchanges a refresh token for a new session. The old refresh token is rotated out.</summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResult>> Refresh(RefreshRequest request, CancellationToken cancellationToken)
        => Ok(await _authService.RefreshAsync(request, cancellationToken));

    /// <summary>Revokes a refresh token (logout).</summary>
    [HttpPost("logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout(RefreshRequest request, CancellationToken cancellationToken)
    {
        await _authService.RevokeAsync(request, cancellationToken);
        return NoContent();
    }

    /// <summary>Returns the identity carried by the current bearer token.</summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(AuthUser), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult<AuthUser> Me()
    {
        if (!Guid.TryParse(User.FindFirstValue(JwtRegisteredClaimNames.Sub), out var userId))
        {
            return Unauthorized();
        }

        return Ok(new AuthUser(
            userId,
            User.FindFirstValue(JwtRegisteredClaimNames.Name) ?? string.Empty,
            User.FindFirstValue(JwtRegisteredClaimNames.Email) ?? string.Empty,
            User.FindFirstValue(ClaimTypes.Role) ?? string.Empty));
    }
}
