namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when a login attempt fails — wrong email, wrong password, or a
/// suspended account. The message is deliberately generic so it cannot be used
/// to discover which emails are registered. The API layer maps this to HTTP 401.
/// </summary>
public sealed class InvalidCredentialsException : Exception
{
    public InvalidCredentialsException()
        : base("Invalid email or password.")
    {
    }
}
