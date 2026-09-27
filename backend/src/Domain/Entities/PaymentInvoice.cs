using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

public sealed class PaymentInvoice : AuditableEntity
{
    private PaymentInvoice() { }

    private PaymentInvoice(
        ChargingSession session,
        Guid? driverId,
        decimal tariffPerKwh,
        decimal grossAmount,
        decimal advanceDeducted,
        decimal netAmountDue)
    {
        Session = session;
        SessionId = session.Id;
        DriverId = driverId;
        TariffPerKwh = tariffPerKwh;
        GrossAmount = grossAmount;
        AdvanceDeducted = advanceDeducted;
        NetAmountDue = netAmountDue;
        IssuedAt = DateTimeOffset.UtcNow;
        Status = InvoiceStatus.Pending;

        if (netAmountDue == 0)
        {
            PaymentMethod = driverId.HasValue ? Domain.Enums.PaymentMethod.Wallet : Domain.Enums.PaymentMethod.Cash;
            Status = InvoiceStatus.Paid;
            SettledAt = IssuedAt;
        }
    }

    public Guid Id { get; private set; }
    public Guid SessionId { get; private set; }
    public Guid? DriverId { get; private set; }
    public decimal TariffPerKwh { get; private set; }
    public decimal GrossAmount { get; private set; }
    public decimal AdvanceDeducted { get; private set; }
    public decimal NetAmountDue { get; private set; }
    public PaymentMethod? PaymentMethod { get; private set; }
    public InvoiceStatus Status { get; private set; }
    public DateTimeOffset IssuedAt { get; private set; }
    public DateTimeOffset? SettledAt { get; private set; }

    public ChargingSession Session { get; private set; } = null!;
    public User? Driver { get; private set; }

    public static PaymentInvoice Issue(
        ChargingSession session,
        Guid? driverId,
        decimal tariffPerKwh,
        decimal advanceDeposit)
    {
        ArgumentNullException.ThrowIfNull(session);
        if (session.Status == ChargingSessionStatus.InProgress || session.FinalEnergyDeliveredKwh is null)
            throw new InvalidOperationException("An invoice can only be issued after the session has stopped.");
        if (tariffPerKwh < 0)
            throw new ArgumentException("Tariff cannot be negative.", nameof(tariffPerKwh));
        if (advanceDeposit < 0)
            throw new ArgumentException("Advance deposit cannot be negative.", nameof(advanceDeposit));

        var gross = decimal.Round(
            session.FinalEnergyDeliveredKwh.Value * tariffPerKwh,
            2,
            MidpointRounding.AwayFromZero);
        var appliedAdvance = Math.Min(advanceDeposit, gross);
        var netDue = gross - appliedAdvance;

        return new PaymentInvoice(session, driverId, tariffPerKwh, gross, appliedAdvance, netDue);
    }

    public void Settle(PaymentMethod paymentMethod, DateTimeOffset? settledAt = null)
    {
        if (Status != InvoiceStatus.Pending)
            throw new InvalidOperationException("Only a pending invoice can be settled.");
        if (DriverId is null && paymentMethod != Domain.Enums.PaymentMethod.Cash)
            throw new InvalidOperationException("Walk-in invoices must be settled with cash.");

        PaymentMethod = paymentMethod;
        Status = InvoiceStatus.Paid;
        SettledAt = settledAt ?? DateTimeOffset.UtcNow;
    }
}
