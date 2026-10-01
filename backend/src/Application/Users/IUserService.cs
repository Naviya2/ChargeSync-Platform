using Application.Users.Models;

namespace Application.Users;

public interface IUserService
{
    /// <summary>Creates an account with any role (administrator action).</summary>
    Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken cancellationToken = default);

    /// <summary>Fetches a single user, or throws <see cref="Common.Exceptions.NotFoundException"/>.</summary>
    Task<UserDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<List<UserDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<UserDto> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
