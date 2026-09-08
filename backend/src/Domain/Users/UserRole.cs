namespace Domain.Users;

/// <summary>
/// System roles as defined by the SRS (§2.3, §4.2 "Users.Role").
/// Enum member names match the persisted string values exactly.
/// </summary>
public enum UserRole
{
    /// <summary>Primary mobile-app user: registers vehicles, reserves slots, tracks sessions.</summary>
    Driver,

    /// <summary>Manages their own stations and chargers via the web portal.</summary>
    StationOwner,

    /// <summary>Platform Administrator with full administrative access.</summary>
    Admin,

    /// <summary>Customer Support Manager: handles tickets, session and payment disputes.</summary>
    SupportManager
}
