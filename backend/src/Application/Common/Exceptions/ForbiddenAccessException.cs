namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when an authenticated caller tries to act on a resource they do not own
/// and are not an administrator for. The API layer maps this to HTTP 403.
/// </summary>
public sealed class ForbiddenAccessException : Exception
{
    public ForbiddenAccessException()
        : base("You do not have permission to access this resource.")
    {
    }
}
