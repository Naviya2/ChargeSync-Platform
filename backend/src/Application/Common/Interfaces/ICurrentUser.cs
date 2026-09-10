using Domain.Users;

namespace Application.Common.Interfaces;

/// <summary>
/// The identity behind the current request, read from the validated JWT.
/// Implemented in the API layer; consumed by application services.
/// </summary>
public interface ICurrentUser
{
    /// <summary>The caller's user id, or <c>null</c> when unauthenticated.</summary>
    Guid? Id { get; }

    /// <summary>The caller's role, or <c>null</c> when unauthenticated or unrecognised.</summary>
    UserRole? Role { get; }

    bool IsAuthenticated { get; }

    /// <summary>True when the caller is a Platform Administrator (unrestricted access — SRS §7.2).</summary>
    bool IsAdmin { get; }
}
