namespace Infrastructure.Authentication;

/// <summary>
/// JWT signing/validation configuration, bound from the <c>Jwt</c> configuration section.
/// <see cref="Key"/> is a secret and must be supplied outside source control
/// (user-secrets in development, environment variable in production) — SRS §7.2.
/// </summary>
public sealed class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; init; } = string.Empty;

    public string Audience { get; init; } = string.Empty;

    /// <summary>HMAC-SHA256 signing key. Must be at least 32 bytes.</summary>
    public string Key { get; init; } = string.Empty;

    /// <summary>Access-token lifetime in minutes.</summary>
    public int AccessTokenMinutes { get; init; } = 60;

    /// <summary>Refresh-token lifetime in days.</summary>
    public int RefreshTokenDays { get; init; } = 30;
}
