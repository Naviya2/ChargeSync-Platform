using Application.Common.Exceptions;
using Application.ReservationPlanning;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Application.Sessions;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace UnitTests.ReservationPlanning.Tests;

public sealed class ReservationServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly Mock<ISessionService> _sessionsMock;
    private readonly ReservationService _service;

    public ReservationServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        _sessionsMock = new Mock<ISessionService>();
        _service = new ReservationService(_db, _sessionsMock.Object);
    }

    public void Dispose() => _db.Dispose();

    private async Task<User> CreateDriverAsync(decimal balance = 1000m)
    {
        var driver = User.Create("Driver", $"driver_{Guid.NewGuid():N}@test.com", "hash", UserRole.Driver);
        driver.CreditBalance(balance);
        _db.Users.Add(driver);
        await _db.SaveChangesAsync();
        return driver;
    }

    private async Task<User> CreateAdminAsync()
    {
        var admin = User.Create("Admin", $"admin_{Guid.NewGuid():N}@test.com", "hash", UserRole.Admin);
        _db.Users.Add(admin);
        await _db.SaveChangesAsync();
        return admin;
    }

    private async Task<Charger> CreateChargerAsync()
    {
        var owner = User.Create("Owner", $"owner_{Guid.NewGuid():N}@test.com", "hash", UserRole.StationOwner);
        _db.Users.Add(owner);
        var station = Station.Create("Station", "Address", 0, 0, owner.Id);
        station.UpdateOperatingHours(Enumerable.Range(0, 7)
            .Select(day => OperatingHour.Create(station.Id, day, true, TimeSpan.Zero, new TimeSpan(23, 59, 59))).ToList());
        _db.Stations.Add(station);
        var charger = Charger.Create(station.Id, "CH-01", "Bay 1", ConnectorType.CCS2, 50, 40);
        _db.Chargers.Add(charger);
        await _db.SaveChangesAsync();
        return charger;
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesReservationAndDeductsBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow.AddHours(1),
            EndTime = DateTimeOffset.UtcNow.AddHours(2),
            AdvanceDepositAmount = 100m
        };

        var result = await _service.CreateAsync(driver.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.Confirmed, result.Status);
        
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(400m, updatedDriver!.WalletBalance);

        var histories = await _db.ReservationStatusHistories.Where(h => h.ReservationId == result.Id).ToListAsync();
        Assert.Contains(histories, h => h.NewStatus == ReservationStatus.Confirmed);
    }

    [Fact]
    public async Task CreateAsync_InsufficientBalance_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(50m);
        var charger = await CreateChargerAsync();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow.AddHours(1),
            EndTime = DateTimeOffset.UtcNow.AddHours(2),
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request));
    }

    [Fact]
    public async Task CreateAsync_OverlappingReservation_ThrowsInvalidOperationException()
    {
        var driver1 = await CreateDriverAsync(500m);
        var driver2 = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var startTime = DateTimeOffset.UtcNow.AddHours(1);
        
        var request1 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = startTime.AddHours(1),
            AdvanceDepositAmount = 100m
        };

        await _service.CreateAsync(driver1.Id, request1);

        var request2 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime.AddMinutes(30),
            EndTime = startTime.AddHours(1).AddMinutes(30),
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver2.Id, request2));
    }

    [Fact]
    public async Task CreateByAdminAsync_ValidRequest_CreatesReservationWithoutDeposit()
    {
        var driver = await CreateDriverAsync(0m); // 0 balance is fine for admin creation
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        
        var request = new AdminCreateReservationRequest
        {
            DriverId = driver.Id,
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow.AddHours(1),
            EndTime = DateTimeOffset.UtcNow.AddHours(2)
        };

        var result = await _service.CreateByAdminAsync(admin.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.Confirmed, result.Status);
        
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(0m, updatedDriver!.WalletBalance); // Balance not deducted
    }

    [Fact]
    public async Task CreateWalkInAsync_ValidRequest_CreatesCheckedInReservationAndStartsSession()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        
        var request = new WalkInRequest
        {
            ChargerId = charger.Id,
            StartTime = DateTimeOffset.UtcNow,
            EndTime = DateTimeOffset.UtcNow.AddHours(1),
            CustomerName = "John Doe",
            VehicleNumber = "CBA-1234",
            BatteryCapacity = 50.5
        };

        var result = await _service.CreateWalkInAsync(admin.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.CheckedIn, result.Status);
        Assert.Equal("John Doe", result.WalkInCustomerName);
        Assert.Equal("CBA-1234", result.WalkInVehicleNumber);
        
        // Assert session started
        _sessionsMock.Verify(s => s.StartForCheckedInReservationAsync(It.IsAny<Reservation>(), admin.Id, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CancelAsync_ValidDriver_CancelsAndRefundsBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow.AddHours(2), // More than 1 hour away
            EndTime = DateTimeOffset.UtcNow.AddHours(3),
            AdvanceDepositAmount = 100m
        };

        var reservation = await _service.CreateAsync(driver.Id, request);
        Assert.Equal(400m, (await _db.Users.FindAsync(driver.Id))!.WalletBalance);

        // Cancel
        await _service.CancelAsync(driver.Id, reservation.Id);

        var updatedReservation = await _db.Reservations.FindAsync(reservation.Id);
        Assert.Equal(ReservationStatus.Cancelled, updatedReservation!.Status);
        
        // Fully refunded
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(500m, updatedDriver!.WalletBalance);
    }
}
