using Domain.Common;

namespace Domain.Entities;

public class OperatingHour : AuditableEntity
{
    private OperatingHour() { }

    private OperatingHour(Guid stationId, int dayOfWeek, bool isEnabled, TimeSpan openTime, TimeSpan closeTime)
    {
        StationId = stationId;
        DayOfWeek = dayOfWeek;
        IsEnabled = isEnabled;
        OpenTime = openTime;
        CloseTime = closeTime;
    }

    public Guid Id { get; private set; }
    public Guid StationId { get; private set; }
    
    public int DayOfWeek { get; private set; }
    public bool IsEnabled { get; private set; }
    public TimeSpan OpenTime { get; private set; }
    public TimeSpan CloseTime { get; private set; }

    public Station Station { get; private set; } = null!;

    public static OperatingHour Create(Guid stationId, int dayOfWeek, bool isEnabled, TimeSpan openTime, TimeSpan closeTime)
    {
        if (dayOfWeek < 0 || dayOfWeek > 6)
            throw new ArgumentException("Day of week must be between 0 and 6.", nameof(dayOfWeek));

        if (isEnabled && openTime >= closeTime)
            throw new ArgumentException("Open time must be before close time.", nameof(openTime));

        return new OperatingHour(stationId, dayOfWeek, isEnabled, openTime, closeTime);
    }

    public void Update(bool isEnabled, TimeSpan openTime, TimeSpan closeTime)
    {
        if (isEnabled && openTime >= closeTime)
            throw new ArgumentException("Open time must be before close time.", nameof(openTime));

        IsEnabled = isEnabled;
        OpenTime = openTime;
        CloseTime = closeTime;
    }
}
