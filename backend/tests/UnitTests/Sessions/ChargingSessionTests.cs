using Domain.Entities;
using Domain.Enums;

namespace UnitTests.Sessions;

public sealed class ChargingSessionTests
{
    [Fact]
    public void Stop_CalculatesEnergyAndCompletes_WhenOverrideIsWithinThreshold()
    {
        var start = DateTimeOffset.UtcNow;
        var reservation = CheckedInReservation();
        var session = ChargingSession.Start(reservation, Guid.NewGuid(), start);

        session.Stop(start.AddHours(1), 50m, 57.50m);

        Assert.Equal(50m, session.AutoCalculatedKwh);
        Assert.Equal(57.50m, session.FinalEnergyDeliveredKwh);
        Assert.Equal(ChargingSessionStatus.Completed, session.Status);
    }

    [Fact]
    public void Stop_FlagsDiscrepancy_WhenOverrideExceedsFifteenPercent()
    {
        var start = DateTimeOffset.UtcNow;
        var session = ChargingSession.Start(CheckedInReservation(), Guid.NewGuid(), start);

        session.Stop(start.AddHours(1), 50m, 57.51m);

        Assert.Equal(ChargingSessionStatus.DiscrepancyFlagged, session.Status);
    }

    [Fact]
    public void FlaggedMeterOverride_IsUsedForInvoiceWhileAutomaticEnergyIsPreserved()
    {
        var start = DateTimeOffset.UtcNow;
        var driverId = Guid.NewGuid();
        var session = ChargingSession.Start(CheckedInReservation(), Guid.NewGuid(), start);

        session.Stop(start.AddHours(1), 50m, 57.51m);
        var invoice = PaymentInvoice.Issue(session, driverId, 100m, 100m);

        Assert.Equal(ChargingSessionStatus.DiscrepancyFlagged, session.Status);
        Assert.Equal(50m, session.AutoCalculatedKwh);
        Assert.Equal(57.51m, session.StaffOverriddenKwh);
        Assert.Equal(57.51m, session.FinalEnergyDeliveredKwh);
        Assert.Equal(5751m, invoice.GrossAmount);
        Assert.Equal(100m, invoice.AdvanceDeducted);
        Assert.Equal(5651m, invoice.NetAmountDue);
        Assert.Equal(InvoiceStatus.Pending, invoice.Status);
    }

    [Fact]
    public void Stop_RejectsSecondStop()
    {
        var start = DateTimeOffset.UtcNow;
        var session = ChargingSession.Start(CheckedInReservation(), Guid.NewGuid(), start);
        session.Stop(start.AddHours(1), 50m, null);

        Assert.Throws<InvalidOperationException>(() =>
            session.Stop(start.AddHours(2), 50m, null));
    }

    private static Reservation CheckedInReservation()
    {
        var reservation = Reservation.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            DateTimeOffset.UtcNow.AddMinutes(1),
            DateTimeOffset.UtcNow.AddHours(1),
            0m);
        reservation.ConfirmWithQrCode(Guid.NewGuid().ToString("N"));
        reservation.CheckIn();
        return reservation;
    }
}
