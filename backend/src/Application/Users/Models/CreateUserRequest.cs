using Domain.Users;

namespace Application.Users.Models;

/// <summary>
/// Admin-only account creation. Any <see cref="UserRole"/> is allowed here —
/// this is the only way to create Admin and SupportManager accounts.
/// </summary>
public sealed record CreateUserRequest(
    string FullName,
    string Email,
    string Password,
    UserRole Role,
    string? PhoneNumber = null);
