using System.IdentityModel.Tokens.Jwt;
using Domain.Users;
using Infrastructure.Authentication;
using Microsoft.Extensions.Options;

namespace UnitTests.Authentication;

public class JwtTokenGeneratorTests
{
    private static readonly JwtSettings Settings = new()
    {
        Issuer = "ChargeSync",
        Audience = "ChargeSync",
        Key = "test-signing-key-that-is-at-least-32-bytes-long",
        AccessTokenMinutes = 60
    };

    private static readonly DateTimeOffset Now = new(2026, 9, 8, 12, 0, 0, TimeSpan.Zero);

    private static JwtTokenGenerator CreateSut() =>
        new(Options.Create(Settings), new FixedTimeProvider(Now));

    private static User CreateUser() =>
        User.Create("Ada Lovelace", "ADA@example.com ", "hash", UserRole.StationOwner);

    [Fact]
    public void Generate_SetsExpiryToConfiguredLifetime()
    {
        var token = CreateSut().Generate(CreateUser());

        Assert.Equal(Now.AddMinutes(60), token.ExpiresAtUtc);
    }

    [Fact]
    public void Generate_EmitsExpectedClaims()
    {
        var user = CreateUser();

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(CreateSut().Generate(user).Value);
        var claimValues = jwt.Claims.Select(c => c.Value).ToList();

        Assert.Equal("ChargeSync", jwt.Issuer);
        Assert.Contains("ChargeSync", jwt.Audiences);
        Assert.Contains(user.Id.ToString(), claimValues);          // sub
        Assert.Contains("ada@example.com", claimValues);            // email, normalised
        Assert.Contains("StationOwner", claimValues);               // role
        Assert.Single(jwt.Claims, c => c.Type == JwtRegisteredClaimNames.Jti);
    }

    [Fact]
    public void Constructor_ThrowsWhenKeyTooShort()
    {
        var weak = Options.Create(new JwtSettings { Key = "too-short" });

        Assert.Throws<InvalidOperationException>(() => new JwtTokenGenerator(weak, new FixedTimeProvider(Now)));
    }

    private sealed class FixedTimeProvider(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
    }
}
