using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Application.Common.Interfaces;
using Domain.Users;

namespace Api.Authentication;

/// <summary>
/// Reads the current caller's identity from the validated JWT on <see cref="HttpContext.User"/>.
/// </summary>
public sealed class CurrentUser : ICurrentUser
{
    private readonly ClaimsPrincipal? _principal;

    public CurrentUser(IHttpContextAccessor httpContextAccessor)
    {
        _principal = httpContextAccessor.HttpContext?.User;
    }

    public Guid? Id =>
        Guid.TryParse(_principal?.FindFirstValue(JwtRegisteredClaimNames.Sub), out var id)
            ? id
            : null;

    public UserRole? Role =>
        Enum.TryParse<UserRole>(_principal?.FindFirstValue(ClaimTypes.Role), ignoreCase: false, out var role)
            ? role
            : null;

    public bool IsAuthenticated => _principal?.Identity?.IsAuthenticated ?? false;

    public bool IsAdmin => Role == UserRole.Admin;
}
