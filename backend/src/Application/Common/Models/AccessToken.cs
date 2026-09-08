namespace Application.Common.Models;

/// <summary>
/// A signed JWT access token and the instant it expires (UTC).
/// </summary>
public sealed record AccessToken(string Value, DateTimeOffset ExpiresAtUtc);
