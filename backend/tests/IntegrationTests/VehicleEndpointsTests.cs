using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace IntegrationTests;

public sealed class VehicleEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly ChargeSyncApiFactory _factory;

    public VehicleEndpointsTests(ChargeSyncApiFactory factory)
    {
        _factory = factory;
    }

    private sealed record AuthResponse(string AccessToken);

    private sealed record VehicleResponse(
        Guid Id,
        Guid OwnerId,
        string Make,
        string Model,
        string Connector,
        decimal BatteryCapacityKwh,
        decimal MaxChargeRateKw);

    private async Task<(HttpClient Client, string Token)> CreateAuthenticatedDriverAsync()
    {
        var client = _factory.CreateClient();
        var register = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Vehicle Driver",
            email = $"driver-{Guid.NewGuid():N}@example.com",
            password = "password123",
            role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var auth = await register.Content.ReadFromJsonAsync<AuthResponse>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);
        return (client, auth.AccessToken);
    }

    [Fact]
    public async Task VEH_TC_01_VehicleRegistration_MissingMake_ReturnsBadRequest()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var response = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "",
            model = "Model 3",
            connector = "NACS",
            batteryCapacityKwh = 75.0m,
            maxChargeRateKw = 170.0m
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_02_VehicleRegistration_Valid_ReturnsCreated()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var response = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Tesla",
            model = "Model 3",
            connector = "NACS",
            batteryCapacityKwh = 75.0m,
            maxChargeRateKw = 170.0m
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var vehicle = await response.Content.ReadFromJsonAsync<VehicleResponse>();

        Assert.NotNull(vehicle);
        Assert.NotEqual(Guid.Empty, vehicle.Id);
        Assert.Equal("Tesla", vehicle.Make);
        Assert.Equal("Model 3", vehicle.Model);
        Assert.Equal("NACS", vehicle.Connector);
        Assert.Equal(75.0m, vehicle.BatteryCapacityKwh);
        Assert.Equal(170.0m, vehicle.MaxChargeRateKw);
    }

    [Fact]
    public async Task VEH_TC_03_VehicleRegistration_Unauthenticated_ReturnsUnauthorized()
    {
        var unauthenticatedClient = _factory.CreateClient();

        var response = await unauthenticatedClient.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Tesla",
            model = "Model 3",
            connector = "NACS",
            batteryCapacityKwh = 75.0m,
            maxChargeRateKw = 170.0m
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_04_VehicleRegistration_NegativeBattery_ReturnsBadRequest()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var response = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Nissan",
            model = "Leaf",
            connector = "CHAdeMO",
            batteryCapacityKwh = -10.0m,
            maxChargeRateKw = 50.0m
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_05_VehicleRegistration_ZeroChargeRate_ReturnsBadRequest()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var response = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Nissan",
            model = "Leaf",
            connector = "CHAdeMO",
            batteryCapacityKwh = 40.0m,
            maxChargeRateKw = 0.0m
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_06_CompatibleStationsLookup_Valid_ReturnsOk()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var createRes = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Hyundai",
            model = "Ioniq 5",
            connector = "CCS2",
            batteryCapacityKwh = 77.4m,
            maxChargeRateKw = 233.0m
        });
        createRes.EnsureSuccessStatusCode();
        var vehicle = await createRes.Content.ReadFromJsonAsync<VehicleResponse>();

        var response = await client.GetAsync(
            $"/api/vehicles/{vehicle!.Id}/compatible-stations?latitude=6.9271&longitude=79.8612&radiusKm=25");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.StartsWith("[", body.Trim());
    }

    [Fact]
    public async Task VEH_TC_07_CompatibleStationsLookup_CrossUser_ReturnsForbiddenOrNotFound()
    {
        var (driverA, _) = await CreateAuthenticatedDriverAsync();
        var (driverB, _) = await CreateAuthenticatedDriverAsync();

        var createRes = await driverA.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Kia",
            model = "EV6",
            connector = "CCS2",
            batteryCapacityKwh = 77.4m,
            maxChargeRateKw = 233.0m
        });
        createRes.EnsureSuccessStatusCode();
        var vehicle = await createRes.Content.ReadFromJsonAsync<VehicleResponse>();

        // Driver B attempts to look up Driver A's vehicle
        var response = await driverB.GetAsync(
            $"/api/vehicles/{vehicle!.Id}/compatible-stations?latitude=6.9271&longitude=79.8612&radiusKm=25");

        Assert.True(
            response.StatusCode == HttpStatusCode.NotFound || response.StatusCode == HttpStatusCode.Forbidden,
            $"Expected 404 or 403, got {response.StatusCode}");
    }

    [Fact]
    public async Task VEH_TC_08_VehicleDeletion_OwnVehicle_ReturnsNoContent()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var createRes = await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "BYD",
            model = "Atto 3",
            connector = "CCS2",
            batteryCapacityKwh = 60.0m,
            maxChargeRateKw = 88.0m
        });
        createRes.EnsureSuccessStatusCode();
        var vehicle = await createRes.Content.ReadFromJsonAsync<VehicleResponse>();

        var deleteRes = await client.DeleteAsync($"/api/vehicles/{vehicle!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        // Verification: GetById should return 404 NotFound
        var getRes = await client.GetAsync($"/api/vehicles/{vehicle.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_09_VehicleDeletion_NonExistent_ReturnsNotFound()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        var deleteRes = await client.DeleteAsync($"/api/vehicles/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, deleteRes.StatusCode);
    }

    [Fact]
    public async Task VEH_TC_10_VehicleList_DriverOwnVehicles_ReturnsOk()
    {
        var (client, _) = await CreateAuthenticatedDriverAsync();

        // Create 2 vehicles for this driver
        await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Tesla",
            model = "Model Y",
            connector = "NACS",
            batteryCapacityKwh = 75.0m,
            maxChargeRateKw = 210.0m
        });

        await client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "BMW",
            model = "i4",
            connector = "CCS2",
            batteryCapacityKwh = 80.0m,
            maxChargeRateKw = 200.0m
        });

        var response = await client.GetAsync("/api/vehicles");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var list = await response.Content.ReadFromJsonAsync<List<VehicleResponse>>();
        Assert.NotNull(list);
        Assert.True(list.Count >= 2);
    }
}