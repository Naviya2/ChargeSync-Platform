using Application.Common.Interfaces;
using Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infrastructure.Persistence;

/// <summary>
/// Ensures the system is usable from an empty database by creating one initial
/// Platform Administrator and one Support Manager from configuration.
/// Runs on every startup and is a no-op once the accounts exist.
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
        await SeedAdminAsync(cancellationToken);
        await SeedSupportManagerAsync(cancellationToken);
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    private async Task SeedAdminAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.AdminEmail) || string.IsNullOrWhiteSpace(_options.AdminPassword))
        {
            _logger.LogInformation(
                "Seed:AdminEmail / Seed:AdminPassword not configured — skipping initial admin seed.");
            return;
        }

        var admins = await _db.Users.Where(u => u.Role == UserRole.Admin).ToListAsync(cancellationToken);
        if (admins.Any())
        {
            _logger.LogWarning("Existing admins found: {Admins}", string.Join(", ", admins.Select(a => a.Email)));
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

    // ── Support Manager ───────────────────────────────────────────────────────

    private async Task SeedSupportManagerAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.SupportManagerEmail) || string.IsNullOrWhiteSpace(_options.SupportManagerPassword))
        {
            _logger.LogInformation(
                "Seed:SupportManagerEmail / Seed:SupportManagerPassword not configured — skipping support manager seed.");
            return;
        }

        var email = _options.SupportManagerEmail.Trim().ToLowerInvariant();

        if (await _db.Users.AnyAsync(u => u.Email == email, cancellationToken))
        {
            _logger.LogInformation("Support manager account already exists ({Email}) — skipping seed.", email);
            return;
        }

        _db.Users.Add(User.Create(
            _options.SupportManagerFullName,
            email,
            _passwordHasher.Hash(_options.SupportManagerPassword),
            UserRole.SupportManager));

        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Seeded initial support manager account ({Email}).", email);
    }
}
