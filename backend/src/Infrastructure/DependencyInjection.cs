using Application.Common.Interfaces;
using Infrastructure.Authentication;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Infrastructure;

public static class DependencyInjection
{
    /// <summary>
    /// Registers Infrastructure services: the PostgreSQL context, password hashing,
    /// JWT/refresh token generation and database seeding. Expects a connection string
    /// named <c>Postgres</c> and a <c>Jwt</c> configuration section (secrets supplied
    /// outside source control).
    /// </summary>
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Postgres")
            ?? throw new InvalidOperationException(
                "Connection string 'Postgres' is not configured.");

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.SectionName));
        services.Configure<SeedOptions>(configuration.GetSection(SeedOptions.SectionName));

        services.AddSingleton(TimeProvider.System);
        services.AddScoped<IPasswordHasher, BcryptPasswordHasher>();
        services.AddScoped<IJwtTokenGenerator, JwtTokenGenerator>();
        services.AddScoped<IRefreshTokenIssuer, RefreshTokenIssuer>();
        services.AddScoped<DbSeeder>();

        // Register OpenRouteService HTTP Client
        services.AddHttpClient<Application.ReservationPlanning.Services.IRoutingService, Infrastructure.ExternalServices.OpenRouteService>(client =>
        {
            client.BaseAddress = new Uri("https://api.heigit.org/");
            var apiKey = configuration["OpenRouteService:ApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
            {
                client.DefaultRequestHeaders.Add("Authorization", apiKey);
            }
        });

        return services;
    }

    /// <summary>
    /// Applies pending migrations (relational providers only) and runs the seeder.
    /// Call once during application startup.
    /// </summary>
    public static async Task InitialiseDatabaseAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();

        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        if (db.Database.IsRelational())
        {
            await db.Database.MigrateAsync();
        }

        await scope.ServiceProvider.GetRequiredService<DbSeeder>().SeedAsync();
    }
}
