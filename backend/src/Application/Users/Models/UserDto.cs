using Domain.Users;

namespace Application.Users.Models;

public sealed record UserDto(Guid Id, string FullName, string Email, string Role, bool IsActive)
{
    public static UserDto From(User user) =>
        new(user.Id, user.FullName, user.Email, user.Role.ToString(), user.IsActive);
}
