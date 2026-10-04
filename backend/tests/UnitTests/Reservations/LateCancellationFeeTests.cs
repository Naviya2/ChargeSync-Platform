using Application.Common.Exceptions;
using Application.ReservationPlanning;
using Application.ReservationPlanning.Models;
using Application.Sessions;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace UnitTests.Reservations;

public sealed class LateCancellationFeeTests : IDisposable
{
    private readonly DbContextOptions<AppDbContext> _options = new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
    private readonly AppDbContext _db;
    private readonly TestClock _clock = new();
    private readonly DateTimeOffset _start = new(DateTime.UtcNow.Date.AddDays(1).AddHours(4), TimeSpan.Zero);
    private readonly ReservationService _service;

    public LateCancellationFeeTests()
    {
        _db = new(_options);
        _service = new(_db, Mock.Of<ISessionService>(), _clock);
        _clock.Now = _start.AddHours(-1);
    }

    public void Dispose() => _db.Dispose();

    private async Task<(User Driver, User Owner, Reservation Reservation)> Seed()
    {
        var driver = User.Create("Driver", $"{Guid.NewGuid()}@test.com", "hash", UserRole.Driver);
        driver.CreditBalance(1000); // Original 1500 wallet, after a 500 advance.
        var owner = User.Create("Owner", $"{Guid.NewGuid()}@test.com", "hash", UserRole.StationOwner);
        _db.Users.AddRange(driver, owner);
        var station = Station.Create("Station", "Address", 0, 0, owner.Id);
        station.UpdateOperatingHours(Enumerable.Range(0, 7).Select(day =>
            OperatingHour.Create(station.Id, day, true, TimeSpan.Zero, new TimeSpan(23, 59, 59))).ToList());
        _db.Stations.Add(station);
        var charger = Charger.Create(station.Id, "CH1", "Bay", ConnectorType.CCS2, 20, 100);
        _db.Chargers.Add(charger);
        var reservation = Reservation.Create(driver.Id, charger.Id, _start, _start.AddMinutes(30), 500, Guid.NewGuid());
        reservation.ConfirmWithQrCode(Guid.NewGuid().ToString());
        _db.Reservations.Add(reservation);
        await _db.SaveChangesAsync();
        return (driver, owner, reservation);
    }

    private CreateReservationRequest Next(Reservation original, decimal? expectedFee = 500) => new()
    {
        ChargerId = original.ChargerId, VehicleId = Guid.NewGuid(), StartTime = _start,
        EndTime = _start.AddMinutes(30), AdvanceDepositAmount = 500, ExpectedCancellationFees = expectedFee
    };

    [Theory]
    [InlineData(121, 0)]
    [InlineData(120, 0)]
    [InlineData(119, 500)]
    [InlineData(0, 500)]
    [InlineData(-5, 500)]
    public async Task Cancellation_UsesServerTimeAndStrictTwoHourBoundary(int minutesBeforeStart, decimal fee)
    {
        var (driver, _, reservation) = await Seed();
        _clock.Now = _start.AddMinutes(-minutesBeforeStart).ToOffset(TimeSpan.FromHours(5.5));
        await _service.CancelAsync(driver.Id, reservation.Id);
        _db.ChangeTracker.Clear();
        var savedUser = await _db.Users.SingleAsync(u => u.Id == driver.Id);
        var saved = await _db.Reservations.SingleAsync(r => r.Id == reservation.Id);
        Assert.Equal(1500, savedUser.WalletBalance);
        Assert.Equal(fee, savedUser.PendingCancellationFees);
        Assert.Equal(fee, saved.LateCancellationFee);
        Assert.Equal(_clock.Now, saved.CancelledAt);
        Assert.Equal(ReservationStatus.Cancelled, saved.Status);
    }

    [Fact]
    public async Task DuplicateCancellation_CannotRefundOrAssessTwice()
    {
        var (driver, _, reservation) = await Seed();
        await _service.CancelAsync(driver.Id, reservation.Id);
        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CancelAsync(driver.Id, reservation.Id));
        Assert.Equal(1500, driver.WalletBalance);
        Assert.Equal(500, driver.PendingCancellationFees);
        Assert.Single(await _db.ReservationStatusHistories.Where(h => h.ReservationId == reservation.Id).ToListAsync());
    }

    [Fact]
    public async Task NextBooking_CollectsOnceSeparatelyFromAdvance_AndEarlyCancellationRefundsOnlyAdvance()
    {
        var (driver, _, original) = await Seed();
        await _service.CancelAsync(driver.Id, original.Id);
        var quote = await _service.GetBookingChargesAsync(driver.Id);
        Assert.Equal(500, quote.PendingCancellationFees);
        var booking = await _service.CreateAsync(driver.Id, Next(original));
        Assert.Equal(500, booking.AdvanceDepositAmount);
        Assert.Equal(500, booking.CancellationFeesPaid);
        Assert.Equal(500, driver.WalletBalance);
        Assert.Equal(0, driver.PendingCancellationFees);
        _clock.Now = _start.AddHours(-3);
        await _service.CancelAsync(driver.Id, booking.Id);
        Assert.Equal(1000, driver.WalletBalance); // The old fee remains paid.
        Assert.Equal(0, driver.PendingCancellationFees);
        var third = await _service.CreateAsync(driver.Id, Next(original, 0));
        Assert.Equal(0, third.CancellationFeesPaid);
        Assert.Equal(500, driver.WalletBalance);
    }

    [Fact]
    public async Task PaidFee_DoesNotReduceChargingInvoice()
    {
        var (driver, owner, original) = await Seed();
        await _service.CancelAsync(driver.Id, original.Id);
        var booking = await _service.CreateAsync(driver.Id, Next(original));
        var reservation = await _db.Reservations.FindAsync(booking.Id);
        reservation!.CheckIn();
        var session = ChargingSession.Start(reservation, owner.Id, _start);
        session.Stop(_start.AddMinutes(30), 20, null);
        var invoice = PaymentInvoice.Issue(session, driver.Id, 100, reservation.AdvanceDepositAmount);
        Assert.Equal(1000, invoice.GrossAmount);
        Assert.Equal(500, invoice.AdvanceDeducted);
        Assert.Equal(500, invoice.NetAmountDue);
    }

    [Theory]
    [InlineData(null)]
    [InlineData(0)]
    [InlineData(1000)]
    public async Task MissingOrStaleFeeAcknowledgement_DoesNotCharge(int? acknowledged)
    {
        var (driver, _, original) = await Seed();
        await _service.CancelAsync(driver.Id, original.Id);
        await Assert.ThrowsAsync<PaymentConflictException>(() => _service.CreateAsync(driver.Id,
            Next(original, acknowledged.HasValue ? (decimal)acknowledged.Value : null)));
        Assert.Equal(1500, driver.WalletBalance);
        Assert.Equal(500, driver.PendingCancellationFees);
        Assert.Single(await _db.Reservations.ToListAsync());
    }

    [Fact]
    public async Task InsufficientFunds_PreservesFeeAndWallet()
    {
        var (driver, _, original) = await Seed();
        await _service.CancelAsync(driver.Id, original.Id);
        driver.DeductBalance(600);
        await _db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, Next(original)));
        Assert.Equal(900, driver.WalletBalance);
        Assert.Equal(500, driver.PendingCancellationFees);
        Assert.Single(await _db.Reservations.ToListAsync());
    }

    [Fact]
    public async Task UnavailableSlot_DoesNotCollectPendingFee()
    {
        var (driver, _, original) = await Seed();
        await _service.CancelAsync(driver.Id, original.Id);
        var occupied = Reservation.Create(Guid.NewGuid(), original.ChargerId, _start, _start.AddMinutes(30), 0);
        _db.Reservations.Add(occupied);
        await _db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, Next(original)));
        Assert.Equal(1500, driver.WalletBalance);
        Assert.Equal(500, driver.PendingCancellationFees);
    }

    [Fact]
    public async Task MultipleLateCancellations_AccumulateAndCollectTogether()
    {
        var (driver, _, original) = await Seed();
        var second = Reservation.Create(driver.Id, original.ChargerId, _start.AddMinutes(60), _start.AddMinutes(90), 500);
        _db.Reservations.Add(second);
        driver.DeductBalance(500);
        await _db.SaveChangesAsync();
        _clock.Now = _start;
        await _service.CancelAsync(driver.Id, original.Id);
        await _service.CancelAsync(driver.Id, second.Id);
        Assert.Equal(1000, driver.PendingCancellationFees);
        var booking = await _service.CreateAsync(driver.Id, Next(original, 1000));
        Assert.Equal(1000, booking.CancellationFeesPaid);
        Assert.Equal(0, driver.PendingCancellationFees);
        Assert.Equal(0, driver.WalletBalance);
    }

    [Theory]
    [InlineData(UserRole.Admin)]
    [InlineData(UserRole.StationOwner)]
    public async Task StaffCancellation_RefundsWithoutAssessingFee(UserRole role)
    {
        var (driver, owner, reservation) = await Seed();
        owner.ChangeRole(role);
        await _db.SaveChangesAsync();
        await _service.CancelAsync(owner.Id, reservation.Id);
        Assert.Equal(1500, driver.WalletBalance);
        Assert.Equal(0, driver.PendingCancellationFees);
        Assert.Equal(0, reservation.LateCancellationFee);
    }

    [Theory]
    [InlineData(UserRole.Driver)]
    [InlineData(UserRole.StationOwner)]
    [InlineData(UserRole.SupportManager)]
    public async Task OtherUsers_CannotCancelAndChangeDriversMoney(UserRole role)
    {
        var (driver, _, reservation) = await Seed();
        var stranger = User.Create("Other", "other@test.com", "hash", role);
        _db.Users.Add(stranger);
        await _db.SaveChangesAsync();
        await Assert.ThrowsAsync<ForbiddenAccessException>(() => _service.CancelAsync(stranger.Id, reservation.Id));
        Assert.Equal(1000, driver.WalletBalance);
        Assert.Equal(0, driver.PendingCancellationFees);
        Assert.Equal(ReservationStatus.Confirmed, reservation.Status);
    }

    [Fact]
    public async Task StaleFeeBalance_IsRejectedByConcurrencyToken()
    {
        var (driver, _, _) = await Seed();
        using var other = new AppDbContext(_options);
        var stale = await other.Users.SingleAsync(u => u.Id == driver.Id);
        driver.AddCancellationFee(500);
        await _db.SaveChangesAsync();
        stale.AddCancellationFee(500);
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => other.SaveChangesAsync());
    }

    [Fact]
    public async Task StaleReservation_CannotCancelTwiceAtDatabaseLevel()
    {
        var (driver, _, reservation) = await Seed();
        using var other = new AppDbContext(_options);
        var stale = await other.Reservations.SingleAsync(r => r.Id == reservation.Id);
        await _service.CancelAsync(driver.Id, reservation.Id);
        stale.Cancel();
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => other.SaveChangesAsync());
    }

    [Fact]
    public async Task FeeAuditRecord_CannotBeHardDeleted()
    {
        var (driver, owner, reservation) = await Seed();
        await _service.CancelAsync(driver.Id, reservation.Id);
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.DeleteAsync(owner.Id, nameof(UserRole.StationOwner), reservation.Id));
    }

    private sealed class TestClock : TimeProvider
    {
        public DateTimeOffset Now { get; set; }
        public override DateTimeOffset GetUtcNow() => Now.ToUniversalTime();
    }
}
