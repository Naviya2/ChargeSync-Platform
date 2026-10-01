using Application.Memberships;
using Domain.Entities;
using Domain.Enums;
using Domain.Loyalty;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace UnitTests.Memberships;

public sealed class MemberServiceTests : IDisposable
{
    private readonly AppDbContext db;
    private readonly MemberService service;
    private readonly CancellationToken ct = CancellationToken.None;
    public MemberServiceTests()
    {
        db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        db.Database.EnsureCreated(); service = new MemberService(db);
    }
    public void Dispose() => db.Dispose();
    private async Task<User> Driver(decimal balance = 10000)
    {
        var user = User.Create("Driver", Guid.NewGuid() + "@test.com", "hashed", UserRole.Driver);
        user.CreditBalance(balance); db.Users.Add(user); await db.SaveChangesAsync(); return user;
    }

    [Fact]
    public async Task Subscription_ChargesWallet_ChangesWithCredit_CancelsWithoutLosingPaidBenefits()
    {
        var driver = await Driver(); var plans = await service.PlansAsync(ct);
        var sub = await service.SubscribeAsync(driver.Id, plans[0].Id, null, ct);
        Assert.Equal(9500m, driver.WalletBalance);
        Assert.Equal(5m, await service.DiscountAsync(driver.Id, ct));
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SubscribeAsync(driver.Id, plans[0].Id, null, ct));
        var changed = await service.SubscribeAsync(driver.Id, plans[1].Id, sub.Id, ct);
        Assert.InRange(changed.CreditApplied, 499.9m, 500m);
        Assert.Equal(9500m + changed.CreditApplied - 1000m, driver.WalletBalance);
        Assert.Equal(2, (await service.SubscriptionsAsync(driver.Id, ct)).Count);
        await service.CancelAsync(driver.Id, sub.Id, ct);
        Assert.Equal(10m, await service.DiscountAsync(driver.Id, ct));
        Assert.Equal("Cancelled", (await service.SubscriptionsAsync(driver.Id, ct)).First().Status);
        var row = await db.Subscriptions.FindAsync(sub.Id); row!.EndDate = DateTimeOffset.UtcNow.AddSeconds(-1);
        await db.SaveChangesAsync();
        Assert.Equal(0m, await service.DiscountAsync(driver.Id, ct));
    }

    [Fact]
    public async Task InsufficientWallet_DoesNotCreateSubscription()
    {
        var user = await Driver(10);
        var planId = (await service.PlansAsync(ct))[0].Id;
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SubscribeAsync(user.Id, planId, null, ct));
        Assert.Empty(await db.Subscriptions.ToListAsync()); Assert.Equal(10m, user.WalletBalance);
    }

    [Fact]
    public async Task PaidInvoice_AwardsOnce_DepositCoveredInvoiceAlsoQualifies()
    {
        var user = await Driver();
        var reservation = Reservation.Create(user.Id, Guid.NewGuid(), DateTimeOffset.UtcNow.AddMinutes(1), DateTimeOffset.UtcNow.AddHours(1), 1000);
        reservation.ConfirmWithQrCode("qr"); reservation.CheckIn();
        var session = ChargingSession.Start(reservation, Guid.NewGuid(), DateTimeOffset.UtcNow.AddHours(-1));
        session.Stop(DateTimeOffset.UtcNow, 50, 10);
        var invoice = PaymentInvoice.Issue(session, user.Id, 100, 1000);
        db.Reservations.Add(reservation); db.ChargingSessions.Add(session); db.PaymentInvoices.Add(invoice);
        await service.AwardAsync(invoice, ct); await db.SaveChangesAsync();
        await service.AwardAsync(invoice, ct); await db.SaveChangesAsync();
        Assert.Equal(10, (await service.BalanceAsync(user.Id, ct)).PointsBalance);
        Assert.Single(await db.LoyaltyEntries.ToListAsync());
    }

    [Fact]
    public async Task Redemption_UsesServerCost_Idempotent_RejectsInsufficientBalance()
    {
        var user = await Driver(0); var account = new LoyaltyAccount { DriverId = user.Id }; account.Earn(150);
        db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        var reward = (await service.RewardsAsync(ct))[0]; var request = new RedeemRequest(reward.Id, Guid.NewGuid());
        var first = await service.RedeemAsync(user.Id, request, ct);
        var retry = await service.RedeemAsync(user.Id, request, ct);
        Assert.Equal(first.Id, retry.Id); Assert.Equal(100m, user.WalletBalance); Assert.Equal(50, account.PointsBalance);
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.RedeemAsync(user.Id, new(reward.Id, Guid.NewGuid()), ct));
        Assert.Equal(50, account.PointsBalance);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task HighValueReward_HoldsPointsUntilReview_ReviewOnlyOnce(bool approve)
    {
        var user = await Driver(0); var account = new LoyaltyAccount { DriverId = user.Id }; account.Earn(7000);
        db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        var reward = (await service.RewardsAsync(ct))[1];
        var r = await service.RedeemAsync(user.Id, new(reward.Id, Guid.NewGuid()), ct);
        Assert.Equal("Pending", r.Status); Assert.Equal(1000, account.PointsBalance); Assert.Equal(0m, user.WalletBalance);
        var admin = User.Create("Admin", $"{Guid.NewGuid()}@test.com", "hashed", UserRole.Admin);
        db.Users.Add(admin); await db.SaveChangesAsync();
        await service.ReviewAsync(admin.Id, r.Id, approve, ct);
        Assert.Equal(approve ? 6000m : 0m, user.WalletBalance);
        Assert.Equal(approve ? 1000 : 7000, account.PointsBalance);
        Assert.Equal(7000, account.LifetimePoints); Assert.Equal("Gold", account.Tier);
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.ReviewAsync(admin.Id, r.Id, approve, ct));
    }

    [Fact]
    public async Task StaleLoyaltyAccount_CannotOverwriteNewerBalance()
    {
        var user = await Driver(); var account = new LoyaltyAccount { DriverId = user.Id }; account.Earn(1000);
        db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        var original = db.Entry(account).Property(a => a.Version).OriginalValue;
        account.Spend(600); await db.SaveChangesAsync();
        db.Entry(account).Property(a => a.Version).OriginalValue = original;
        account.Spend(100);
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => db.SaveChangesAsync());
    }

    [Fact]
    public async Task DriverCannotApproveRewardThroughApplicationService()
    {
        var driver = await Driver(0);
        var account = new LoyaltyAccount { DriverId = driver.Id }; account.Earn(6000);
        db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        var reward = (await service.RewardsAsync(ct))[1];
        var redemption = await service.RedeemAsync(driver.Id, new(reward.Id, Guid.NewGuid()), ct);
        await Assert.ThrowsAsync<Application.Common.Exceptions.ForbiddenAccessException>(
            () => service.ReviewAsync(driver.Id, redemption.Id, true, ct));
        Assert.Equal("Pending", redemption.Status);
        Assert.Equal(0, driver.WalletBalance);
    }

    [Theory]
    [InlineData(PaymentMethod.Cash)]
    [InlineData(PaymentMethod.Wallet)]
    public async Task Settlement_AwardsDiscountedPointsOnce(PaymentMethod method)
    {
        var user = await Driver();
        var station = Station.Create("Test", "Test", 6.9, 79.8, user.Id); db.Stations.Add(station); await db.SaveChangesAsync();
        var charger = Charger.Create(station.Id, "CH-TEST", "Bay", ConnectorType.CCS2, 50, 100); db.Chargers.Add(charger); await db.SaveChangesAsync();
        var reservation = Reservation.Create(user.Id, charger.Id, DateTimeOffset.UtcNow.AddMinutes(1), DateTimeOffset.UtcNow.AddHours(1), 0);
        reservation.ConfirmWithQrCode("qr"); reservation.CheckIn();
        var session = ChargingSession.Start(reservation, user.Id, DateTimeOffset.UtcNow.AddHours(-1)); session.Stop(DateTimeOffset.UtcNow, 50, 10);
        var invoice = PaymentInvoice.Issue(session, user.Id, 100, 0, 10);
        db.Reservations.Add(reservation); db.ChargingSessions.Add(session); db.PaymentInvoices.Add(invoice); await db.SaveChangesAsync();
        Assert.Empty(await db.LoyaltyEntries.ToListAsync());
        var payments = new Application.Payments.PaymentService(db, service);
        await payments.SettleAsync(user.Id, method == PaymentMethod.Wallet ? "Driver" : "Admin", invoice.Id, new() { PaymentMethod = method }, ct);
        Assert.Equal(9, (await service.BalanceAsync(user.Id, ct)).PointsBalance);
        await Assert.ThrowsAsync<InvalidOperationException>(() => payments.SettleAsync(user.Id, method == PaymentMethod.Wallet ? "Driver" : "Admin", invoice.Id, new() { PaymentMethod = method }, ct));
        Assert.Single(await db.LoyaltyEntries.ToListAsync());
        // Fresh reads represent the next request, rather than unsaved tracked objects.
        db.ChangeTracker.Clear();
        Assert.Equal(method == PaymentMethod.Wallet ? 9100m : 10000m, (await db.Users.FindAsync(user.Id))!.WalletBalance);
    }
}
