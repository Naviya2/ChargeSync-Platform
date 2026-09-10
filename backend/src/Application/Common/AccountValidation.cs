using System.Net.Mail;

namespace Application.Common;

/// <summary>
/// Shared validation for the fields common to every account (registration and
/// admin-created users). Role rules are applied by each caller.
/// </summary>
internal static class AccountValidation
{
    public const int MinPasswordLength = 8;
    public const int MaxPasswordLength = 72; // bcrypt only considers the first 72 bytes

    public static void ValidateProfile(
        string? fullName,
        string? email,
        string? password,
        string? phoneNumber,
        Dictionary<string, string[]> errors)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            errors["FullName"] = ["Full name is required."];
        }
        else if (fullName.Trim().Length > 150)
        {
            errors["FullName"] = ["Full name must be 150 characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(email) || !MailAddress.TryCreate(email.Trim(), out _))
        {
            errors["Email"] = ["A valid email address is required."];
        }
        else if (email.Trim().Length > 150)
        {
            errors["Email"] = ["Email must be 150 characters or fewer."];
        }

        if (string.IsNullOrEmpty(password) || password.Length < MinPasswordLength)
        {
            errors["Password"] = [$"Password must be at least {MinPasswordLength} characters."];
        }
        else if (password.Length > MaxPasswordLength)
        {
            errors["Password"] = [$"Password must be {MaxPasswordLength} characters or fewer."];
        }

        if (!string.IsNullOrWhiteSpace(phoneNumber) && phoneNumber.Trim().Length > 20)
        {
            errors["PhoneNumber"] = ["Phone number must be 20 characters or fewer."];
        }
    }
}
