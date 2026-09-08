namespace Domain.Common;

/// <summary>
/// Base type for entities that carry creation and modification timestamps.
/// Every table in the SRS data dictionary (§4.2) has <c>CreatedAt</c> / <c>UpdatedAt</c>.
/// The values are maintained by the persistence layer, not the domain.
/// </summary>
public abstract class AuditableEntity
{
    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }
}
