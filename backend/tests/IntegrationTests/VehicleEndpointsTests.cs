using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace IntegrationTests;

public sealed class VehicleEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly HttpClient _client;

    public VehicleEndpointsTests(ChargeSyncApiFactory factory) => _client = factory.CreateClient();

    private sealed record AuthResponse(string AccessToken);

    private sealed record VehicleResponse(
        Guid Id,
        Guid OwnerId,
        string Make,
        string Model,
        string Connector,
        decimal BatteryCapacityKwh,
        decimal MaxChargeRateKw);

    [Fact]
    public async Task Driver_CanRegisterVehicle_WithRequiredSpecifications()
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Vehicle Driver",
            email = $"vehicle-driver-{Guid.NewGuid():N}@example.com",
            password = "password123",
            role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var auth = await register.Content.ReadFromJsonAsync<AuthResponse>();

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        var response = await _client.PostAsJsonAsync("/api/vehicles", new
        {
            make = "Tesla",
            model = "Model 3",
            connector = "NACS",
            batteryCapacityKwh = 75.0m,
            maxChargeRateKw = 170.0m
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var vehicle = await response.Content.ReadFromJsonAsync<VehicleResponse>();

        Assert.NotEqual(Guid.Empty, vehicle!.Id);
        Assert.Equal("Tesla", vehicle.Make);
        Assert.Equal("Model 3", vehicle.Model);
        Assert.Equal("NACS", vehicle.Connector);
        Assert.Equal(75.0m, vehicle.BatteryCapacityKwh);
        Assert.Equal(170.0m, vehicle.MaxChargeRateKw);
    }
}