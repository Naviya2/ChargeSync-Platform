namespace Application.Authentication.Models;

/// <summary>Successful authentication response: an access token, a refresh token, and the caller's identity.</summary>
public sealed record AuthResult(
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAtUtc,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAtUtc,
    AuthUser User);

/// <summary>Minimal user projection returned to clients (never includes the password hash).</summary>
public sealed record AuthUser(Guid Id, string FullName, string Email, string Role);
