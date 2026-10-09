using Domain.Common;

namespace Domain.Entities;

public class Bay : AuditableEntity
{
    private Bay() { }

    public Bay(Guid stationId, string name)
    {
        StationId = stationId;
        Name = name;
    }

    public Guid Id { get; private set; }
    public Guid StationId { get; private set; }
    public Station Station { get; private set; } = null!;
    public string Name { get; private set; } = null!;

    public void UpdateName(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Bay name is required.", nameof(name));
        Name = name.Trim();
    }
}
