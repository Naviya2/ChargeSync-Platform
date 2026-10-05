using System.Globalization;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Users;
using Domain.Wallets;
using Microsoft.EntityFrameworkCore;

namespace Application.Wallets;

public sealed class WalletService(IAppDbContext db, IWalletGateway gateway)
{
    public async Task<object> Overview(Guid driverId, CancellationToken ct)
    {
        var user = await Driver(driverId, ct);
        var rows = await db.WalletTopUps.AsNoTracking().Where(t => t.DriverId == driverId)
            .OrderByDescending(t => t.CreatedAt).Take(50).ToListAsync(ct);
        return new { balance = user.WalletBalance, pendingCancellationFees = user.PendingCancellationFees,
            currency = "LKR", gatewayAvailable = gateway.Available,
            sandbox = gateway.Sandbox, minimum = 100, maximum = 50000, topUps = rows.Select(ToDto) };
    }

    public async Task<WalletTopUp> Start(Guid driverId, StartTopUpRequest request, CancellationToken ct)
    {
        if (!gateway.Available) throw new InvalidOperationException("Wallet top-up is not configured yet. Contact the ChargeSync team.");
        await Driver(driverId, ct);
        if (request.RequestId == Guid.Empty || request.Amount < 100 || request.Amount > 50000 || decimal.Round(request.Amount, 2) != request.Amount)
            throw new ArgumentException("Enter LKR 100–50,000 with at most two decimal places and a request ID.");
        if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Address) || string.IsNullOrWhiteSpace(request.City))
            throw new ArgumentException("Phone, billing address and city are required.");
        var existing = await db.WalletTopUps.SingleOrDefaultAsync(t => t.DriverId == driverId && t.RequestId == request.RequestId, ct);
        if (existing != null)
        {
            if (existing.Amount != request.Amount) throw new PaymentConflictException("This request ID was already used for a different amount.");
            return existing;
        }
        var topUp = new WalletTopUp { DriverId = driverId, RequestId = request.RequestId, Amount = request.Amount,
            Sandbox = gateway.Sandbox, Phone = request.Phone.Trim(), Address = request.Address.Trim(), City = request.City.Trim() };
        db.WalletTopUps.Add(topUp);
        await Save(ct);
        return topUp;
    }

    public async Task<Dictionary<string, string>> Checkout(Guid id, CancellationToken ct)
    {
        var topUp = await db.WalletTopUps.SingleOrDefaultAsync(t => t.Id == id, ct)
            ?? throw new ArgumentException("Top-up not found.");
        if (topUp.Status != "Pending" || topUp.CreatedAt < DateTimeOffset.UtcNow.AddMinutes(-30) || topUp.Sandbox != gateway.Sandbox)
            throw new InvalidOperationException("This checkout has finished or expired. Return to your wallet and start a new top-up.");
        return gateway.CheckoutFields(topUp, await Driver(topUp.DriverId, ct));
    }

    public async Task Notify(GatewayNotification notification, CancellationToken ct)
    {
        if (!gateway.Verify(notification)) throw new ForbiddenAccessException("Invalid payment notification.");
        if (!Guid.TryParseExact(notification.OrderId, "N", out var id)
            || !decimal.TryParse(notification.Amount, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out var amount))
            throw new ArgumentException("Invalid payment order or amount.");
        var topUp = await db.WalletTopUps.SingleOrDefaultAsync(t => t.Id == id, ct)
            ?? throw new ArgumentException("Unknown payment order.");
        if (amount != topUp.Amount || notification.Currency != topUp.Currency || topUp.Sandbox != gateway.Sandbox)
            throw new ArgumentException("Payment does not match the requested top-up.");
        if (notification.StatusCode == "2")
        {
            if (string.IsNullOrWhiteSpace(notification.PaymentId) || notification.PaymentId.Length > 100)
                throw new ArgumentException("Missing or invalid payment reference.");
            if (topUp.CreditedAt != null)
            {
                if (topUp.PaymentId != notification.PaymentId)
                    throw new PaymentConflictException("A second payment was received for an already credited order. Reconciliation is required.");
                return; // Verified duplicate delivery: no second credit.
            }
            if (topUp.Status == "ChargedBack") return; // Out-of-order success cannot restore a charged-back payment.
            if (await db.WalletTopUps.AnyAsync(t => t.PaymentId == notification.PaymentId && t.Id != id, ct))
                throw new PaymentConflictException("Payment reference was already credited.");
            // Do not drop a verified payment if the driver was deactivated after checkout.
            var user = await db.Users.SingleAsync(u => u.Id == topUp.DriverId, ct);
            user.CreditBalance(topUp.Amount);
            topUp.PaymentId = notification.PaymentId;
            topUp.CreditedAt = DateTimeOffset.UtcNow;
            topUp.Status = "Paid";
        }
        else if (topUp.CreditedAt == null)
        {
            topUp.Status = notification.StatusCode switch
            {
                "0" => topUp.Status,
                "-1" => "Cancelled",
                "-2" => "Failed",
                "-3" => "ChargedBack",
                _ => throw new ArgumentException("Unknown payment status.")
            };
        }
        else if (notification.StatusCode == "-3")
        {
            // Preserve the credited audit record; chargebacks require operator reconciliation.
            topUp.Status = "ChargebackReview";
        }
        else return; // Late pending/failure notifications cannot undo a successful payment.
        topUp.Version = Guid.NewGuid();
        // PostgreSQL commits the wallet change and payment receipt in one SaveChanges transaction.
        await Save(ct);
    }

    public static TopUpDto ToDto(WalletTopUp t) => new(t.Id, t.Amount, t.Currency, t.Status, t.Sandbox, t.CreatedAt, t.CreditedAt);
    private async Task<User> Driver(Guid id, CancellationToken ct) =>
        await db.Users.SingleOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Driver && u.IsActive, ct)
        ?? throw new ForbiddenAccessException("An active driver account is required.");
    private async Task Save(CancellationToken ct)
    {
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new PaymentConflictException("Wallet changed concurrently. Retry the request."); }
        catch (DbUpdateException ex) when (ex.InnerException?.GetType().GetProperty("SqlState")?.GetValue(ex.InnerException)?.ToString() == "23505")
        { throw new PaymentConflictException("Duplicate payment request. Refresh and retry."); }
    }
}
