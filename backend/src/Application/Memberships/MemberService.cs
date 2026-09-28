using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Domain.Entities;
using Domain.Enums;
using Domain.Loyalty;
using Domain.Memberships;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Memberships;

public sealed class MemberService(IAppDbContext db)
{
    public Task<List<MembershipPlan>> PlansAsync(CancellationToken ct) => db.MembershipPlans.AsNoTracking().Where(p => p.IsActive).OrderBy(p => p.MonthlyFee).ToListAsync(ct);
    public Task<List<Reward>> RewardsAsync(CancellationToken ct) => db.Rewards.AsNoTracking().Where(r => r.IsActive).OrderBy(r => r.PointsCost).ToListAsync(ct);

    public async Task<List<SubscriptionDto>> SubscriptionsAsync(Guid driverId, CancellationToken ct)
    {
        var rows = await db.Subscriptions.AsNoTracking().Include(s => s.Plan).Where(s => s.DriverId == driverId).OrderByDescending(s => s.StartDate).ToListAsync(ct);
        return rows.Select(ToDto).ToList();
    }

    public async Task<SubscriptionDto> SubscribeAsync(Guid driverId, Guid planId, Guid? changeId, CancellationToken ct)
    {
        var driver = await DriverAsync(driverId, ct);
        var plan = await db.MembershipPlans.FirstOrDefaultAsync(p => p.Id == planId && p.IsActive, ct)
            ?? throw new NotFoundException(nameof(MembershipPlan), planId);
        var now = DateTimeOffset.UtcNow;
        var rows = await db.Subscriptions.Include(s => s.Plan).Where(s => s.DriverId == driverId && (s.Status == "Active" || s.Status == "Cancelled")).ToListAsync(ct);
        foreach (var expired in rows.Where(s => s.EndDate <= now)) { expired.Status = "Expired"; expired.Version = Guid.NewGuid(); }
        var current = rows.SingleOrDefault(s => s.HasBenefits(now));
        if (changeId.HasValue && (current is null || current.Id != changeId))
            throw new InvalidOperationException("Only your current membership can be changed.");
        if (!changeId.HasValue && current is not null)
            throw new InvalidOperationException("You already have a membership. Use Change plan.");
        if (current?.PlanId == planId) throw new InvalidOperationException("You already have this plan.");
        var credit = current is null ? 0 : decimal.Round(current.FeePaid * (decimal)((current.EndDate - now).TotalSeconds / (current.EndDate - current.StartDate).TotalSeconds), 2);
        if (driver.WalletBalance + credit < plan.MonthlyFee)
            throw new InvalidOperationException("Insufficient wallet balance for this membership.");
        driver.CreditBalance(credit);
        driver.DeductBalance(plan.MonthlyFee);
        driver.TouchMembership();
        // Reuse the active row on a change; the old period is retained as history.
        if (current is not null)
        {
            db.Subscriptions.Add(new Subscription { DriverId = current.DriverId, PlanId = current.PlanId,
                StartDate = current.StartDate, EndDate = now, Status = "Changed", FeePaid = current.FeePaid,
                CreditApplied = current.CreditApplied, DiscountPercentage = current.DiscountPercentage });
        }
        var next = current ?? new Subscription { DriverId = driverId };
        next.PlanId = plan.Id; next.Plan = plan; next.StartDate = now; next.EndDate = now.AddDays(30);
        next.FeePaid = plan.MonthlyFee; next.CreditApplied = credit; next.DiscountPercentage = plan.DiscountPercentage;
        next.Status = "Active"; next.Version = Guid.NewGuid();
        if (current is null) db.Subscriptions.Add(next);
        await SaveAsync(ct);
        return ToDto(next);
    }

    public async Task<SubscriptionDto> CancelAsync(Guid driverId, Guid id, CancellationToken ct)
    {
        var row = await db.Subscriptions.Include(s => s.Plan).FirstOrDefaultAsync(s => s.Id == id && s.DriverId == driverId, ct)
            ?? throw new NotFoundException(nameof(Subscription), id);
        if (row.Status != "Active" || row.EndDate <= DateTimeOffset.UtcNow)
            throw new InvalidOperationException("Only an active membership can be cancelled.");
        row.Status = "Cancelled"; row.Version = Guid.NewGuid();
        (await DriverAsync(driverId, ct)).TouchMembership();
        await SaveAsync(ct);
        return ToDto(row);
    }

    public async Task<decimal> DiscountAsync(Guid driverId, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var planDiscount = await db.Subscriptions.Where(s => s.DriverId == driverId && s.EndDate > now && (s.Status == "Active" || s.Status == "Cancelled"))
            .Select(s => (decimal?)s.DiscountPercentage).FirstOrDefaultAsync(ct) ?? 0;
        var account = await db.LoyaltyAccounts.AsNoTracking().FirstOrDefaultAsync(a => a.DriverId == driverId, ct);
        var tierDiscount = account?.Tier == "Gold" ? 5m : account?.Tier == "Silver" ? 2m : 0m;
        return Math.Max(planDiscount, tierDiscount);
    }

    // Adds changes to the caller's transaction; never commits independently of payment.
    public async Task AwardAsync(PaymentInvoice invoice, CancellationToken ct)
    {
        if (invoice.Status != InvoiceStatus.Paid || invoice.DriverId is null || invoice.GrossAmount <= 0) return;
        if (await db.LoyaltyEntries.AnyAsync(e => e.InvoiceId == invoice.Id, ct)) return;
        var driver = await db.Users.FirstAsync(u => u.Id == invoice.DriverId, ct);
        if (driver.Role != UserRole.Driver) return;
        var account = await AccountAsync(driver.Id, ct);
        var points = checked((int)decimal.Floor((invoice.GrossAmount - invoice.DiscountAmount) / 100m));
        account.Earn(points);
        db.LoyaltyEntries.Add(new LoyaltyEntry { DriverId = driver.Id, Invoice = invoice, Points = points, Reason = "Paid charging invoice" });
    }

    public async Task<LoyaltyDto> BalanceAsync(Guid driverId, CancellationToken ct)
    {
        var a = await db.LoyaltyAccounts.AsNoTracking().FirstOrDefaultAsync(a => a.DriverId == driverId, ct);
        var wallet = await db.Users.Where(u => u.Id == driverId).Select(u => u.WalletBalance).FirstOrDefaultAsync(ct);
        return new(a?.PointsBalance ?? 0, a?.LifetimePoints ?? 0, a?.Tier ?? "Bronze",
            (a?.LifetimePoints ?? 0) < 1000 ? 1000 : (a?.LifetimePoints ?? 0) < 5000 ? 5000 : null, wallet);
    }
    public Task<List<LoyaltyEntry>> HistoryAsync(Guid driverId, CancellationToken ct) => db.LoyaltyEntries.AsNoTracking().Where(e => e.DriverId == driverId).OrderByDescending(e => e.CreatedAt).Take(100).ToListAsync(ct);
    public Task<List<RewardRedemption>> RedemptionsAsync(Guid? driverId, CancellationToken ct) => db.RewardRedemptions.AsNoTracking().Where(r => driverId == null || r.DriverId == driverId).OrderByDescending(r => r.CreatedAt).Take(100).ToListAsync(ct);

    public async Task<RewardRedemption> RedeemAsync(Guid driverId, RedeemRequest request, CancellationToken ct)
    {
        if (request.RequestId == Guid.Empty) throw new ArgumentException("A request ID is required.");
        var prior = await db.RewardRedemptions.FirstOrDefaultAsync(r => r.DriverId == driverId && r.RequestId == request.RequestId, ct);
        if (prior is not null)
        {
            if (prior.RewardId != request.RewardId) throw new InvalidOperationException("Request ID already used for a different reward.");
            return prior;
        }
        var driver = await DriverAsync(driverId, ct);
        var reward = await db.Rewards.FirstOrDefaultAsync(r => r.Id == request.RewardId && r.IsActive, ct)
            ?? throw new NotFoundException(nameof(Reward), request.RewardId);
        var account = await AccountAsync(driverId, ct);
        account.Spend(reward.PointsCost);
        var approval = reward.RequiresApproval || reward.PointsCost > 5000;
        var redemption = new RewardRedemption { DriverId = driverId, RewardId = reward.Id, RequestId = request.RequestId,
            RewardDescription = reward.Name, PointsRedeemed = reward.PointsCost, WalletCredit = reward.WalletCredit,
            Status = approval ? "Pending" : "Approved" };
        if (!approval) driver.CreditBalance(reward.WalletCredit);
        db.RewardRedemptions.Add(redemption);
        db.LoyaltyEntries.Add(new LoyaltyEntry { DriverId = driverId, RedemptionId = redemption.Id,
            Points = -reward.PointsCost, Reason = approval ? "Points reserved for approval" : "Reward redeemed" });
        await SaveAsync(ct);
        return redemption;
    }

    public async Task<RewardRedemption> ReviewAsync(Guid adminId, Guid id, bool approve, CancellationToken ct)
    {
        var r = await db.RewardRedemptions.FirstOrDefaultAsync(r => r.Id == id, ct) ?? throw new NotFoundException(nameof(RewardRedemption), id);
        if (r.Status != "Pending") throw new InvalidOperationException("This redemption has already been reviewed.");
        r.Status = approve ? "Approved" : "Rejected"; r.ReviewedBy = adminId; r.ReviewedAt = DateTimeOffset.UtcNow;
        if (approve) (await DriverAsync(r.DriverId, ct)).CreditBalance(r.WalletCredit);
        else
        {
            (await AccountAsync(r.DriverId, ct)).Release(r.PointsRedeemed);
            db.LoyaltyEntries.Add(new LoyaltyEntry { DriverId = r.DriverId, RedemptionId = r.Id, Points = r.PointsRedeemed, Reason = "Rejected reward: points released" });
        }
        await SaveAsync(ct);
        return r;
    }

    private async Task<LoyaltyAccount> AccountAsync(Guid driverId, CancellationToken ct)
    {
        var account = await db.LoyaltyAccounts.FindAsync(new object[] { driverId }, ct);
        if (account is not null) return account;
        account = new LoyaltyAccount { DriverId = driverId }; db.LoyaltyAccounts.Add(account); return account;
    }
    private async Task<User> DriverAsync(Guid id, CancellationToken ct) =>
        await db.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == UserRole.Driver && u.IsActive, ct)
        ?? throw new ForbiddenAccessException();
    private async Task SaveAsync(CancellationToken ct)
    {
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw new MembershipConflictException(); }
        catch (DbUpdateException e) when (e.InnerException?.GetType().GetProperty("SqlState")?.GetValue(e.InnerException)?.ToString() == "23505") { throw new MembershipConflictException(); }
    }
    private static SubscriptionDto ToDto(Subscription s) => new(s.Id, s.PlanId, s.Plan.Name,
        s.EndDate <= DateTimeOffset.UtcNow && s.Status is "Active" or "Cancelled" ? "Expired" : s.Status,
        s.StartDate, s.EndDate, s.FeePaid, s.CreditApplied, s.DiscountPercentage);
}
