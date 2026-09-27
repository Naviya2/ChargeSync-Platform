using Domain.Entities;

namespace UnitTests.Reservations;

public sealed class ReservationTimezoneTests
{
    [Fact]
    public void WalkIn_NormalizesLocalOffsetForPostgresWithoutChangingInstant()
    {
        var start = DateTimeOffset.UtcNow.AddMinutes(1).ToOffset(TimeSpan.FromHours(5.5));
        var end = start.AddHours(1);
        var reservation = Reservation.CreateWalkIn(Guid.NewGuid(), start, end);

        Assert.Equal(TimeSpan.Zero, reservation.StartTime.Offset);
        Assert.Equal(TimeSpan.Zero, reservation.EndTime.Offset);
        Assert.Equal(start.UtcDateTime, reservation.StartTime.UtcDateTime);
        Assert.Equal(end.UtcDateTime, reservation.EndTime.UtcDateTime);
        Assert.Null(reservation.DriverId);
    }
}
