namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when registering with an email address that already has an account.
/// The API layer maps this to HTTP 409 Conflict.
/// </summary>
public sealed class EmailAlreadyInUseException : Exception
{
    public EmailAlreadyInUseException()
        : base("An account with this email address already exists.")
    {
    }
}
