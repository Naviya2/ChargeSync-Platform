using Application.Common.Interfaces;
using BCryptNet = BCrypt.Net.BCrypt;

namespace Infrastructure.Authentication;

/// <summary>
/// <see cref="IPasswordHasher"/> backed by BCrypt (SRS §7.2).
/// </summary>
public sealed class BcryptPasswordHasher : IPasswordHasher
{
    /// <summary>Cost factor: 2^12 rounds. Raise as hardware improves.</summary>
    private const int WorkFactor = 12;

    public string Hash(string password) =>
        BCryptNet.HashPassword(password, WorkFactor);

    public bool Verify(string password, string passwordHash) =>
        BCryptNet.Verify(password, passwordHash);
}
