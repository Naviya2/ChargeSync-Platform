using Domain.Common;

namespace Domain.Users;

/// <summary>
/// A long-lived token that lets a client obtain new access tokens without
/// re-entering credentials. Only a hash of the token value is stored; tokens are
/// single-use and rotated on every refresh.
/// </summary>
public class RefreshToken : AuditableEntity
{
    private RefreshToken()
    {
        // Required by EF Core.
    }

    private RefreshToken(User user, string tokenHash, DateTimeOffset expiresAt)
    {
        User = user;
        UserId = user.Id;
        TokenHash = tokenHash;
        ExpiresAt = expiresAt;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public User User { get; private set; } = null!;

    /// <summary>SHA-256 hash of the raw token value. The raw value is never persisted.</summary>
    public string TokenHash { get; private set; } = null!;

    public DateTimeOffset ExpiresAt { get; private set; }

    public DateTimeOffset? RevokedAt { get; private set; }

    /// <summary>Hash of the token that superseded this one (rotation audit trail).</summary>
    public string? ReplacedByTokenHash { get; private set; }

    /// <summary>
    /// Issues a token for <paramref name="user"/>. The navigation is set (not just the id)
    /// so EF Core propagates a database-generated user id and orders the inserts correctly.
    /// </summary>
    public static RefreshToken Issue(User user, string tokenHash, DateTimeOffset expiresAt) =>
        new(user, tokenHash, expiresAt);

    public bool IsActiveAt(DateTimeOffset utcNow) => RevokedAt is null && ExpiresAt > utcNow;

    public void Revoke(DateTimeOffset utcNow, string? replacedByTokenHash = null)
    {
        RevokedAt ??= utcNow;
        ReplacedByTokenHash ??= replacedByTokenHash;
    }
}
