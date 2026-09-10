using Domain.Users;
using Infrastructure.Authentication;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace UnitTests.Persistence;

public sealed class DbSeederTests : IDisposable
{
    private readonly AppDbContext _db;

    public DbSeederTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"seed-{Guid.NewGuid()}")
            .Options);
    }

    public void Dispose() => _db.Dispose();

    private DbSeeder Seeder(SeedOptions options) =>
        new(_db, new BcryptPasswordHasher(), Options.Create(options), NullLogger<DbSeeder>.Instance);

    private static SeedOptions Configured => new()
    {
        AdminEmail = "admin@chargesync.test",
        AdminPassword = "admin-password-123",
        AdminFullName = "Platform Administrator"
    };

    [Fact]
    public async Task SeedAsync_CreatesAdmin_WhenConfiguredAndNoneExists()
    {
        await Seeder(Configured).SeedAsync();

        var admin = await _db.Users.SingleAsync();
        Assert.Equal(UserRole.Admin, admin.Role);
        Assert.Equal("admin@chargesync.test", admin.Email);
    }

    [Fact]
    public async Task SeedAsync_IsIdempotent()
    {
        await Seeder(Configured).SeedAsync();
        await Seeder(Configured).SeedAsync();

        Assert.Equal(1, await _db.Users.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_DoesNothing_WhenNotConfigured()
    {
        await Seeder(new SeedOptions()).SeedAsync();

        Assert.Equal(0, await _db.Users.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_DoesNotOverwrite_WhenEmailBelongsToNonAdmin()
    {
        _db.Users.Add(User.Create("Existing", "admin@chargesync.test", "hash", UserRole.Driver));
        await _db.SaveChangesAsync();

        await Seeder(Configured).SeedAsync();

        var user = await _db.Users.SingleAsync();
        Assert.Equal(UserRole.Driver, user.Role);
    }
}
