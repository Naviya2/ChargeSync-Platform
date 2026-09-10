namespace Application.Common.Interfaces;

/// <summary>A freshly minted refresh token: the raw value for the client, its hash for storage, and its expiry.</summary>
public sealed record RefreshTokenIssue(string RawToken, string TokenHash, DateTimeOffset ExpiresAtUtc);

/// <summary>
/// Creates cryptographically random refresh tokens and hashes token values for lookup.
/// The configured lifetime lives with the implementation (Infrastructure).
/// </summary>
public interface IRefreshTokenIssuer
{
    RefreshTokenIssue Issue();

    string Hash(string rawToken);
}
