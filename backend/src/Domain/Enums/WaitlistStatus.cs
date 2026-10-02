namespace Domain.Enums;

/// <summary>
/// Lifecycle states for a <see cref="Domain.Entities.WaitlistEntry"/> record (SRS §4.2 WaitlistEntries).
/// </summary>
public enum WaitlistStatus
{
    /// <summary>Driver is queued; no slot available yet.</summary>
    Waiting,

    /// <summary>A slot opened and this entry was automatically promoted to a reservation.</summary>
    Promoted,

    /// <summary>The requested time window has passed without promotion.</summary>
    Expired
}
