using System.Reflection;
using Application.Common.Interfaces;
using Domain.Common;
using Domain.Users;
using Domain.Entities;

using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Persistence;

/// <summary>
/// The application's EF Core context (PostgreSQL via Npgsql).
/// Entity mappings live in <see cref="Configurations"/>; timestamp columns are
/// maintained centrally in <see cref="SaveChangesAsync"/>.
/// </summary>
public class AppDbContext : DbContext, IAppDbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();

    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    public DbSet<Station> Stations => Set<Station>();

    public DbSet<Charger> Chargers => Set<Charger>();

    public DbSet<OperatingHour> OperatingHours => Set<OperatingHour>();

    public DbSet<MaintenanceWindow> MaintenanceWindows => Set<MaintenanceWindow>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        TouchTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        TouchTimestamps();
        return base.SaveChanges();
    }

    /// <summary>
    /// Bumps <c>UpdatedAt</c> on modified auditable entities. <c>CreatedAt</c> and the
    /// initial <c>UpdatedAt</c> are set by the database default (<c>now()</c>) on insert.
    /// </summary>
    private void TouchTimestamps()
    {
        var now = DateTimeOffset.UtcNow;

        foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
        {
            if (entry.State == EntityState.Modified)
            {
                entry.Property(e => e.UpdatedAt).CurrentValue = now;
            }
        }
    }
}
