using Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace IntegrationTests;

/// <summary>
/// Boots the real API pipeline (auth, authorization, controllers, exception handling)
/// with the PostgreSQL context swapped for an isolated in-memory database.
/// </summary>
public sealed class ChargeSyncApiFactory : WebApplicationFactory<Program>
{
    public const string AdminEmail = "seed-admin@chargesync.test";
    public const string AdminPassword = "seed-admin-password-123";

    private readonly string _databaseName = $"it-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment(Environments.Development);

        // Settings are visible to Program.cs before it builds the app.
        builder.UseSetting("ConnectionStrings:Postgres", "Host=test;Database=test;Username=test;Password=test");
        builder.UseSetting("Jwt:Issuer", "ChargeSync");
        builder.UseSetting("Jwt:Audience", "ChargeSync");
        builder.UseSetting("Jwt:Key", "integration-tests-signing-key-at-least-32-bytes");
        builder.UseSetting("Jwt:AccessTokenMinutes", "60");
        builder.UseSetting("Seed:AdminEmail", AdminEmail);
        builder.UseSetting("Seed:AdminPassword", AdminPassword);

        builder.ConfigureServices(services =>
        {
            var toRemove = services
                .Where(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>)
                            || d.ServiceType == typeof(DbContextOptions)
                            || d.ServiceType == typeof(AppDbContext))
                .ToList();

            foreach (var descriptor in toRemove)
            {
                services.Remove(descriptor);
            }

            services.AddDbContext<AppDbContext>(options => options.UseInMemoryDatabase(_databaseName));
        });
    }
}
