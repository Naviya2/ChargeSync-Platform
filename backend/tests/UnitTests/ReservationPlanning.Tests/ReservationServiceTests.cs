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

    // ── Test Fixture Helpers ──────────────────────────────────────────────────

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

    private async Task<User> CreateStationOwnerAsync()
    {
        var owner = User.Create("Owner", $"owner_{Guid.NewGuid():N}@test.com", "hash", UserRole.StationOwner);
        _db.Users.Add(owner);
        await _db.SaveChangesAsync();
        return owner;
    }

    private async Task<Charger> CreateChargerAsync(
        User? owner = null,
        bool allDaysOpen = true,
        TimeSpan? openTime = null,
        TimeSpan? closeTime = null,
        int? closedDayOfWeek = null)
    {
        owner ??= await CreateStationOwnerAsync();
        var station = Station.Create("Station", "Address", 6.9271, 79.8612, owner.Id);
        station.UpdateOperatingHours(Enumerable.Range(0, 7)
            .Select(day => OperatingHour.Create(
                station.Id,
                day,
                allDaysOpen && day != closedDayOfWeek,
                openTime ?? TimeSpan.Zero,
                closeTime ?? new TimeSpan(23, 59, 59))).ToList());
        _db.Stations.Add(station);
        var charger = Charger.Create(station.Id, "CH-01", "Bay 1", ConnectorType.CCS2, 50, 40);
        _db.Chargers.Add(charger);
        await _db.SaveChangesAsync();
        return charger;
    }

    private static (DateTimeOffset Start, DateTimeOffset End) GetValidTimeSlot(int offsetHours = 0)
    {
        var sriLankaOffset = TimeSpan.FromHours(5.5);
        var tomorrowLocal = DateTimeOffset.UtcNow.ToOffset(sriLankaOffset).Date.AddDays(1);
        var start = new DateTimeOffset(tomorrowLocal.Year, tomorrowLocal.Month, tomorrowLocal.Day, 10, 0, 0, sriLankaOffset).AddHours(offsetHours);
        var end = start.AddHours(1);
        return (start, end);
    }

    // ── CreateAsync Tests ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesReservationAndDeductsBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
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
        var (startTime, endTime) = GetValidTimeSlot();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request));
    }

    [Fact]
    public async Task CreateAsync_NonExistentDriver_ThrowsNotFoundException()
    {
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<NotFoundException>(() => _service.CreateAsync(Guid.NewGuid(), request));
    }

    [Fact]
    public async Task CreateAsync_NonExistentCharger_ThrowsNotFoundException()
    {
        var driver = await CreateDriverAsync(500m);
        var (startTime, endTime) = GetValidTimeSlot();
        var request = new CreateReservationRequest
        {
            ChargerId = Guid.NewGuid(),
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<NotFoundException>(() => _service.CreateAsync(driver.Id, request));
    }

    [Fact]
    public async Task CreateAsync_DuplicateVehicleReservationSameDay_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        var vehicleId = Guid.NewGuid();

        var request1 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = vehicleId,
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        await _service.CreateAsync(driver.Id, request1);

        var request2 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = vehicleId,
            StartTime = startTime.AddHours(2),
            EndTime = endTime.AddHours(2),
            AdvanceDepositAmount = 100m
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request2));
        Assert.Equal("You already have an incomplete reservation for this vehicle today.", ex.Message);
    }

    [Fact]
    public async Task CreateAsync_ClosedDayOfWeek_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var (startTime, endTime) = GetValidTimeSlot();
        var closedDay = (int)startTime.ToOffset(TimeSpan.FromHours(5.5)).DayOfWeek;
        var charger = await CreateChargerAsync(closedDayOfWeek: closedDay);

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request));
        Assert.Equal("The charging station is closed on this time.", ex.Message);
    }

    [Fact]
    public async Task CreateAsync_OutsideOperatingHours_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync(openTime: new TimeSpan(14, 0, 0), closeTime: new TimeSpan(18, 0, 0));
        var (startTime, endTime) = GetValidTimeSlot(); // 10:00 - 11:00 AM

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request));
        Assert.Contains("outside the station's operating hours", ex.Message);
    }

    [Fact]
    public async Task CreateAsync_MaintenanceWindowOverlap_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var maintenance = MaintenanceWindow.Create(charger.Id, "Routine Check", startTime.AddMinutes(-10), endTime.AddMinutes(10));
        _db.MaintenanceWindows.Add(maintenance);
        await _db.SaveChangesAsync();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver.Id, request));
        Assert.Equal("The requested time slot falls during a scheduled maintenance window for this charger.", ex.Message);
    }

    [Fact]
    public async Task CreateAsync_OverlappingReservation_ThrowsInvalidOperationException()
    {
        var driver1 = await CreateDriverAsync(500m);
        var driver2 = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        
        var request1 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        await _service.CreateAsync(driver1.Id, request1);

        var request2 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime.AddMinutes(30),
            EndTime = endTime.AddMinutes(30),
            AdvanceDepositAmount = 100m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateAsync(driver2.Id, request2));
    }

    [Fact]
    public async Task CreateAsync_WithRequiresApproval_LeavesReservationPendingAndDoesNotDeductBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var result = await _service.CreateAsync(driver.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.Pending, result.Status);

        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(500m, updatedDriver!.WalletBalance); // Not deducted yet

        var histories = await _db.ReservationStatusHistories.Where(h => h.ReservationId == result.Id).ToListAsync();
        Assert.Contains(histories, h => h.NewStatus == ReservationStatus.Pending);
    }

    // ── CreateByAdminAsync Tests ──────────────────────────────────────────────

    [Fact]
    public async Task CreateByAdminAsync_ValidRequest_CreatesReservationWithoutDeposit()
    {
        var driver = await CreateDriverAsync(0m); // 0 balance is fine for admin creation
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        
        var request = new AdminCreateReservationRequest
        {
            DriverId = driver.Id,
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime
        };

        var result = await _service.CreateByAdminAsync(admin.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.Confirmed, result.Status);
        
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(0m, updatedDriver!.WalletBalance); // Balance not deducted
    }

    [Fact]
    public async Task CreateByAdminAsync_NonExistentDriver_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new AdminCreateReservationRequest
        {
            DriverId = Guid.NewGuid(),
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime
        };

        await Assert.ThrowsAsync<NotFoundException>(() => _service.CreateByAdminAsync(admin.Id, request));
    }

    [Fact]
    public async Task CreateByAdminAsync_NonExistentCharger_ThrowsNotFoundException()
    {
        var driver = await CreateDriverAsync();
        var admin = await CreateAdminAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new AdminCreateReservationRequest
        {
            DriverId = driver.Id,
            ChargerId = Guid.NewGuid(),
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime
        };

        await Assert.ThrowsAsync<NotFoundException>(() => _service.CreateByAdminAsync(admin.Id, request));
    }

    [Fact]
    public async Task CreateByAdminAsync_OverlappingSlot_ThrowsInvalidOperationException()
    {
        var driver1 = await CreateDriverAsync(500m);
        var driver2 = await CreateDriverAsync(500m);
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request1 = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };
        await _service.CreateAsync(driver1.Id, request1);

        var request2 = new AdminCreateReservationRequest
        {
            DriverId = driver2.Id,
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime.AddMinutes(15),
            EndTime = endTime.AddMinutes(15)
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateByAdminAsync(admin.Id, request2));
    }

    // ── CreateWalkInAsync Tests ───────────────────────────────────────────────

    [Fact]
    public async Task CreateWalkInAsync_ValidRequest_CreatesCheckedInReservationAndStartsSession()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        
        var request = new WalkInRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime,
            EndTime = endTime,
            CustomerName = "John Doe",
            VehicleNumber = "CBA-1234",
            BatteryCapacity = 50.5
        };

        var result = await _service.CreateWalkInAsync(admin.Id, request);

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.CheckedIn, result.Status);
        Assert.Equal("John Doe", result.WalkInCustomerName);
        Assert.Equal("CBA-1234", result.WalkInVehicleNumber);
        
        _sessionsMock.Verify(s => s.StartForCheckedInReservationAsync(It.IsAny<Reservation>(), admin.Id, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateWalkInAsync_NonExistentCharger_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new WalkInRequest
        {
            ChargerId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            CustomerName = "John Doe"
        };

        await Assert.ThrowsAsync<NotFoundException>(() => _service.CreateWalkInAsync(admin.Id, request));
    }

    [Fact]
    public async Task CreateWalkInAsync_OverlappingSlot_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var booking = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };
        await _service.CreateAsync(driver.Id, booking);

        var walkIn = new WalkInRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime.AddMinutes(15),
            EndTime = endTime.AddMinutes(15),
            CustomerName = "Walk-in Guest"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CreateWalkInAsync(admin.Id, walkIn));
    }

    // ── GetListAsync Tests ────────────────────────────────────────────────────

    [Fact]
    public async Task GetListAsync_AsDriver_ReturnsOnlyOwnReservations()
    {
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start1, end1) = GetValidTimeSlot(0);
        var (start2, end2) = GetValidTimeSlot(2);

        await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start1,
            EndTime = end1,
            AdvanceDepositAmount = 100m
        });

        await _service.CreateAsync(driver2.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start2,
            EndTime = end2,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetListAsync(driver1.Id, UserRole.Driver.ToString(), new ReservationFilter());

        Assert.Single(result.Items);
        Assert.Equal(driver1.Id, result.Items[0].DriverId);
    }

    [Fact]
    public async Task GetListAsync_AsStationOwner_ReturnsOnlyOwnStationsReservations()
    {
        var owner1 = await CreateStationOwnerAsync();
        var owner2 = await CreateStationOwnerAsync();
        var charger1 = await CreateChargerAsync(owner1);
        var charger2 = await CreateChargerAsync(owner2);
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var (start1, end1) = GetValidTimeSlot(0);
        var (start2, end2) = GetValidTimeSlot(2);

        await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger1.Id,
            StartTime = start1,
            EndTime = end1,
            AdvanceDepositAmount = 100m
        });

        await _service.CreateAsync(driver2.Id, new CreateReservationRequest
        {
            ChargerId = charger2.Id,
            StartTime = start2,
            EndTime = end2,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetListAsync(owner1.Id, UserRole.StationOwner.ToString(), new ReservationFilter());

        Assert.Single(result.Items);
        Assert.Equal(charger1.Id, result.Items[0].ChargerId);
    }

    [Fact]
    public async Task GetListAsync_AsAdmin_ReturnsAllReservations()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var (start1, end1) = GetValidTimeSlot(0);
        var (start2, end2) = GetValidTimeSlot(2);

        await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start1,
            EndTime = end1,
            AdvanceDepositAmount = 100m
        });

        await _service.CreateAsync(driver2.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start2,
            EndTime = end2,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetListAsync(admin.Id, UserRole.Admin.ToString(), new ReservationFilter());

        Assert.Equal(2, result.TotalCount);
        Assert.Equal(2, result.Items.Count);
    }

    [Fact]
    public async Task GetListAsync_WithFiltersAndPagination_ReturnsMatchingSubset()
    {
        var admin = await CreateAdminAsync();
        var charger1 = await CreateChargerAsync();
        var charger2 = await CreateChargerAsync();
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var (start1, end1) = GetValidTimeSlot(0);
        var (start2, end2) = GetValidTimeSlot(2);

        var r1 = await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger1.Id,
            StartTime = start1,
            EndTime = end1,
            AdvanceDepositAmount = 100m
        });

        var r2 = await _service.CreateAsync(driver2.Id, new CreateReservationRequest
        {
            ChargerId = charger2.Id,
            StartTime = start2,
            EndTime = end2,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        });

        var chargerFilter = await _service.GetListAsync(admin.Id, UserRole.Admin.ToString(), new ReservationFilter { ChargerId = charger1.Id });
        Assert.Single(chargerFilter.Items);
        Assert.Equal(r1.Id, chargerFilter.Items[0].Id);

        var statusFilter = await _service.GetListAsync(admin.Id, UserRole.Admin.ToString(), new ReservationFilter { Status = ReservationStatus.Pending });
        Assert.Single(statusFilter.Items);
        Assert.Equal(r2.Id, statusFilter.Items[0].Id);

        var paged = await _service.GetListAsync(admin.Id, UserRole.Admin.ToString(), new ReservationFilter { Page = 1, PageSize = 1 });
        Assert.Single(paged.Items);
        Assert.Equal(2, paged.TotalCount);
    }

    // ── GetByIdAsync Tests ────────────────────────────────────────────────────

    [Fact]
    public async Task GetByIdAsync_ExistingReservation_ReturnsCompleteDto()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var created = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetByIdAsync(driver.Id, UserRole.Driver.ToString(), created.Id);

        Assert.NotNull(result);
        Assert.Equal(created.Id, result.Id);
        Assert.Equal("Station", result.StationName);
        Assert.Equal("CH-01", result.ChargerName);
    }

    [Fact]
    public async Task GetByIdAsync_NonExistent_ReturnsNull()
    {
        var admin = await CreateAdminAsync();
        var result = await _service.GetByIdAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid());
        Assert.Null(result);
    }

    [Fact]
    public async Task GetByIdAsync_AsDriverForDifferentDriver_ReturnsNull()
    {
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var created = await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetByIdAsync(driver2.Id, UserRole.Driver.ToString(), created.Id);
        Assert.Null(result);
    }

    [Fact]
    public async Task GetByIdAsync_AsStationOwnerForDifferentStation_ReturnsNull()
    {
        var owner1 = await CreateStationOwnerAsync();
        var owner2 = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner1);
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot();

        var created = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetByIdAsync(owner2.Id, UserRole.StationOwner.ToString(), created.Id);
        Assert.Null(result);
    }

    [Fact]
    public async Task GetByIdAsync_AsAdmin_ReturnsReservationRegardlessOfOwnership()
    {
        var owner = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner);
        var driver = await CreateDriverAsync();
        var admin = await CreateAdminAsync();
        var (start, end) = GetValidTimeSlot();

        var created = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var result = await _service.GetByIdAsync(admin.Id, UserRole.Admin.ToString(), created.Id);
        Assert.NotNull(result);
        Assert.Equal(created.Id, result.Id);
    }

    // ── CancelAsync Tests ─────────────────────────────────────────────────────

    [Fact]
    public async Task CancelAsync_ValidDriver_CancelsAndRefundsBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();
        
        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m
        };

        var reservation = await _service.CreateAsync(driver.Id, request);
        Assert.Equal(400m, (await _db.Users.FindAsync(driver.Id))!.WalletBalance);

        await _service.CancelAsync(driver.Id, reservation.Id);

        var updatedReservation = await _db.Reservations.FindAsync(reservation.Id);
        Assert.Equal(ReservationStatus.Cancelled, updatedReservation!.Status);
        
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(500m, updatedDriver!.WalletBalance);
    }

    [Fact]
    public async Task CancelAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var driver = await CreateDriverAsync();
        await Assert.ThrowsAsync<NotFoundException>(() => _service.CancelAsync(driver.Id, Guid.NewGuid()));
    }

    [Fact]
    public async Task CancelAsync_DifferentDriver_ThrowsForbiddenAccessException()
    {
        var driver1 = await CreateDriverAsync(500m);
        var driver2 = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() => _service.CancelAsync(driver2.Id, res.Id));
    }

    [Fact]
    public async Task CancelAsync_AsAdmin_CancelsReservationAndRefundsDriver()
    {
        var driver = await CreateDriverAsync(500m);
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await _service.CancelAsync(admin.Id, res.Id);

        var updated = await _db.Reservations.FindAsync(res.Id);
        Assert.Equal(ReservationStatus.Cancelled, updated!.Status);

        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(500m, updatedDriver!.WalletBalance);
    }

    [Fact]
    public async Task CancelAsync_AlreadyCheckedIn_ThrowsInvalidOperationException()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var walkIn = await _service.CreateWalkInAsync(admin.Id, new WalkInRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            CustomerName = "Guest"
        });

        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CancelAsync(admin.Id, walkIn.Id));
    }

    // ── StaffCheckinAsync Tests ───────────────────────────────────────────────

    [Fact]
    public async Task StaffCheckinAsync_EmptyQrCode_ThrowsArgumentException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<ArgumentException>(() =>
            _service.StaffCheckinAsync(admin.Id, new StaffCheckinRequest { QrCode = "   " }));
    }

    [Fact]
    public async Task StaffCheckinAsync_NonExistentQrCode_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.StaffCheckinAsync(admin.Id, new StaffCheckinRequest { QrCode = "UNKNOWN-QR" }));
    }

    [Fact]
    public async Task StaffCheckinAsync_OutsideScheduledTimeWindow_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var admin = await CreateAdminAsync();
        var (start, end) = GetValidTimeSlot(3); // 3 hours in the future

        var reservation = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.StaffCheckinAsync(admin.Id, new StaffCheckinRequest { QrCode = reservation.ReservationQRCode! }));
        Assert.Contains("Check-in is only allowed during the scheduled reservation window", ex.Message);
    }

    [Fact]
    public async Task StaffCheckinAsync_ValidQrWithinWindow_MarksCheckedInAndStartsSession()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var admin = await CreateAdminAsync();

        var reservation = Reservation.Create(
            driver.Id,
            charger.Id,
            DateTimeOffset.UtcNow.AddMinutes(-2),
            DateTimeOffset.UtcNow.AddMinutes(30),
            100m);
        reservation.ConfirmWithQrCode("VALID_CHECKIN_QR");
        _db.Reservations.Add(reservation);
        await _db.SaveChangesAsync();

        var result = await _service.StaffCheckinAsync(admin.Id, new StaffCheckinRequest { QrCode = "VALID_CHECKIN_QR" });

        Assert.NotNull(result);
        Assert.Equal(ReservationStatus.CheckedIn, result.Status);

        var histories = await _db.ReservationStatusHistories.Where(h => h.ReservationId == reservation.Id).ToListAsync();
        Assert.Contains(histories, h => h.NewStatus == ReservationStatus.CheckedIn);

        _sessionsMock.Verify(s => s.StartForCheckedInReservationAsync(It.IsAny<Reservation>(), admin.Id, It.IsAny<CancellationToken>()), Times.Once);
    }

    // ── GetHistoryAsync Tests ─────────────────────────────────────────────────

    [Fact]
    public async Task GetHistoryAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.GetHistoryAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid()));
    }

    [Fact]
    public async Task GetHistoryAsync_ExistingReservation_ReturnsChronologicalHistory()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await _service.CancelAsync(driver.Id, res.Id);

        var history = await _service.GetHistoryAsync(driver.Id, UserRole.Driver.ToString(), res.Id);

        Assert.True(history.Count >= 2);
        Assert.Contains(history, h => h.NewStatus == ReservationStatus.Confirmed);
        Assert.Contains(history, h => h.NewStatus == ReservationStatus.Cancelled);
    }

    // ── UpdateAsync Tests ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        var (start, end) = GetValidTimeSlot();

        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.UpdateAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid(), new UpdateReservationRequest
            {
                StartTime = start,
                EndTime = end
            }));
    }

    [Fact]
    public async Task UpdateAsync_AsDriver_UpdatesSuccessfully()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var updatedRes = await _service.UpdateAsync(driver.Id, UserRole.Driver.ToString(), res.Id, new UpdateReservationRequest
        {
            StartTime = start.AddHours(2),
            EndTime = end.AddHours(2)
        });

        Assert.Equal(start.AddHours(2), updatedRes.StartTime);
        Assert.Equal(end.AddHours(2), updatedRes.EndTime);
    }

    [Fact]
    public async Task UpdateAsync_AsUnauthorizedOwner_ThrowsForbiddenAccessException()
    {
        var owner1 = await CreateStationOwnerAsync();
        var owner2 = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner1);
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.UpdateAsync(owner2.Id, UserRole.StationOwner.ToString(), res.Id, new UpdateReservationRequest
            {
                StartTime = start.AddHours(2),
                EndTime = end.AddHours(2)
            }));
    }

    [Fact]
    public async Task UpdateAsync_OverlappingSlot_ThrowsInvalidOperationException()
    {
        var owner = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner);
        var driver1 = await CreateDriverAsync();
        var driver2 = await CreateDriverAsync();
        var (start1, end1) = GetValidTimeSlot(0);
        var (start2, end2) = GetValidTimeSlot(2);

        var res1 = await _service.CreateAsync(driver1.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start1,
            EndTime = end1,
            AdvanceDepositAmount = 100m
        });

        var res2 = await _service.CreateAsync(driver2.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start2,
            EndTime = end2,
            AdvanceDepositAmount = 100m
        });

        // Try to update res2 into res1's window
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.UpdateAsync(owner.Id, UserRole.StationOwner.ToString(), res2.Id, new UpdateReservationRequest
            {
                StartTime = start1.AddMinutes(15),
                EndTime = end1.AddMinutes(15)
            }));
    }

    [Fact]
    public async Task UpdateAsync_ValidOwnerRequest_UpdatesTimeWindow()
    {
        var owner = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner);
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot(0);

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var newStart = start.AddHours(3);
        var newEnd = end.AddHours(3);

        var updated = await _service.UpdateAsync(owner.Id, UserRole.StationOwner.ToString(), res.Id, new UpdateReservationRequest
        {
            StartTime = newStart,
            EndTime = newEnd
        });

        Assert.Equal(newStart, updated.StartTime);
        Assert.Equal(newEnd, updated.EndTime);

        var dbRes = await _db.Reservations.FindAsync(res.Id);
        Assert.Equal(newStart, dbRes!.StartTime);
        Assert.Equal(newEnd, dbRes.EndTime);
    }

    // ── DeleteAsync Tests ─────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.DeleteAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid()));
    }

    [Fact]
    public async Task DeleteAsync_AsDriver_ThrowsForbiddenAccessException()
    {
        var driver = await CreateDriverAsync();
        var charger = await CreateChargerAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.DeleteAsync(driver.Id, UserRole.Driver.ToString(), res.Id));
    }

    [Fact]
    public async Task DeleteAsync_AsUnauthorizedOwner_ThrowsForbiddenAccessException()
    {
        var owner1 = await CreateStationOwnerAsync();
        var owner2 = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner1);
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.DeleteAsync(owner2.Id, UserRole.StationOwner.ToString(), res.Id));
    }

    [Fact]
    public async Task DeleteAsync_AsAdmin_RemovesReservationAndStatusHistories()
    {
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot();

        var res = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        await _service.DeleteAsync(admin.Id, UserRole.Admin.ToString(), res.Id);

        Assert.Null(await _db.Reservations.FindAsync(res.Id));
        var remainingHistories = await _db.ReservationStatusHistories.Where(h => h.ReservationId == res.Id).ToListAsync();
        Assert.Empty(remainingHistories);
    }

    // ── GetAvailableTimeSlotsAsync Tests ──────────────────────────────────────

    [Fact]
    public async Task GetAvailableTimeSlotsAsync_NonExistentCharger_ThrowsNotFoundException()
    {
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.GetAvailableTimeSlotsAsync(Guid.NewGuid(), DateTime.UtcNow.AddDays(1), 30));
    }

    [Fact]
    public async Task GetAvailableTimeSlotsAsync_StationClosedOnDay_ReturnsEmptyList()
    {
        var (start, _) = GetValidTimeSlot();
        var closedDay = (int)start.ToOffset(TimeSpan.FromHours(5.5)).DayOfWeek;
        var charger = await CreateChargerAsync(closedDayOfWeek: closedDay);

        var slots = await _service.GetAvailableTimeSlotsAsync(charger.Id, start.Date, 30);
        Assert.Empty(slots);
    }

    [Fact]
    public async Task GetAvailableTimeSlotsAsync_OpenDay_ReturnsAvailableSlotsExcludingReservations()
    {
        var charger = await CreateChargerAsync(openTime: new TimeSpan(8, 0, 0), closeTime: new TimeSpan(12, 0, 0));
        var driver = await CreateDriverAsync();
        var (start, end) = GetValidTimeSlot(); // 10:00 - 11:00 AM

        await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = start,
            EndTime = end,
            AdvanceDepositAmount = 100m
        });

        var slots = await _service.GetAvailableTimeSlotsAsync(charger.Id, start.Date, 30);

        Assert.NotEmpty(slots);
        // Ensure no returned slot overlaps with the existing reservation (considering 30-min buffer)
        Assert.DoesNotContain(slots, s => s.StartTime < end.AddMinutes(30) && s.EndTime > start.AddMinutes(-30));
    }

    // ── ApproveAsync Tests ────────────────────────────────────────────────────

    [Fact]
    public async Task ApproveAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.ApproveAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid()));
    }

    [Fact]
    public async Task ApproveAsync_AsDriver_ThrowsForbiddenAccessException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var reservation = await _service.CreateAsync(driver.Id, request);

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.ApproveAsync(driver.Id, UserRole.Driver.ToString(), reservation.Id));
    }

    [Fact]
    public async Task ApproveAsync_AsUnauthorizedOwner_ThrowsForbiddenAccessException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var anotherOwner = User.Create("AnotherOwner", "another@owner.com", "hash", UserRole.StationOwner);
        _db.Users.Add(anotherOwner);
        await _db.SaveChangesAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var reservation = await _service.CreateAsync(driver.Id, request);

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.ApproveAsync(anotherOwner.Id, UserRole.StationOwner.ToString(), reservation.Id));
    }

    [Fact]
    public async Task ApproveAsync_NonPendingStatus_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var station = await _db.Stations.FindAsync(charger.StationId);
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = false // Immediately confirmed
        };

        var reservation = await _service.CreateAsync(driver.Id, request);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.ApproveAsync(station!.OwnerId, UserRole.StationOwner.ToString(), reservation.Id));
    }

    [Fact]
    public async Task ApproveAsync_DriverHasInsufficientBalance_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var station = await _db.Stations.FindAsync(charger.StationId);
        var ownerId = station!.OwnerId;
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var reservation = await _service.CreateAsync(driver.Id, request);

        // Driver spends their balance elsewhere before approval
        driver.DeductBalance(450m);
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.ApproveAsync(ownerId, UserRole.StationOwner.ToString(), reservation.Id));
    }

    [Fact]
    public async Task ApproveAsync_AsStationOwner_ApprovesReservationDeductsBalanceAndConfirms()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var station = await _db.Stations.FindAsync(charger.StationId);
        var ownerId = station!.OwnerId;
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var reservation = await _service.CreateAsync(driver.Id, request);
        Assert.Equal(ReservationStatus.Pending, reservation.Status);

        var approved = await _service.ApproveAsync(ownerId, UserRole.StationOwner.ToString(), reservation.Id);

        Assert.NotNull(approved);
        Assert.Equal(ReservationStatus.Confirmed, approved.Status);

        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(400m, updatedDriver!.WalletBalance);

        var histories = await _db.ReservationStatusHistories.Where(h => h.ReservationId == reservation.Id).ToListAsync();
        Assert.Contains(histories, h => h.OldStatus == ReservationStatus.Pending && h.NewStatus == ReservationStatus.Confirmed);
    }

    [Fact]
    public async Task ApproveAsync_AsAdmin_ApprovesReservationDeductsBalanceAndConfirms()
    {
        var driver = await CreateDriverAsync(500m);
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var reservation = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        });

        var approved = await _service.ApproveAsync(admin.Id, UserRole.Admin.ToString(), reservation.Id);

        Assert.NotNull(approved);
        Assert.Equal(ReservationStatus.Confirmed, approved.Status);
        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(400m, updatedDriver!.WalletBalance);
    }

    // ── RejectAsync Tests ─────────────────────────────────────────────────────

    [Fact]
    public async Task RejectAsync_NonExistentReservation_ThrowsNotFoundException()
    {
        var admin = await CreateAdminAsync();
        await Assert.ThrowsAsync<NotFoundException>(() =>
            _service.RejectAsync(admin.Id, UserRole.Admin.ToString(), Guid.NewGuid()));
    }

    [Fact]
    public async Task RejectAsync_AsDriver_ThrowsForbiddenAccessException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var reservation = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.RejectAsync(driver.Id, UserRole.Driver.ToString(), reservation.Id));
    }

    [Fact]
    public async Task RejectAsync_AsUnauthorizedOwner_ThrowsForbiddenAccessException()
    {
        var owner1 = await CreateStationOwnerAsync();
        var owner2 = await CreateStationOwnerAsync();
        var charger = await CreateChargerAsync(owner1);
        var driver = await CreateDriverAsync(500m);
        var (startTime, endTime) = GetValidTimeSlot();

        var reservation = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        });

        await Assert.ThrowsAsync<ForbiddenAccessException>(() =>
            _service.RejectAsync(owner2.Id, UserRole.StationOwner.ToString(), reservation.Id));
    }

    [Fact]
    public async Task RejectAsync_NonPendingStatus_ThrowsInvalidOperationException()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var station = await _db.Stations.FindAsync(charger.StationId);
        var ownerId = station!.OwnerId;
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = false // Immediately confirmed
        };

        var reservation = await _service.CreateAsync(driver.Id, request);
        Assert.Equal(ReservationStatus.Confirmed, reservation.Status);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.RejectAsync(ownerId, UserRole.StationOwner.ToString(), reservation.Id));
    }

    [Fact]
    public async Task RejectAsync_AsStationOwner_CancelsPendingReservationWithoutDeductingBalance()
    {
        var driver = await CreateDriverAsync(500m);
        var charger = await CreateChargerAsync();
        var station = await _db.Stations.FindAsync(charger.StationId);
        var ownerId = station!.OwnerId;
        var (startTime, endTime) = GetValidTimeSlot();

        var request = new CreateReservationRequest
        {
            ChargerId = charger.Id,
            VehicleId = Guid.NewGuid(),
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        };

        var reservation = await _service.CreateAsync(driver.Id, request);
        Assert.Equal(ReservationStatus.Pending, reservation.Status);

        await _service.RejectAsync(ownerId, UserRole.StationOwner.ToString(), reservation.Id);

        var updatedReservation = await _db.Reservations.FindAsync(reservation.Id);
        Assert.Equal(ReservationStatus.Cancelled, updatedReservation!.Status);

        var updatedDriver = await _db.Users.FindAsync(driver.Id);
        Assert.Equal(500m, updatedDriver!.WalletBalance);
    }

    [Fact]
    public async Task RejectAsync_AsAdmin_CancelsPendingReservation()
    {
        var driver = await CreateDriverAsync(500m);
        var admin = await CreateAdminAsync();
        var charger = await CreateChargerAsync();
        var (startTime, endTime) = GetValidTimeSlot();

        var reservation = await _service.CreateAsync(driver.Id, new CreateReservationRequest
        {
            ChargerId = charger.Id,
            StartTime = startTime,
            EndTime = endTime,
            AdvanceDepositAmount = 100m,
            RequiresApproval = true
        });

        await _service.RejectAsync(admin.Id, UserRole.Admin.ToString(), reservation.Id);

        var updatedReservation = await _db.Reservations.FindAsync(reservation.Id);
        Assert.Equal(ReservationStatus.Cancelled, updatedReservation!.Status);
    }
}
