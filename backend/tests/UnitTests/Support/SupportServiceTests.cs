using Application.Common.Exceptions;
using Application.Support;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace UnitTests.Support;

public sealed class SupportServiceTests : IDisposable
{
    private readonly AppDbContext db = new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
    private SupportService Service => new(db);
    public void Dispose() => db.Dispose();
    private async Task<User> User(UserRole role)
    {
        var user = Domain.Users.User.Create(role.ToString(), $"{Guid.NewGuid()}@test.com", "hash", role);
        db.Users.Add(user); await db.SaveChangesAsync(); return user;
    }
    private static CreateTicketRequest General() => new("Technical", "App cannot refresh", "The application cannot refresh my charging information.");

    [Fact]
    public async Task DriverCreatesReadsRepliesAndWithdrawsOwnOpenTicket()
    {
        var driver = await User(UserRole.Driver);
        var created = await Service.CreateAsync(driver.Id, General(), default);
        Assert.Equal("Medium", created.Priority); Assert.Equal("Open", created.Status); Assert.Single(created.Messages);
        var run = Assert.Single(db.AgentWorkflowRuns);
        Assert.Equal(created.Id, run.TicketId);
        Assert.Equal(driver.Id, run.DriverId);
        Assert.Equal(Domain.Support.AgentWorkflowStatus.Running, run.Status);
        var replied = await Service.AddMessageAsync(driver.Id, UserRole.Driver, created.Id, "Extra diagnostic information", default);
        Assert.Equal(2, replied.Messages.Count);
        var withdrawn = await Service.WithdrawAsync(driver.Id, created.Id, default);
        Assert.Equal("Withdrawn", withdrawn.Status);
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.AddMessageAsync(driver.Id, UserRole.Driver, created.Id, "late", default));
    }

    [Fact]
    public async Task DriverCannotReadOrWithdrawAnotherDriversTicket()
    {
        var owner = await User(UserRole.Driver); var other = await User(UserRole.Driver);
        var ticket = await Service.CreateAsync(owner.Id, General(), default);
        await Assert.ThrowsAsync<ForbiddenAccessException>(() => Service.GetAsync(other.Id, UserRole.Driver, ticket.Id, default));
        await Assert.ThrowsAsync<NotFoundException>(() => Service.WithdrawAsync(other.Id, ticket.Id, default));
    }

    [Fact]
    public async Task SupportAssignmentReplyAndStatusAreAudited()
    {
        var driver = await User(UserRole.Driver); var support = await User(UserRole.SupportManager);
        var ticket = await Service.CreateAsync(driver.Id, General(), default);
        var assigned = await Service.AssignAsync(support.Id, UserRole.SupportManager, ticket.Id, support.Id, default);
        Assert.Equal(support.Id, assigned.AssignedToUserId);
        var replied = await Service.AddMessageAsync(support.Id, UserRole.SupportManager, ticket.Id, "We are investigating this issue.", default);
        Assert.Equal("InProgress", replied.Status);
        var resolved = await Service.SetStatusAsync(support.Id, UserRole.SupportManager, ticket.Id, "Resolved", default);
        Assert.Equal("Resolved", resolved.Status); Assert.Contains(resolved.Messages, m => m.IsSystem && m.Body.Contains("Resolved"));
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.WithdrawAsync(driver.Id, ticket.Id, default));
    }

    [Fact]
    public async Task RefundReferencesOwnPaidInvoiceAndApprovalCreditsExactlyOnce()
    {
        var driver = await User(UserRole.Driver); var support = await User(UserRole.SupportManager);
        var reservation = Reservation.Create(driver.Id, Guid.NewGuid(), DateTimeOffset.UtcNow.AddMinutes(1), DateTimeOffset.UtcNow.AddHours(1), 0);
        reservation.ConfirmWithQrCode("qr"); reservation.CheckIn();
        var session = ChargingSession.Start(reservation, driver.Id, DateTimeOffset.UtcNow.AddHours(-1)); session.Stop(DateTimeOffset.UtcNow, 100, 100);
        var invoice = PaymentInvoice.Issue(session, driver.Id, 100, 0); invoice.Settle(PaymentMethod.Wallet);
        db.Reservations.Add(reservation); db.ChargingSessions.Add(session); db.PaymentInvoices.Add(invoice); await db.SaveChangesAsync();
        var loyalty = new Domain.Loyalty.LoyaltyAccount { DriverId = driver.Id };
        loyalty.Earn(100); db.LoyaltyAccounts.Add(loyalty);
        db.LoyaltyEntries.Add(new Domain.Loyalty.LoyaltyEntry { DriverId = driver.Id, InvoiceId = invoice.Id, Points = 100, Reason = "Paid charging invoice" });
        await db.SaveChangesAsync();
        var ticket = await Service.CreateAsync(driver.Id, new("Refund", "Incorrect charging bill", "Please review this paid charging invoice.", invoice.Id, 6000), default);
        Assert.Equal("Urgent", ticket.Priority); Assert.Equal("PendingReview", ticket.RefundStatus);
        await Assert.ThrowsAsync<PaymentConflictException>(() => Service.CreateAsync(driver.Id, new("Refund", "Duplicate refund request", "Please review this paid charging invoice again.", invoice.Id, 100), default));
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.SetStatusAsync(support.Id, UserRole.SupportManager, ticket.Id, "Resolved", default));
        var approved = await Service.ReviewRefundAsync(support.Id, UserRole.SupportManager, ticket.Id, new(true, "Invoice verified"), default);
        Assert.Equal("Approved", approved.RefundStatus); Assert.Equal(6000, driver.WalletBalance);
        Assert.Equal(6000, invoice.RefundedAmount);
        Assert.Equal(40, loyalty.PointsBalance); Assert.Equal(40, loyalty.LifetimePoints);
        Assert.Contains(db.LoyaltyEntries, e => e.Points == -60 && e.Reason.Contains(ticket.Id.ToString()));
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.ReviewRefundAsync(support.Id, UserRole.SupportManager, ticket.Id, new(true, null), default));
        Assert.Equal(6000, driver.WalletBalance);
        Assert.Equal(6000, invoice.RefundedAmount); Assert.Equal(40, loyalty.PointsBalance);
    }

    [Fact]
    public async Task RefundCannotExceedPaidInvoiceOrUseAnotherDriversInvoice()
    {
        var owner = await User(UserRole.Driver); var other = await User(UserRole.Driver);
        var reservation = Reservation.Create(owner.Id, Guid.NewGuid(), DateTimeOffset.UtcNow.AddMinutes(1), DateTimeOffset.UtcNow.AddHours(1), 0);
        reservation.ConfirmWithQrCode("qr"); reservation.CheckIn(); var session = ChargingSession.Start(reservation, owner.Id, DateTimeOffset.UtcNow.AddHours(-1)); session.Stop(DateTimeOffset.UtcNow, 50, 10);
        var invoice = PaymentInvoice.Issue(session, owner.Id, 100, 0); invoice.Settle(PaymentMethod.Cash);
        db.Reservations.Add(reservation); db.ChargingSessions.Add(session); db.PaymentInvoices.Add(invoice); await db.SaveChangesAsync();
        await Assert.ThrowsAsync<ArgumentException>(() => Service.CreateAsync(owner.Id, new("Refund", "Refund this payment", "The requested amount is too large.", invoice.Id, 1001), default));
        await Assert.ThrowsAsync<NotFoundException>(() => Service.CreateAsync(other.Id, new("Refund", "Refund this payment", "This invoice belongs to another driver.", invoice.Id, 100), default));
    }

    [Fact]
    public async Task SpentLoyaltyPreventsRefundWithoutChangingWalletInvoiceOrApproval()
    {
        var driver = await User(UserRole.Driver); var support = await User(UserRole.SupportManager);
        var reservation = Reservation.Create(driver.Id, Guid.NewGuid(), DateTimeOffset.UtcNow.AddMinutes(1), DateTimeOffset.UtcNow.AddHours(1), 0);
        reservation.ConfirmWithQrCode("qr"); reservation.CheckIn();
        var start = DateTimeOffset.UtcNow.AddHours(-1);
        var session = ChargingSession.Start(reservation, support.Id, start); session.Stop(start.AddHours(1), 10, null);
        var invoice = PaymentInvoice.Issue(session, driver.Id, 100, 0); invoice.Settle(PaymentMethod.Wallet);
        var account = new Domain.Loyalty.LoyaltyAccount { DriverId = driver.Id }; account.Earn(10); account.Spend(10);
        db.Reservations.Add(reservation); db.ChargingSessions.Add(session); db.PaymentInvoices.Add(invoice); db.LoyaltyAccounts.Add(account);
        db.LoyaltyEntries.Add(new Domain.Loyalty.LoyaltyEntry { DriverId = driver.Id, Invoice = invoice, Points = 10 });
        await db.SaveChangesAsync();
        var ticket = await Service.CreateAsync(driver.Id, new("Refund", "Invoice refund request", "Please refund this incorrect invoice.", invoice.Id, 1000), default);
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.ReviewRefundAsync(support.Id, UserRole.SupportManager, ticket.Id, new(true, null), default));
        Assert.Equal(0, driver.WalletBalance); Assert.Equal(0, invoice.RefundedAmount);
        Assert.Equal("PendingReview", (await Service.GetAsync(support.Id, UserRole.SupportManager, ticket.Id, default)).RefundStatus);
        Assert.Single(db.LoyaltyEntries);
    }

    [Fact]
    public void InvoiceRefundCannotExceedRemainingAmountAndFullRefundUpdatesStatus()
    {
        var reservation = Reservation.CreateWalkIn(Guid.NewGuid(), DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddHours(1));
        var start = DateTimeOffset.UtcNow;
        var session = ChargingSession.Start(reservation, Guid.NewGuid(), start); session.Stop(start.AddHours(1), 10, null);
        var invoice = PaymentInvoice.Issue(session, null, 100, 0); invoice.Settle(PaymentMethod.Cash);
        invoice.Refund(400);
        Assert.Throws<InvalidOperationException>(() => invoice.Refund(601));
        Assert.Throws<InvalidOperationException>(() => invoice.Refund(.001m));
        invoice.Refund(600);
        Assert.Equal(InvoiceStatus.Refunded, invoice.Status); Assert.Equal(1000, invoice.RefundedAmount);
        Assert.Throws<InvalidOperationException>(() => invoice.Refund(1));
    }
}
