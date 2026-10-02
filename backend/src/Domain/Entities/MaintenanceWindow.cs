using Domain.Common;

namespace Domain.Entities;

public class MaintenanceWindow : AuditableEntity
{
    private MaintenanceWindow() { }

    private MaintenanceWindow(Guid chargerId, string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        ChargerId = chargerId;
        Reason = reason;
        StartTime = startTime;
        EndTime = endTime;
    }

    public Guid Id { get; private set; }
    public Guid ChargerId { get; private set; }
    public string Reason { get; private set; } = null!;
    public DateTimeOffset StartTime { get; private set; }
    public DateTimeOffset EndTime { get; private set; }

    public Charger Charger { get; private set; } = null!;

    public static MaintenanceWindow Create(Guid chargerId, string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        if (startTime >= endTime)
            throw new ArgumentException("Start time must be before end time.", nameof(startTime));

        return new MaintenanceWindow(chargerId, reason?.Trim() ?? string.Empty, startTime.ToUniversalTime(), endTime.ToUniversalTime());
    }

    public void Update(string reason, DateTimeOffset startTime, DateTimeOffset endTime)
    {
        if (startTime >= endTime)
            throw new ArgumentException("Start time must be before end time.", nameof(startTime));

        Reason = reason?.Trim() ?? string.Empty;
        StartTime = startTime.ToUniversalTime();
        EndTime = endTime.ToUniversalTime();
    }
}
