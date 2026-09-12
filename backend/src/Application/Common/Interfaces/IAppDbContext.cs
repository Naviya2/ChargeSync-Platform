using Domain.Users;
using Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Application.Common.Interfaces;

/// <summary>
/// Abstraction over the EF Core context so application code depends on the
/// persistence contract, not the Infrastructure implementation.
/// </summary>
public interface IAppDbContext
{
    DbSet<User> Users { get; }

    DbSet<RefreshToken> RefreshTokens { get; }

    DbSet<Station> Stations { get; }

    DbSet<Charger> Chargers { get; }

    DbSet<OperatingHour> OperatingHours { get; }

    DbSet<MaintenanceWindow> MaintenanceWindows { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
