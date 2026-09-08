using System.Security.Cryptography;
using System.Text;
using Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace Infrastructure.Authentication;

/// <summary>
/// Issues 256-bit random refresh tokens (hex-encoded, URL-safe) and hashes them
/// with SHA-256 for storage/lookup.
/// </summary>
public sealed class RefreshTokenIssuer : IRefreshTokenIssuer
{
    private readonly JwtSettings _settings;
    private readonly TimeProvider _timeProvider;

    public RefreshTokenIssuer(IOptions<JwtSettings> settings, TimeProvider timeProvider)
    {
        _settings = settings.Value;
        _timeProvider = timeProvider;
    }

    public RefreshTokenIssue Issue()
    {
        var rawToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var expiresAt = _timeProvider.GetUtcNow().AddDays(_settings.RefreshTokenDays);

        return new RefreshTokenIssue(rawToken, Hash(rawToken), expiresAt);
    }

    public string Hash(string rawToken)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
        return Convert.ToBase64String(hash);
    }
}
