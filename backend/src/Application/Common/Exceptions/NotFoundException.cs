namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when a requested resource does not exist. The API layer maps this to HTTP 404.
/// </summary>
public sealed class NotFoundException : Exception
{
    public NotFoundException(string resource, object key)
        : base($"{resource} '{key}' was not found.")
    {
    }
}
