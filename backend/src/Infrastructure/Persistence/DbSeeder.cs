using Application.Common.Interfaces;
using Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infrastructure.Persistence;

/// <summary>
/// Ensures the system is usable from an empty database by creating one initial
/// Platform Administrator from configuration. Runs on every startup and is a
/// no-op once an administrator exists.
/// </summary>
public sealed class DbSeeder
{
    private readonly AppDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly SeedOptions _options;
    private readonly ILogger<DbSeeder> _logger;

    public DbSeeder(
        AppDbContext db,
        IPasswordHasher passwordHasher,
        IOptions<SeedOptions> options,
        ILogger<DbSeeder> logger)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.AdminEmail) || string.IsNullOrWhiteSpace(_options.AdminPassword))
        {
            _logger.LogInformation(
                "Seed:AdminEmail / Seed:AdminPassword not configured — skipping initial admin seed.");
            return;
        }

        if (await _db.Users.AnyAsync(u => u.Role == UserRole.Admin, cancellationToken))
        {
            return;
        }

        var email = _options.AdminEmail.Trim().ToLowerInvariant();

        if (await _db.Users.AnyAsync(u => u.Email == email, cancellationToken))
        {
            _logger.LogWarning(
                "Seed admin email is already registered to a non-admin account — skipping seed.");
            return;
        }

        _db.Users.Add(User.Create(
            _options.AdminFullName,
            email,
            _passwordHasher.Hash(_options.AdminPassword),
            UserRole.Admin));

        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Seeded initial administrator account.");
    }
}
