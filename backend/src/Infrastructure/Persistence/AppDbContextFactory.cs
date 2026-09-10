using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Infrastructure.Persistence;

/// <summary>
/// Lets the <c>dotnet ef</c> tooling build the context at design time without
/// starting the API host. The connection string is resolved in this priority order:
/// 1. <c>CHARGESYNC_DB</c> environment variable.
/// 2. <c>appsettings.Development.json</c> ConnectionStrings:Postgres (local dev).
/// 3. Hard-coded local fallback (last resort, for CI with a local Postgres).
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString =
            Environment.GetEnvironmentVariable("CHARGESYNC_DB")
            ?? BuildFromConfig()
            ?? "Host=localhost;Port=5432;Database=chargesync;Username=postgres;Password=postgres";

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName))
            .Options;

        return new AppDbContext(options);
    }

    private static string? BuildFromConfig()
    {
        // The EF tool runs from the API's bin/Debug/net8.0 folder.
        // We search the Api project directory for appsettings files.
        var searchDir = AppContext.BaseDirectory;

        var config = new ConfigurationBuilder()
            .SetBasePath(searchDir)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        return config.GetConnectionString("Postgres");
    }
}

