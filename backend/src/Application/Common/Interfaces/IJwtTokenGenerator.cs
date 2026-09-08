using Application.Common.Models;
using Domain.Users;

namespace Application.Common.Interfaces;

/// <summary>
/// Issues signed JWT bearer tokens for authenticated users (SRS §5.2).
/// </summary>
public interface IJwtTokenGenerator
{
    AccessToken Generate(User user);
}
