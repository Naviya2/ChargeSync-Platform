using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Application.Stations.Models;

namespace IntegrationTests;

public sealed class StationEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly HttpClient _client;
    private readonly ChargeSyncApiFactory _factory;

    public StationEndpointsTests(ChargeSyncApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private static readonly System.Text.Json.JsonSerializerOptions JsonOptions = new()
    {
        Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() },
        PropertyNameCaseInsensitive = true
    };

    private sealed record AuthResponse(string AccessToken, UserDto User);
    private sealed record UserDto(Guid Id, string FullName, string Email, string Role);

    private async Task<AuthResponse> RegisterAsync(string email, string role)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Integration User",
            email,
            password = "password123",
            role = role
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthResponse>())!;
    }

    private void UseBearer(string token) =>
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

    [Fact]
    public async Task RegisterStation_Returns201_ForStationOwner()
    {
        var auth = await RegisterAsync("owner@chargesync.test", "StationOwner");
        UseBearer(auth.AccessToken);

        var request = new RegisterStationRequest
        {
            Name = "New Station",
            Address = "123 Main St",
            Latitude = 1.23,
            Longitude = 4.56,
            DocumentUrls = new List<string>()
        };

        var response = await _client.PostAsJsonAsync("/api/stations", request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var station = await response.Content.ReadFromJsonAsync<StationDto>(JsonOptions);
        Assert.NotNull(station);
        Assert.Equal("New Station", station!.Name);
    }

    [Fact]
    public async Task RegisterStation_Returns403_ForDriver()
    {
        var auth = await RegisterAsync("driver@chargesync.test", "Driver");
        UseBearer(auth.AccessToken);

        var request = new RegisterStationRequest
        {
            Name = "New Station",
            Address = "123 Main St",
            Latitude = 1.23,
            Longitude = 4.56,
            DocumentUrls = new List<string>()
        };

        var response = await _client.PostAsJsonAsync("/api/stations", request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetAllStations_Returns200_Anonymous()
    {
        var response = await _client.GetAsync("/api/stations/all");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddCharger_Returns400_WhenStationNotActive()
    {
        var auth = await RegisterAsync("owner3@chargesync.test", "StationOwner");
        UseBearer(auth.AccessToken);

        var stationRequest = new RegisterStationRequest
        {
            Name = "My Station",
            Address = "123 Main St",
            Latitude = 1.23,
            Longitude = 4.56,
            DocumentUrls = new List<string>()
        };
        var stationResponse = await _client.PostAsJsonAsync("/api/stations", stationRequest);
        var station = await stationResponse.Content.ReadFromJsonAsync<StationDto>(JsonOptions);

        var chargerRequest = new AddChargerRequest
        {
            Identifier = "CHG-01",
            BayLabel = "Bay 1",
            Connector = Domain.Enums.ConnectorType.CCS2,
            PowerKw = 50,
            Tariff = 0.5m
        };

        var response = await _client.PostAsJsonAsync($"/api/stations/{station!.Id}/chargers", chargerRequest);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SearchStations_Returns200_Anonymous()
    {
        var response = await _client.GetAsync("/api/stations/search?radiusKm=25&query=test");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
