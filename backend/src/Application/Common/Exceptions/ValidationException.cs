namespace Application.Common.Exceptions;

/// <summary>
/// Thrown when a request fails input validation. Carries a field → messages map
/// that the API layer renders as an RFC 7807 problem-details response (400).
/// </summary>
public sealed class ValidationException : Exception
{
    public ValidationException(IReadOnlyDictionary<string, string[]> errors)
        : base("One or more validation errors occurred.")
    {
        Errors = errors;
    }

    public IReadOnlyDictionary<string, string[]> Errors { get; }
}
