using Application.Authentication.Models;

namespace Application.Authentication;

public interface IAuthService
{
    /// <summary>Registers a new self-service account and returns a signed-in session.</summary>
    Task<AuthResult> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);

    /// <summary>Authenticates an existing account by email and password.</summary>
    Task<AuthResult> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);

    /// <summary>Exchanges a valid refresh token for a new session, rotating the refresh token.</summary>
    Task<AuthResult> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken = default);

    /// <summary>Revokes a refresh token (logout). Idempotent.</summary>
    Task RevokeAsync(RefreshRequest request, CancellationToken cancellationToken = default);
}
