using Domain.Common;

namespace Domain.Entities;

public class MaintenanceWindow : AuditableEntity
{
    private MaintenanceWindow() { }

    private MaintenanceWindow(Guid chargerId, string title, string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        ChargerId = chargerId;
        Title = title;
        Reason = reason;
        StartTime = startTime;
        EndTime = endTime;
    }

    public Guid Id { get; private set; }
    public Guid ChargerId { get; private set; }
    public string Title { get; private set; } = null!;
    public string Reason { get; private set; } = null!;
    public DateTimeOffset StartTime { get; private set; }
    public DateTimeOffset EndTime { get; private set; }

    public Charger Charger { get; private set; } = null!;

    public static MaintenanceWindow Create(Guid chargerId, string title, string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title is required.", nameof(title));
        
        if (startTime >= endTime)
            throw new ArgumentException("Start time must be before end time.", nameof(startTime));

        return new MaintenanceWindow(chargerId, title.Trim(), reason?.Trim() ?? string.Empty, startTime, endTime);
    }

    public void Update(string title, string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title is required.", nameof(title));
        
        if (startTime >= endTime)
            throw new ArgumentException("Start time must be before end time.", nameof(startTime));

        Title = title.Trim();
        Reason = reason?.Trim() ?? string.Empty;
        StartTime = startTime;
        EndTime = endTime;
    }
}
