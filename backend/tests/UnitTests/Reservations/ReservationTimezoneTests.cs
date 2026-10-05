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

    [Fact]
    public void Create_Beyond7DaysInAdvance_ThrowsArgumentException()
    {
        var start = new DateTimeOffset(DateTime.UtcNow.Date.AddDays(7).AddHours(1), TimeSpan.Zero);
        var end = start.AddHours(1);

        var ex = Assert.Throws<ArgumentException>(() =>
            Reservation.Create(Guid.NewGuid(), Guid.NewGuid(), start, end, 10m));

        Assert.Contains("Reservations can only be made up to 7 days in advance.", ex.Message);
    }

    [Fact]
    public void Create_Within7DaysInAdvance_Succeeds()
    {
        var start = new DateTimeOffset(DateTime.UtcNow.Date.AddDays(5).AddHours(10), TimeSpan.Zero);
        var end = start.AddHours(1);

        var reservation = Reservation.Create(Guid.NewGuid(), Guid.NewGuid(), start, end, 10m);

        Assert.NotNull(reservation);
        Assert.Equal(start.UtcDateTime, reservation.StartTime.UtcDateTime);
    }

    [Fact]
    public void Create_InThePast_ThrowsArgumentException()
    {
        var start = DateTimeOffset.UtcNow.AddHours(-1);
        var end = start.AddHours(1);

        var ex = Assert.Throws<ArgumentException>(() =>
            Reservation.Create(Guid.NewGuid(), Guid.NewGuid(), start, end, 10m));

        Assert.Contains("Reservation cannot be scheduled in the past.", ex.Message);
    }
}

