namespace Domain.Entities;

public static class CancellationPolicy
{
    public const decimal LateFeeLkr = 500m;
    public static readonly TimeSpan FreeCancellationNotice = TimeSpan.FromHours(2);

    // Also covers a driver cancellation after the scheduled start, before check-in/timeout.
    public static decimal Fee(DateTimeOffset startTime, DateTimeOffset cancelledAt) =>
        startTime - cancelledAt < FreeCancellationNotice ? LateFeeLkr : 0m;
}
