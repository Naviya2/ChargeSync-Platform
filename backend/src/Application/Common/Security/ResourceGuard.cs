using Application.Common.Exceptions;
using Application.Common.Interfaces;

namespace Application.Common.Security;

public sealed class ResourceGuard : IResourceGuard
{
    private readonly ICurrentUser _currentUser;

    public ResourceGuard(ICurrentUser currentUser) => _currentUser = currentUser;

    public bool CanAccess(Guid ownerId) =>
        _currentUser.IsAdmin || (_currentUser.Id is { } callerId && callerId == ownerId);

    public void EnsureOwnerOrAdmin(Guid ownerId)
    {
        if (!CanAccess(ownerId))
        {
            throw new ForbiddenAccessException();
        }
    }
}
