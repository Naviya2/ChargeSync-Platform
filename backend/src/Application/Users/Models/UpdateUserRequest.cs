using Domain.Users;

namespace Application.Users.Models;

public record UpdateUserRequest(
    string FullName,
    string? Email,
    string? Password,
    UserRole Role,
    string? PhoneNumber);
