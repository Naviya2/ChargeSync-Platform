using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Common.Security;
using Domain.Users;

namespace UnitTests.Common;

public class ResourceGuardTests
{
    private static readonly Guid Owner = Guid.NewGuid();
    private static readonly Guid Other = Guid.NewGuid();

    private static ResourceGuard Guard(Guid? id, UserRole? role) => new(new FakeCurrentUser(id, role));

    [Fact]
    public void Owner_CanAccessOwnResource()
    {
        var guard = Guard(Owner, UserRole.Driver);

        Assert.True(guard.CanAccess(Owner));
        guard.EnsureOwnerOrAdmin(Owner); // does not throw
    }

    [Fact]
    public void Admin_CanAccessAnyResource()
    {
        var guard = Guard(Other, UserRole.Admin);

        Assert.True(guard.CanAccess(Owner));
        guard.EnsureOwnerOrAdmin(Owner);
    }

    [Fact]
    public void NonOwnerNonAdmin_IsForbidden()
    {
        var guard = Guard(Other, UserRole.StationOwner);

        Assert.False(guard.CanAccess(Owner));
        Assert.Throws<ForbiddenAccessException>(() => guard.EnsureOwnerOrAdmin(Owner));
    }

    [Fact]
    public void Unauthenticated_IsForbidden()
    {
        var guard = Guard(null, null);

        Assert.False(guard.CanAccess(Owner));
        Assert.Throws<ForbiddenAccessException>(() => guard.EnsureOwnerOrAdmin(Owner));
    }

    private sealed class FakeCurrentUser(Guid? id, UserRole? role) : ICurrentUser
    {
        public Guid? Id => id;
        public UserRole? Role => role;
        public bool IsAuthenticated => id is not null;
        public bool IsAdmin => role == UserRole.Admin;
    }
}
