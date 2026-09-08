using Domain.Users;

namespace Application.Authentication.Models;

/// <summary>
/// Self-service registration. Only <see cref="UserRole.Driver"/> and
/// <see cref="UserRole.StationOwner"/> may be requested here; Admin and
/// SupportManager accounts are created by an administrator.
/// </summary>
public sealed record RegisterRequest(
    string FullName,
    string Email,
    string Password,
    UserRole Role,
    string? PhoneNumber = null);
