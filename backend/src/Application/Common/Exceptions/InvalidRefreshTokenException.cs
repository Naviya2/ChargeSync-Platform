namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when a refresh token is missing, unknown, expired, revoked, or belongs
/// to a suspended account. The API layer maps this to HTTP 401.
/// </summary>
public sealed class InvalidRefreshTokenException : Exception
{
    public InvalidRefreshTokenException()
        : base("The refresh token is invalid or has expired.")
    {
    }
}
