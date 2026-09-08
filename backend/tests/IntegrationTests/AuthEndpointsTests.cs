using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace IntegrationTests;

public sealed class AuthEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly HttpClient _client;

    public AuthEndpointsTests(ChargeSyncApiFactory factory) => _client = factory.CreateClient();

    private static object RegisterBody(string email) => new
    {
        fullName = "Integration User",
        email,
        password = "password123",
        role = "Driver"
    };

    private sealed record AuthResponse(
        string AccessToken,
        DateTimeOffset AccessTokenExpiresAtUtc,
        string RefreshToken,
        DateTimeOffset RefreshTokenExpiresAtUtc,
        UserDto User);

    private sealed record UserDto(Guid Id, string FullName, string Email, string Role);

    private async Task<AuthResponse> RegisterAsync(string email)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register", RegisterBody(email));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthResponse>())!;
    }

    private void UseBearer(string token) =>
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

    [Fact]
    public async Task Register_ThenMe_ReturnsSameIdentity()
    {
        var auth = await RegisterAsync("reg-me@example.com");

        UseBearer(auth.AccessToken);
        var me = await _client.GetFromJsonAsync<UserDto>("/api/auth/me");

        Assert.Equal(auth.User.Id, me!.Id);
        Assert.Equal("reg-me@example.com", me.Email);
        Assert.Equal("Driver", me.Role);
    }

    [Fact]
    public async Task Register_ReturnsBothTokens()
    {
        var auth = await RegisterAsync("both-tokens@example.com");

        Assert.False(string.IsNullOrWhiteSpace(auth.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(auth.RefreshToken));
        Assert.True(auth.RefreshTokenExpiresAtUtc > auth.AccessTokenExpiresAtUtc);
    }

    [Fact]
    public async Task Login_ThenMe_Succeeds()
    {
        await RegisterAsync("login-me@example.com");

        var login = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "LOGIN-ME@example.com",
            password = "password123"
        });
        login.EnsureSuccessStatusCode();
        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>();

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/auth/me");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);
        var me = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
    }

    [Fact]
    public async Task Refresh_RotatesToken_AndOldTokenStopsWorking()
    {
        var auth = await RegisterAsync("refresh-flow@example.com");

        var refresh = await _client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = auth.RefreshToken });
        refresh.EnsureSuccessStatusCode();
        var rotated = await refresh.Content.ReadFromJsonAsync<AuthResponse>();

        Assert.NotEqual(auth.RefreshToken, rotated!.RefreshToken);

        var reuseOld = await _client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = auth.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, reuseOld.StatusCode);

        var useNew = await _client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = rotated.RefreshToken });
        Assert.Equal(HttpStatusCode.OK, useNew.StatusCode);
    }

    [Fact]
    public async Task Refresh_GarbageToken_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = "garbage" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Logout_RevokesRefreshToken()
    {
        var auth = await RegisterAsync("logout-flow@example.com");
        UseBearer(auth.AccessToken);

        var logout = await _client.PostAsJsonAsync("/api/auth/logout", new { refreshToken = auth.RefreshToken });
        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);

        _client.DefaultRequestHeaders.Authorization = null;
        var refresh = await _client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = auth.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task Logout_WithoutToken_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/logout", new { refreshToken = "anything" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithoutToken_Returns401()
    {
        _client.DefaultRequestHeaders.Authorization = null;

        var response = await _client.GetAsync("/api/auth/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Register_WeakPassword_Returns400WithErrors()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "X",
            email = "weak@example.com",
            password = "short",
            role = "Driver"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.True(problem!.ContainsKey("errors"));
    }

    [Fact]
    public async Task Register_DuplicateEmail_Returns409()
    {
        await RegisterAsync("dupe@example.com");

        var second = await _client.PostAsJsonAsync("/api/auth/register", RegisterBody("dupe@example.com"));

        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Register_PrivilegedRole_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Wannabe Admin",
            email = "admin-wannabe@example.com",
            password = "password123",
            role = "Admin"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
