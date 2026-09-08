using Application.Common.Exceptions;
using Application.Users;
using Application.Users.Models;
using Domain.Users;
using Infrastructure.Authentication;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace UnitTests.Users;

public sealed class UserServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"users-{Guid.NewGuid()}")
            .Options);

        _sut = new UserService(_db, new BcryptPasswordHasher());
    }

    public void Dispose() => _db.Dispose();

    [Theory]
    [InlineData(UserRole.Admin)]
    [InlineData(UserRole.SupportManager)]
    [InlineData(UserRole.StationOwner)]
    public async Task Create_PersistsAccountWithRequestedRole(UserRole role)
    {
        var dto = await _sut.CreateAsync(new CreateUserRequest(
            "Staff Member", "Staff@Example.com", "password123", role));

        Assert.Equal(role.ToString(), dto.Role);
        Assert.Equal("staff@example.com", dto.Email);

        var stored = await _db.Users.SingleAsync();
        Assert.Equal(role, stored.Role);
        Assert.NotEqual("password123", stored.PasswordHash);
    }

    [Fact]
    public async Task Create_DuplicateEmail_Throws()
    {
        await _sut.CreateAsync(new CreateUserRequest("A", "dup@example.com", "password123", UserRole.SupportManager));

        await Assert.ThrowsAsync<EmailAlreadyInUseException>(() =>
            _sut.CreateAsync(new CreateUserRequest("B", "DUP@example.com", "password123", UserRole.Admin)));
    }

    [Fact]
    public async Task Create_WeakPassword_ThrowsValidationException()
    {
        var ex = await Assert.ThrowsAsync<ValidationException>(() =>
            _sut.CreateAsync(new CreateUserRequest("A", "x@example.com", "short", UserRole.Admin)));

        Assert.Contains("Password", ex.Errors.Keys);
    }

    [Fact]
    public async Task GetById_Missing_ThrowsNotFound()
    {
        await Assert.ThrowsAsync<NotFoundException>(() => _sut.GetByIdAsync(Guid.NewGuid()));
    }

    [Fact]
    public async Task GetById_ReturnsCreatedUser()
    {
        var created = await _sut.CreateAsync(new CreateUserRequest("Find Me", "find@example.com", "password123", UserRole.Admin));

        var fetched = await _sut.GetByIdAsync(created.Id);

        Assert.Equal(created.Id, fetched.Id);
        Assert.True(fetched.IsActive);
    }
}
