using Application.Authentication.Models;
using Application.Common;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Authentication;

public sealed class AuthService : IAuthService
{
    private readonly IAppDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenGenerator _tokenGenerator;
    private readonly IRefreshTokenIssuer _refreshTokenIssuer;
    private readonly TimeProvider _timeProvider;

    public AuthService(
        IAppDbContext db,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator tokenGenerator,
        IRefreshTokenIssuer refreshTokenIssuer,
        TimeProvider timeProvider)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _tokenGenerator = tokenGenerator;
        _refreshTokenIssuer = refreshTokenIssuer;
        _timeProvider = timeProvider;
    }

    public async Task<AuthResult> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        Validate(request);

        var email = NormaliseEmail(request.Email);

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

        return await IssueSessionAsync(user, cancellationToken);
    }

    public async Task<AuthResult> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var email = NormaliseEmail(request.Email);

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Email == email, cancellationToken);

        if (user is null || !user.IsActive
            || !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new InvalidCredentialsException();
        }

        return await IssueSessionAsync(user, cancellationToken);
    }

    public async Task<AuthResult> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            throw new InvalidRefreshTokenException();
        }

        var hash = _refreshTokenIssuer.Hash(request.RefreshToken);

        var token = await _db.RefreshTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash, cancellationToken);

        var now = _timeProvider.GetUtcNow();

        if (token is null || !token.IsActiveAt(now) || !token.User.IsActive)
        {
            throw new InvalidRefreshTokenException();
        }

        var issue = _refreshTokenIssuer.Issue();
        token.Revoke(now, issue.TokenHash);
        _db.RefreshTokens.Add(RefreshToken.Issue(token.User, issue.TokenHash, issue.ExpiresAtUtc));

        await _db.SaveChangesAsync(cancellationToken);

        return BuildResult(token.User, issue);
    }

    public async Task RevokeAsync(RefreshRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return;
        }

        var hash = _refreshTokenIssuer.Hash(request.RefreshToken);

        var token = await _db.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash, cancellationToken);

        if (token is null || token.RevokedAt is not null)
        {
            return;
        }

        token.Revoke(_timeProvider.GetUtcNow());
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<AuthResult> IssueSessionAsync(User user, CancellationToken cancellationToken)
    {
        var issue = _refreshTokenIssuer.Issue();
        _db.RefreshTokens.Add(RefreshToken.Issue(user, issue.TokenHash, issue.ExpiresAtUtc));

        await _db.SaveChangesAsync(cancellationToken);

        return BuildResult(user, issue);
    }

    private AuthResult BuildResult(User user, RefreshTokenIssue refreshToken)
    {
        var accessToken = _tokenGenerator.Generate(user);

        return new AuthResult(
            accessToken.Value,
            accessToken.ExpiresAtUtc,
            refreshToken.RawToken,
            refreshToken.ExpiresAtUtc,
            new AuthUser(user.Id, user.FullName, user.Email, user.Role.ToString()));
    }

    private static void Validate(RegisterRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        AccountValidation.ValidateProfile(request.FullName, request.Email, request.Password, request.PhoneNumber, errors);

        if (request.Role is not (UserRole.Driver or UserRole.StationOwner))
        {
            errors[nameof(request.Role)] = ["Role must be 'Driver' or 'StationOwner'."];
        }

        if (errors.Count > 0)
        {
            throw new ValidationException(errors);
        }
    }

    private static string NormaliseEmail(string email) => email.Trim().ToLowerInvariant();
}
