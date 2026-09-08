using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Api.Authentication;
using Domain.Users;
using Microsoft.AspNetCore.Http;

namespace IntegrationTests;

public class CurrentUserTests
{
    private static CurrentUser For(params Claim[] claims)
    {
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(claims, authenticationType: "Test"))
        };

        return new CurrentUser(new HttpContextAccessor { HttpContext = context });
    }

    [Fact]
    public void ReadsIdAndRoleFromClaims()
    {
        var id = Guid.NewGuid();

        var user = For(
            new Claim(JwtRegisteredClaimNames.Sub, id.ToString()),
            new Claim(ClaimTypes.Role, nameof(UserRole.StationOwner)));

        Assert.Equal(id, user.Id);
        Assert.Equal(UserRole.StationOwner, user.Role);
        Assert.True(user.IsAuthenticated);
        Assert.False(user.IsAdmin);
    }

    [Fact]
    public void AdminRole_SetsIsAdmin()
    {
        var user = For(
            new Claim(JwtRegisteredClaimNames.Sub, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.Role, nameof(UserRole.Admin)));

        Assert.True(user.IsAdmin);
    }

    [Fact]
    public void NoHttpContext_IsUnauthenticated()
    {
        var user = new CurrentUser(new HttpContextAccessor());

        Assert.Null(user.Id);
        Assert.Null(user.Role);
        Assert.False(user.IsAuthenticated);
        Assert.False(user.IsAdmin);
    }
}
