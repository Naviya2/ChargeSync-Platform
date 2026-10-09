using Application.Stations;
using Application.Reservations;
using Domain.Entities;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace UnitTests.Stations;

public sealed class AvailabilityServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly Mock<IServiceProvider> _serviceProviderMock;
    private readonly Mock<IReservationService> _reservationServiceMock;
    private readonly AvailabilityService _service;

    public AvailabilityServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"availability-{Guid.NewGuid()}")
            .Options);

        _reservationServiceMock = new Mock<IReservationService>();
        _serviceProviderMock = new Mock<IServiceProvider>();
        
        _serviceProviderMock
            .Setup(sp => sp.GetService(typeof(IReservationService)))
            .Returns(_reservationServiceMock.Object);

        _service = new AvailabilityService(_db, _serviceProviderMock.Object);
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task IsChargerAvailableAsync_ReturnsTrue_WhenNoMaintenanceOrReservations()
    {
        // Arrange
        var station = Station.Create("Test", "Address", 0, 0, Guid.NewGuid(), new List<string>());
        station.Approve();
        
        var oh = OperatingHour.Create(station.Id, (int)DateTimeOffset.UtcNow.DayOfWeek, true, TimeSpan.Zero, new TimeSpan(23, 59, 59));
        station.UpdateOperatingHours(new List<OperatingHour> { oh });

        var charger = Charger.Create(station.Id, "CHG-01", "Bay A", Domain.Enums.ConnectorType.Type2, 50.0m, 1.0m);
        station.AddCharger(charger);

        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        _reservationServiceMock
            .Setup(r => r.HasActiveReservationAsync(charger.Id, It.IsAny<DateTimeOffset>(), It.IsAny<DateTimeOffset>(), default))
            .ReturnsAsync(false);

        // Act
        var result = await _service.IsChargerAvailableAsync(charger.Id, DateTimeOffset.UtcNow);

        // Assert
        Assert.True(result);
    }

    [Fact]
    public async Task IsChargerAvailableAsync_ReturnsFalse_WhenMaintenanceWindowOverlaps()
    {
        // Arrange
        var station = Station.Create("Test", "Address", 0, 0, Guid.NewGuid(), new List<string>());
        station.Approve();
        
        var oh = OperatingHour.Create(station.Id, (int)DateTimeOffset.UtcNow.DayOfWeek, true, TimeSpan.Zero, new TimeSpan(23, 59, 59));
        station.UpdateOperatingHours(new List<OperatingHour> { oh });

        var charger = Charger.Create(station.Id, "CHG-02", "Bay B", Domain.Enums.ConnectorType.CCS2, 100.0m, 1.5m);
        station.AddCharger(charger);
        
        var mw = MaintenanceWindow.Create(charger.Id, "Routine Check", DateTimeOffset.UtcNow.AddMinutes(-30), DateTimeOffset.UtcNow.AddMinutes(30));
        charger.MaintenanceWindows.Add(mw);

        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        // Act
        var result = await _service.IsChargerAvailableAsync(charger.Id, DateTimeOffset.UtcNow);

        // Assert
        Assert.False(result);
    }
}
