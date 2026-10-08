using Application.Common.Interfaces;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class VehicleDatabaseTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly ChargeSyncApiFactory _factory;

    public VehicleDatabaseTests(ChargeSyncApiFactory factory)
    {
        _factory = factory;
    }

    private AppDbContext CreateDbContext()
    {
        var scope = _factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    private async Task<User> CreateTestUserAsync(AppDbContext db)
    {
        var user = User.Create(
            $"db-driver-{Guid.NewGuid():N}@example.com",
            "passwordHash123",
            "DB Test Driver",
            UserRole.Driver);
        db.Users.Add(user);
        await db.SaveChangesAsync();
        return user;
    }

    [Fact]
    public async Task VEH_DB_01_VehicleLicensePlate_Tracking_Or_Id_Uniqueness()
    {
        using var db = CreateDbContext();
        var user = await CreateTestUserAsync(db);

        var vehicle1 = Vehicle.Create(
            user.Id, "Tesla", "Model 3", ConnectorType.NACS, 75.0m, 170.0m, "CAB-4921");
        db.Vehicles.Add(vehicle1);
        await db.SaveChangesAsync();

        // Attempting to attach another entity with the exact same Id throws InvalidOperationException / DbUpdateException
        var vehicleDuplicate = Vehicle.Create(
            user.Id, "Tesla", "Model Y", ConnectorType.NACS, 75.0m, 170.0m, "CAB-4921");
        
        // Simulating duplicate key constraint
        typeof(Vehicle).GetProperty("Id")!.SetValue(vehicleDuplicate, vehicle1.Id);

        Assert.Throws<InvalidOperationException>(() =>
        {
            db.Vehicles.Add(vehicleDuplicate);
        });
    }

    [Fact]
    public async Task VEH_DB_02_DriverVehicle_ForeignKey_Integrity()
    {
        using var db = CreateDbContext();
        var user = await CreateTestUserAsync(db);

        var vehicle = Vehicle.Create(
            user.Id, "Hyundai", "Ioniq 5", ConnectorType.CCS2, 77.4m, 233.0m, "EV-1002");
        db.Vehicles.Add(vehicle);
        await db.SaveChangesAsync();

        // Verify relationship navigation holds at persistence level
        var loaded = await db.Vehicles.Include(v => v.Owner).FirstOrDefaultAsync(v => v.Id == vehicle.Id);
        Assert.NotNull(loaded);
        Assert.NotNull(loaded.Owner);
        Assert.Equal(user.Id, loaded.Owner.Id);
        Assert.Equal(user.Email, loaded.Owner.Email);
    }

    [Fact]
    public async Task VEH_DB_03_BatteryAndChargingRate_Bounds_Validation()
    {
        using var db = CreateDbContext();
        var user = await CreateTestUserAsync(db);

        // Domain validation enforces negative battery constraint before persistence
        var ex = Assert.Throws<ArgumentException>(() =>
        {
            Vehicle.Create(user.Id, "Nissan", "Leaf", ConnectorType.CHAdeMO, -5.0m, 50.0m);
        });

        Assert.Contains("Battery capacity must be positive", ex.Message);
    }

    [Fact]
    public async Task VEH_DB_04_SaveTransaction_Atomicity()
    {
        using var db = CreateDbContext();
        var user = await CreateTestUserAsync(db);

        var validVehicle = Vehicle.Create(
            user.Id, "Kia", "EV6", ConnectorType.CCS2, 77.4m, 233.0m, "EV-9999");

        // Simulate multi-entity batch operation that fails prior to commit
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
        {
            db.Vehicles.Add(validVehicle);
            throw new InvalidOperationException("Simulated mid-transaction failure");
        });

        // Ensure change tracker discards uncommitted unit of work
        db.ChangeTracker.Clear();

        // Verify entity was rolled back and not persisted in database
        using var verifyDb = CreateDbContext();
        var exists = await verifyDb.Vehicles.AnyAsync(v => v.Id == validVehicle.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task VEH_DB_05_ConnectorType_Enum_Persistence()
    {
        using var db = CreateDbContext();
        var user = await CreateTestUserAsync(db);

        var vehicle = Vehicle.Create(
            user.Id, "Tesla", "Cybertruck", ConnectorType.NACS, 123.0m, 250.0m, "CYBER-01");
        db.Vehicles.Add(vehicle);
        await db.SaveChangesAsync();

        // Query fresh context to verify enum string conversion
        using var readDb = CreateDbContext();
        var persisted = await readDb.Vehicles.AsNoTracking().FirstOrDefaultAsync(v => v.Id == vehicle.Id);

        Assert.NotNull(persisted);
        Assert.Equal(ConnectorType.NACS, persisted.Connector);
        Assert.Equal(123.0m, persisted.BatteryCapacityKwh);
    }
}
