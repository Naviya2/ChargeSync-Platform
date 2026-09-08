using Application.Common;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Users.Models;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Users;

public sealed class UserService : IUserService
{
    private readonly IAppDbContext _db;
    private readonly IPasswordHasher _passwordHasher;

    public UserService(IAppDbContext db, IPasswordHasher passwordHasher)
    {
        _db = db;
        _passwordHasher = passwordHasher;
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken cancellationToken = default)
    {
        var errors = new Dictionary<string, string[]>();
        AccountValidation.ValidateProfile(request.FullName, request.Email, request.Password, request.PhoneNumber, errors);

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }

        var email = request.Email.Trim().ToLowerInvariant();

        var emailTaken = await _db.Users
            .AsNoTracking()
            .AnyAsync(u => u.Email == email, cancellationToken);

        if (emailTaken)
        {
            throw new EmailAlreadyInUseException();
        }

        var user = User.Create(
            request.FullName,
            email,
            _passwordHasher.Hash(request.Password),
            request.Role,
            request.PhoneNumber);

        _db.Users.Add(user);
        await _db.SaveChangesAsync(cancellationToken);

        return UserDto.From(user);
    }

    public async Task<UserDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken)
            ?? throw new NotFoundException("User", id);

        return UserDto.From(user);
    }
}
