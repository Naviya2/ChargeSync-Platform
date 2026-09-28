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
    DbSet<Domain.Wallets.WalletTopUp> WalletTopUps { get; }
    DbSet<Domain.Memberships.MembershipPlan> MembershipPlans { get; }
    DbSet<Domain.Memberships.Subscription> Subscriptions { get; }
    DbSet<Domain.Loyalty.LoyaltyAccount> LoyaltyAccounts { get; }
    DbSet<Domain.Loyalty.LoyaltyEntry> LoyaltyEntries { get; }
    DbSet<Domain.Loyalty.Reward> Rewards { get; }
    DbSet<Domain.Loyalty.RewardRedemption> RewardRedemptions { get; }
    DbSet<User> Users { get; }

    DbSet<RefreshToken> RefreshTokens { get; }

    DbSet<Station> Stations { get; }

    DbSet<Charger> Chargers { get; }

    DbSet<OperatingHour> OperatingHours { get; }

    DbSet<MaintenanceWindow> MaintenanceWindows { get; }

    DbSet<Vehicle> Vehicles { get; }

    DbSet<Reservation> Reservations { get; }

    DbSet<ReservationStatusHistory> ReservationStatusHistories { get; }

    DbSet<WaitlistEntry> WaitlistEntries { get; }

    DbSet<ChargingSession> ChargingSessions { get; }

    DbSet<PaymentInvoice> PaymentInvoices { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
