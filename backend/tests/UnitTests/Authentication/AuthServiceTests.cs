using Application.Authentication;
using Application.Authentication.Models;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Common.Models;
using Domain.Users;
using Infrastructure.Authentication;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace UnitTests.Authentication;

public sealed class AuthServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly AuthService _sut;

    public AuthServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"auth-{Guid.NewGuid()}")
            .Options);

        _sut = new AuthService(
            _db,
            new BcryptPasswordHasher(),
            new StubTokenGenerator(),
            new StubRefreshTokenIssuer(),
            TimeProvider.System);
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task Register_PersistsUserAndReturnsToken()
    {
        var result = await _sut.RegisterAsync(new RegisterRequest(
            "Grace Hopper", "Grace@Example.com", "password123", UserRole.Driver));

        Assert.Equal("stub-token", result.AccessToken);
        Assert.Equal("grace@example.com", result.User.Email);
        Assert.Equal("Driver", result.User.Role);

        var stored = await _db.Users.SingleAsync();
        Assert.Equal("grace@example.com", stored.Email);
        Assert.NotEqual("password123", stored.PasswordHash);
    }

    [Fact]
    public async Task Register_DuplicateEmail_IsCaseInsensitiveAndThrows()
    {
        await _sut.RegisterAsync(new RegisterRequest(
            "First", "dup@example.com", "password123", UserRole.Driver));

        await Assert.ThrowsAsync<EmailAlreadyInUseException>(() =>
            _sut.RegisterAsync(new RegisterRequest(
                "Second", "DUP@example.com", "password123", UserRole.StationOwner)));
    }

    [Theory]
    [InlineData("short")]
    [InlineData("")]
    public async Task Register_WeakPassword_ThrowsValidationException(string password)
    {
        var ex = await Assert.ThrowsAsync<ValidationException>(() =>
            _sut.RegisterAsync(new RegisterRequest(
                "Name", "user@example.com", password, UserRole.Driver)));

        Assert.Contains("Password", ex.Errors.Keys);
    }

    [Theory]
    [InlineData(UserRole.Admin)]
    [InlineData(UserRole.SupportManager)]
    public async Task Register_PrivilegedRole_ThrowsValidationException(UserRole role)
    {
        var ex = await Assert.ThrowsAsync<ValidationException>(() =>
            _sut.RegisterAsync(new RegisterRequest(
                "Name", "user@example.com", "password123", role)));

        Assert.Contains("Role", ex.Errors.Keys);
    }

    [Fact]
    public async Task Login_ValidCredentials_ReturnsResult()
    {
        await _sut.RegisterAsync(new RegisterRequest(
            "Katherine Johnson", "kj@example.com", "password123", UserRole.Driver));

        var result = await _sut.LoginAsync(new LoginRequest("KJ@example.com", "password123"));

        Assert.Equal("kj@example.com", result.User.Email);
    }

    [Fact]
    public async Task Login_WrongPassword_ThrowsInvalidCredentials()
    {
        await _sut.RegisterAsync(new RegisterRequest(
            "User", "user@example.com", "password123", UserRole.Driver));

        await Assert.ThrowsAsync<InvalidCredentialsException>(() =>
            _sut.LoginAsync(new LoginRequest("user@example.com", "wrong-password")));
    }

    [Fact]
    public async Task Login_UnknownEmail_ThrowsInvalidCredentials()
    {
        await Assert.ThrowsAsync<InvalidCredentialsException>(() =>
            _sut.LoginAsync(new LoginRequest("nobody@example.com", "password123")));
    }

    [Fact]
    public async Task Login_InactiveAccount_ThrowsInvalidCredentials()
    {
        await _sut.RegisterAsync(new RegisterRequest(
            "Suspended", "susp@example.com", "password123", UserRole.Driver));

        var user = await _db.Users.SingleAsync();
        user.Deactivate();
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<InvalidCredentialsException>(() =>
            _sut.LoginAsync(new LoginRequest("susp@example.com", "password123")));
    }

    [Fact]
    public async Task Register_IssuesRotatableRefreshToken()
    {
        var session = await _sut.RegisterAsync(new RegisterRequest(
            "Rotator", "rotate@example.com", "password123", UserRole.Driver));

        Assert.False(string.IsNullOrWhiteSpace(session.RefreshToken));

        var refreshed = await _sut.RefreshAsync(new RefreshRequest(session.RefreshToken));

        Assert.NotEqual(session.RefreshToken, refreshed.RefreshToken);

        // The rotated-out token is now rejected.
        await Assert.ThrowsAsync<InvalidRefreshTokenException>(() =>
            _sut.RefreshAsync(new RefreshRequest(session.RefreshToken)));
    }

    [Fact]
    public async Task Refresh_UnknownToken_Throws()
    {
        await Assert.ThrowsAsync<InvalidRefreshTokenException>(() =>
            _sut.RefreshAsync(new RefreshRequest("not-a-real-token")));
    }

    [Fact]
    public async Task Revoke_ThenRefresh_Throws()
    {
        var session = await _sut.RegisterAsync(new RegisterRequest(
            "Logout", "logout@example.com", "password123", UserRole.Driver));

        await _sut.RevokeAsync(new RefreshRequest(session.RefreshToken));

        await Assert.ThrowsAsync<InvalidRefreshTokenException>(() =>
            _sut.RefreshAsync(new RefreshRequest(session.RefreshToken)));
    }

    private sealed class StubTokenGenerator : IJwtTokenGenerator
    {
        public AccessToken Generate(User user) =>
            new("stub-token", DateTimeOffset.UnixEpoch.AddYears(100));
    }

    private sealed class StubRefreshTokenIssuer : IRefreshTokenIssuer
    {
        public RefreshTokenIssue Issue()
        {
            var raw = Guid.NewGuid().ToString("N");
            return new RefreshTokenIssue(raw, Hash(raw), DateTimeOffset.UtcNow.AddDays(30));
        }

        public string Hash(string rawToken) => $"hash:{rawToken}";
    }
}
