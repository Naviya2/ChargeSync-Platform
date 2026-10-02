using Domain.Entities;
using Domain.Enums;

namespace UnitTests.Payments;

public sealed class PaymentInvoiceTests
{
    [Fact]
    public void Issue_CalculatesGrossDepositAndNetAmount()
    {
        var session = CompletedSession(12.5m);

        var invoice = PaymentInvoice.Issue(session, Guid.NewGuid(), 40m, 100m);

        Assert.Equal(40m, invoice.TariffPerKwh);
        Assert.Equal(500m, invoice.GrossAmount);
        Assert.Equal(100m, invoice.AdvanceDeducted);
        Assert.Equal(400m, invoice.NetAmountDue);
        Assert.Equal(InvoiceStatus.Pending, invoice.Status);
        Assert.Null(invoice.PaymentMethod);
    }

    [Fact]
    public void Issue_MarksFullyCoveredInvoicePaid_AndCapsAppliedDeposit()
    {
        var session = CompletedSession(2m);

        var invoice = PaymentInvoice.Issue(session, Guid.NewGuid(), 40m, 100m);

        Assert.Equal(80m, invoice.GrossAmount);
        Assert.Equal(80m, invoice.AdvanceDeducted);
        Assert.Equal(0m, invoice.NetAmountDue);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);
        Assert.Equal(PaymentMethod.Wallet, invoice.PaymentMethod);
    }

    [Fact]
    public void Settle_RejectsWalletForWalkInAndDuplicateSettlement()
    {
        var invoice = PaymentInvoice.Issue(CompletedSession(5m), null, 40m, 0m);

        Assert.Throws<InvalidOperationException>(() => invoice.Settle(PaymentMethod.Wallet));

        invoice.Settle(PaymentMethod.Cash);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);
        Assert.Throws<InvalidOperationException>(() => invoice.Settle(PaymentMethod.Cash));
    }

    private static ChargingSession CompletedSession(decimal deliveredKwh)
    {
        var reservation = Reservation.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            DateTimeOffset.UtcNow.AddMinutes(1),
            DateTimeOffset.UtcNow.AddHours(1),
            0m);
        reservation.ConfirmWithQrCode(Guid.NewGuid().ToString("N"));
        reservation.CheckIn();

        var start = DateTimeOffset.UtcNow.AddHours(-1);
        var session = ChargingSession.Start(reservation, Guid.NewGuid(), start);
        session.Stop(DateTimeOffset.UtcNow, 50m, deliveredKwh);
        return session;
    }
}
