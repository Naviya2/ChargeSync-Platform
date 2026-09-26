
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

    private User(string fullName, string email, string? passwordHash, string authProvider, UserRole role, string? phoneNumber)
    {
        FullName = fullName;
        Email = email;
        PasswordHash = passwordHash;
        AuthProvider = authProvider;
        Role = role;
        PhoneNumber = phoneNumber;
        IsActive = true;
    }

    /// <summary>Unique user identifier. Assigned by the database (<c>gen_random_uuid()</c>).</summary>
    public Guid Id { get; private set; }

    public string FullName { get; private set; } = null!;

    /// <summary>Login email address. Stored normalised (trimmed, lower-cased); unique.</summary>
    public string Email { get; private set; } = null!;

    /// <summary>Secure (bcrypt) password hash. Null if using third-party auth.</summary>
    public string? PasswordHash { get; private set; }

    /// <summary>Authentication provider (e.g., "Local", "Google").</summary>
    public string AuthProvider { get; private set; } = "Local";

    public UserRole Role { get; private set; }

    public string? PhoneNumber { get; private set; }

    /// <summary>Account active/suspended flag. Suspended accounts cannot authenticate.</summary>
    public bool IsActive { get; private set; }

    /// <summary>Prepaid wallet balance used for advance reservation deposits.</summary>
    public decimal WalletBalance { get; private set; }

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
            "Local",
            role,
            NormalisePhone(phoneNumber));
    }

    /// <summary>
    /// Creates a new user authenticated via Google (no password).
    /// </summary>
    public static User CreateGoogleUser(
        string fullName,
        string email,
        UserRole role = UserRole.Driver)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.", nameof(fullName));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));

        return new User(
            fullName.Trim(),
            NormaliseEmail(email),
            null,
            "Google",
            role,
            null);
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

    /// <summary>
    /// Deducts the specified amount from the wallet balance.
    /// Throws if the balance would go negative.
    /// </summary>
    public void DeductBalance(decimal amount)
    {
        if (amount < 0)
            throw new ArgumentException("Deduction amount cannot be negative.", nameof(amount));
        if (WalletBalance < amount)
            throw new InvalidOperationException(
                $"Insufficient wallet balance. Available: {WalletBalance:C}, required: {amount:C}.");
        WalletBalance -= amount;
    }

    /// <summary>Credits the specified amount to the wallet balance (e.g. cancellation refund).</summary>
    public void CreditBalance(decimal amount)
    {
        if (amount < 0)
            throw new ArgumentException("Credit amount cannot be negative.", nameof(amount));
        WalletBalance += amount;
    }

    private static string NormaliseEmail(string email) => email.Trim().ToLowerInvariant();

    private static string? NormalisePhone(string? phoneNumber) =>
        string.IsNullOrWhiteSpace(phoneNumber) ? null : phoneNumber.Trim();
}
