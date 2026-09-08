using Application.Users.Models;

namespace Application.Users;

public interface IUserService
{
    /// <summary>Creates an account with any role (administrator action).</summary>
    Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken cancellationToken = default);

    /// <summary>Fetches a single user, or throws <see cref="Common.Exceptions.NotFoundException"/>.</summary>
    Task<UserDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
