namespace Application.Common.Security;

/// <summary>
/// Enforces the SRS rule that a caller may only touch their own data,
/// except Platform Administrators who may touch anyone's (§7.2, FR-1.2, FR-2.2).
/// </summary>
public interface IResourceGuard
{
    /// <summary>
    /// Throws <see cref="Common.Exceptions.ForbiddenAccessException"/> unless the current
    /// caller is <paramref name="ownerId"/> or an administrator.
    /// </summary>
    void EnsureOwnerOrAdmin(Guid ownerId);

    /// <summary>Non-throwing variant of <see cref="EnsureOwnerOrAdmin"/>.</summary>
    bool CanAccess(Guid ownerId);
}
