using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Infrastructure.Persistence;

/// <summary>
/// Lets the <c>dotnet ef</c> tooling build the context at design time without
/// starting the API host. The connection string is read from the
/// <c>CHARGESYNC_DB</c> environment variable, falling back to a local default
/// used only for generating/applying migrations during development.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString =
            Environment.GetEnvironmentVariable("CHARGESYNC_DB")
            ?? "Host=localhost;Port=5432;Database=chargesync;Username=postgres;Password=postgres";

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName))
            .Options;

        return new AppDbContext(options);
    }
}
