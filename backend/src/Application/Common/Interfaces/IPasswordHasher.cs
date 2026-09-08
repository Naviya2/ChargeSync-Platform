namespace Application.Common.Interfaces;

/// <summary>
/// Hashes and verifies user passwords. Implementations must use a slow,
/// salted algorithm (bcrypt) — SRS §7.2.
/// </summary>
public interface IPasswordHasher
{
    /// <summary>Produces a salted hash for <paramref name="password"/>.</summary>
    string Hash(string password);

    /// <summary>Returns <c>true</c> if <paramref name="password"/> matches <paramref name="passwordHash"/>.</summary>
    bool Verify(string password, string passwordHash);
}
