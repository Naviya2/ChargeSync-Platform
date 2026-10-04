using Application.Stations;
using Application.Stations.Models;
using Domain.Entities;
using Domain.Enums;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace UnitTests.Stations;

public sealed class StationServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly StationService _service;

    public StationServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"stations-{Guid.NewGuid()}")
            .Options);
        _service = new StationService(_db);
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task RegisterStationAsync_CreatesStationAndSaves()
    {
        var ownerId = Guid.NewGuid();
        var request = new RegisterStationRequest
        {
            Name = "Test Station",
            Address = "123 Test St",
            Latitude = 1.0,
            Longitude = 2.0,
            DocumentUrls = new List<string>()
        };

        var result = await _service.RegisterStationAsync(ownerId, request);

        Assert.NotNull(result);
        Assert.Equal("Test Station", result.Name);

        var saved = await _db.Stations.SingleAsync();
        Assert.Equal(ownerId, saved.OwnerId);
        Assert.Equal("Test Station", saved.Name);
    }

    [Fact]
    public async Task GetStationByIdAsync_ReturnsStation_WhenOwnerMatches()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("My Station", "Address", 0, 0, ownerId, new List<string>());
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var result = await _service.GetStationByIdAsync(station.Id, ownerId);

        Assert.NotNull(result);
        Assert.Equal(station.Id, result.Id);
    }

    [Fact]
    public async Task GetStationByIdAsync_ReturnsNull_WhenOwnerDoesNotMatch()
    {
        var ownerId = Guid.NewGuid();
        var otherId = Guid.NewGuid();
        var station = Station.Create("My Station", "Address", 0, 0, ownerId, new List<string>());
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var result = await _service.GetStationByIdAsync(station.Id, otherId);

        Assert.Null(result);
    }

    [Fact]
    public async Task AddChargerAsync_AddsCharger_WhenStationActive()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("Station", "Address", 0, 0, ownerId, new List<string>());
        station.Approve();
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var request = new AddChargerRequest
        {
            Identifier = "CHG-1",
            BayLabel = "Bay 1",
            Connector = ConnectorType.CCS2,
            PowerKw = 50,
            Tariff = 0.5m
        };

        var result = await _service.AddChargerAsync(station.Id, ownerId, request);

        Assert.NotNull(result);
        Assert.Equal("CHG-1", result.Identifier);

        var saved = await _db.Chargers.SingleAsync();
        Assert.Equal("CHG-1", saved.Identifier);
        Assert.Equal(station.Id, saved.StationId);
    }

    [Fact]
    public async Task AddChargerAsync_ThrowsException_WhenStationNotActive()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("Station", "Address", 0, 0, ownerId, new List<string>());
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var request = new AddChargerRequest
        {
            Identifier = "CHG-1",
            BayLabel = "Bay 1",
            Connector = ConnectorType.CCS2,
            PowerKw = 50,
            Tariff = 0.5m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.AddChargerAsync(station.Id, ownerId, request));
    }

    [Fact]
    public async Task UpdateStationAsync_UpdatesDetails_WhenOwnerMatches()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("Old Name", "Old Addr", 0, 0, ownerId, new List<string>());
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var request = new UpdateStationRequest
        {
            Name = "New Name",
            Address = "New Addr",
            Latitude = 10,
            Longitude = 20
        };

        var result = await _service.UpdateStationAsync(station.Id, ownerId, request);

        Assert.Equal("New Name", result.Name);
        var saved = await _db.Stations.SingleAsync();
        Assert.Equal("New Addr", saved.Address);
    }

    [Fact]
    public async Task UpdateChargerAsync_UpdatesChargerDetails()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("S", "A", 0, 0, ownerId, new List<string>());
        var charger = Charger.Create(station.Id, "CHG-1", "B1", ConnectorType.CCS2, 50, 0.5m);
        station.AddCharger(charger);
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        var request = new UpdateChargerRequest
        {
            Identifier = "CHG-1-NEW",
            BayLabel = "B2",
            Connector = ConnectorType.CCS2,
            PowerKw = 100,
            Tariff = 1.0m
        };

        var result = await _service.UpdateChargerAsync(station.Id, charger.Id, ownerId, request);

        Assert.Equal("CHG-1-NEW", result.Identifier);
        var saved = await _db.Chargers.SingleAsync();
        Assert.Equal(100, saved.PowerKw);
    }

    [Fact]
    public async Task DeleteChargerAsync_RemovesCharger()
    {
        var ownerId = Guid.NewGuid();
        var station = Station.Create("S", "A", 0, 0, ownerId, new List<string>());
        var charger = Charger.Create(station.Id, "CHG-1", "B1", ConnectorType.CCS2, 50, 0.5m);
        station.AddCharger(charger);
        _db.Stations.Add(station);
        await _db.SaveChangesAsync();

        await _service.DeleteChargerAsync(station.Id, charger.Id, ownerId);

        Assert.Empty(await _db.Chargers.ToListAsync());
    }

    [Fact]
    public async Task SearchStationsAsync_ReturnsOnlyActiveStations()
    {
        var ownerId = Guid.NewGuid();
        var s1 = Station.Create("Active", "A", 0, 0, ownerId, new List<string>());
        s1.Approve();
        
        var s2 = Station.Create("Pending", "A", 0, 0, ownerId, new List<string>());
        
        _db.Stations.AddRange(s1, s2);
        await _db.SaveChangesAsync();

        var results = await _service.SearchStationsAsync(null, null, 25, null, null);

        Assert.Single(results);
        Assert.Equal("Active", results[0].Name);
    }
}
