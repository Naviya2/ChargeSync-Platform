using Domain.Common;

namespace Domain.Users;

/// <summary>
/// A system account, shared across all four functions (SRS §4.2 "Users").
/// Passwords are never held here in plain text — only a pre-computed hash.
/// </summary>
public class User : AuditableEntity
{
    private User()
    {
        // Required by EF Core.
    }

    private User(string fullName, string email, string passwordHash, UserRole role, string? phoneNumber)
    {
        FullName = fullName;
        Email = email;
        PasswordHash = passwordHash;
        Role = role;
        PhoneNumber = phoneNumber;
        IsActive = true;
    }

    /// <summary>Unique user identifier. Assigned by the database (<c>gen_random_uuid()</c>).</summary>
    public Guid Id { get; private set; }

    public string FullName { get; private set; } = null!;

    /// <summary>Login email address. Stored normalised (trimmed, lower-cased); unique.</summary>
    public string Email { get; private set; } = null!;

    /// <summary>Secure (bcrypt) password hash. Never the plain-text password.</summary>
    public string PasswordHash { get; private set; } = null!;

    public UserRole Role { get; private set; }

    public string? PhoneNumber { get; private set; }

    /// <summary>Account active/suspended flag. Suspended accounts cannot authenticate.</summary>
    public bool IsActive { get; private set; }

    /// <summary>
    /// Creates a new active user. <paramref name="passwordHash"/> must already be hashed.
    /// </summary>
    public static User Create(
        string fullName,
        string email,
        string passwordHash,
        UserRole role,
        string? phoneNumber = null)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.", nameof(fullName));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));
        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new ArgumentException("Password hash is required.", nameof(passwordHash));

        return new User(
            fullName.Trim(),
            NormaliseEmail(email),
            passwordHash,
            role,
            NormalisePhone(phoneNumber));
    }

    /// <summary>Replaces the stored password hash (already-hashed value).</summary>
    public void SetPasswordHash(string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new ArgumentException("Password hash is required.", nameof(passwordHash));

        PasswordHash = passwordHash;
    }

    /// <summary>Updates editable profile fields.</summary>
    public void UpdateProfile(string fullName, string? phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.", nameof(fullName));

        FullName = fullName.Trim();
        PhoneNumber = NormalisePhone(phoneNumber);
    }

    public void ChangeRole(UserRole role) => Role = role;

    public void Activate() => IsActive = true;

    public void Deactivate() => IsActive = false;

    private static string NormaliseEmail(string email) => email.Trim().ToLowerInvariant();

    private static string? NormalisePhone(string? phoneNumber) =>
        string.IsNullOrWhiteSpace(phoneNumber) ? null : phoneNumber.Trim();
}
