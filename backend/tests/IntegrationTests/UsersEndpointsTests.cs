using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace IntegrationTests;

public sealed class UsersEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly HttpClient _client;

    public UsersEndpointsTests(ChargeSyncApiFactory factory) => _client = factory.CreateClient();

    private sealed record AuthResponse(string AccessToken, string RefreshToken);
    private sealed record UserDto(Guid Id, string FullName, string Email, string Role, bool IsActive);

    private async Task<string> TokenFor(string email, string password)
    {
        var login = await _client.PostAsJsonAsync("/api/auth/login", new { email, password });
        login.EnsureSuccessStatusCode();
        return (await login.Content.ReadFromJsonAsync<AuthResponse>())!.AccessToken;
    }

    private async Task<string> AdminToken() =>
        await TokenFor(ChargeSyncApiFactory.AdminEmail, ChargeSyncApiFactory.AdminPassword);

    private void UseBearer(string token) =>
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

    [Fact]
    public async Task SeededAdmin_CanAuthenticate()
    {
        var token = await AdminToken();

        Assert.False(string.IsNullOrWhiteSpace(token));
    }

    [Fact]
    public async Task Admin_CanCreateSupportManager_ThenFetchIt()
    {
        UseBearer(await AdminToken());

        var create = await _client.PostAsJsonAsync("/api/users", new
        {
            fullName = "Support Sam",
            email = "support-sam@example.com",
            password = "password123",
            role = "SupportManager"
        });

        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var created = await create.Content.ReadFromJsonAsync<UserDto>();
        Assert.Equal("SupportManager", created!.Role);

        var fetched = await _client.GetFromJsonAsync<UserDto>($"/api/users/{created.Id}");
        Assert.Equal(created.Id, fetched!.Id);
    }

    [Fact]
    public async Task Admin_GetMissingUser_Returns404()
    {
        UseBearer(await AdminToken());

        var response = await _client.GetAsync($"/api/users/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task NonAdmin_CannotCreateUsers()
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Ordinary Driver",
            email = "ordinary-driver@example.com",
            password = "password123",
            role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var driver = await register.Content.ReadFromJsonAsync<AuthResponse>();

        UseBearer(driver!.AccessToken);
        var create = await _client.PostAsJsonAsync("/api/users", new
        {
            fullName = "Sneaky Admin",
            email = "sneaky@example.com",
            password = "password123",
            role = "Admin"
        });

        Assert.Equal(HttpStatusCode.Forbidden, create.StatusCode);
    }

    [Fact]
    public async Task Anonymous_CannotCreateUsers()
    {
        _client.DefaultRequestHeaders.Authorization = null;

        var create = await _client.PostAsJsonAsync("/api/users", new
        {
            fullName = "Nobody",
            email = "nobody@example.com",
            password = "password123",
            role = "Admin"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, create.StatusCode);
    }
}
