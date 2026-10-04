using Application.Common.Interfaces;
using Application.Payments.Models;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Application.Payments;

public sealed class DriverPaymentHistoryService(IAppDbContext db)
{
    public async Task<IReadOnlyList<DriverPaymentHistoryItemDto>> GetAsync(Guid driverId, CancellationToken ct = default)
    {
        var items = new List<DriverPaymentHistoryItemDto>();

        var reservations = await db.Reservations.AsNoTracking()
            .Where(r => r.DriverId == driverId).ToListAsync(ct);
        foreach (var reservation in reservations)
        {
            if (reservation.AdvanceDepositAmount > 0)
                items.Add(new(reservation.Id, "ReservationAdvance", "Reservation advance", reservation.AdvanceDepositAmount,
                    "Out", reservation.CreatedAt, "Wallet"));
            if (reservation.CancellationFeesPaid > 0)
                items.Add(new(reservation.Id, "CancellationFee", "Previous late cancellation fees", reservation.CancellationFeesPaid,
                    "Out", reservation.CreatedAt, "Wallet"));
            if (reservation.Status == ReservationStatus.Cancelled && reservation.CancelledAt is { } cancelledAt && reservation.AdvanceDepositAmount > 0)
                items.Add(new(reservation.Id, "AdvanceRefund", "Cancelled reservation advance refund", reservation.AdvanceDepositAmount,
                    "In", cancelledAt, "Wallet"));
        }

        var invoices = await db.PaymentInvoices.AsNoTracking()
            .Include(i => i.Session).ThenInclude(s => s.Reservation)
            .Where(i => i.DriverId == driverId).ToListAsync(ct);
        foreach (var invoice in invoices)
        {
            if (invoice.Status is InvoiceStatus.Paid or InvoiceStatus.Refunded && invoice.NetAmountDue > 0 && invoice.SettledAt is { } settledAt)
                items.Add(new(invoice.Id, "ChargingPayment", "Charging balance after advance", invoice.NetAmountDue,
                    "Out", settledAt, invoice.PaymentMethod?.ToString() ?? "Wallet"));
            var excessAdvance = invoice.Session.Reservation.AdvanceDepositAmount - invoice.AdvanceDeducted;
            if (excessAdvance > 0)
                items.Add(new(invoice.Id, "AdvanceRefund", "Unused reservation advance returned", excessAdvance,
                    "In", invoice.IssuedAt, "Wallet"));
            if (invoice.RefundedAmount > 0)
                items.Add(new(invoice.Id, "ChargingRefund", "Charging refund (total recorded)", invoice.RefundedAmount,
                    "In", invoice.UpdatedAt, "Wallet"));
        }

        var subscriptions = await db.Subscriptions.AsNoTracking().Include(s => s.Plan)
            .Where(s => s.DriverId == driverId).ToListAsync(ct);
        foreach (var subscription in subscriptions)
        {
            if (subscription.CreditApplied > 0)
                items.Add(new(subscription.Id, "MembershipCredit", $"Unused membership credit toward {subscription.Plan.Name}",
                    subscription.CreditApplied, "In", subscription.StartDate, "Wallet"));
            if (subscription.FeePaid > 0)
                items.Add(new(subscription.Id, "MembershipPayment", $"{subscription.Plan.Name} membership", subscription.FeePaid,
                    "Out", subscription.StartDate, "Wallet"));
        }

        var topUps = await db.WalletTopUps.AsNoTracking()
            .Where(t => t.DriverId == driverId && t.Status == "Paid" && t.CreditedAt != null).ToListAsync(ct);
        items.AddRange(topUps.Select(topUp => new DriverPaymentHistoryItemDto(topUp.Id, "WalletTopUp", "Wallet top-up",
            topUp.Amount, "In", topUp.CreditedAt!.Value, "PayHere")));

        var rewards = await db.RewardRedemptions.AsNoTracking()
            .Where(r => r.DriverId == driverId && r.Status == "Approved" && r.WalletCredit > 0).ToListAsync(ct);
        items.AddRange(rewards.Select(reward => new DriverPaymentHistoryItemDto(reward.Id, "RewardCredit",
            $"Reward: {reward.RewardDescription}", reward.WalletCredit, "In",
            reward.ReviewedAt ?? reward.CreatedAt, "Wallet")));

        return items.OrderByDescending(item => item.OccurredAt)
            .ThenBy(item => item.Type).ThenBy(item => item.ReferenceId).ToList();
    }
}
