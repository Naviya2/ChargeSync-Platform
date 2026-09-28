using System.Security.Cryptography;
using System.Text;
using Application.Common.Exceptions;
using Application.Wallets;
using Domain.Users;
using Infrastructure.Payments;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace UnitTests.Wallets;

public sealed class WalletServiceTests : IDisposable
{
    private readonly AppDbContext db = new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
    private readonly PayHereGateway gateway = new(Options.Create(new PayHereOptions { Enabled = true, Sandbox = true,
        MerchantId = "test-merchant", MerchantSecret = "test-secret", PublicBaseUrl = "https://test.example" }));
    private WalletService Service => new(db, gateway);
    public void Dispose() => db.Dispose();
    private async Task<User> Driver()
    {
        var user = User.Create("Wallet Driver", Guid.NewGuid() + "@test.com", "hash", UserRole.Driver);
        db.Users.Add(user); await db.SaveChangesAsync(); return user;
    }
    private static StartTopUpRequest Request(decimal amount = 1000) => new(Guid.NewGuid(), amount, "0771234567", "12 Test Road", "Colombo");
    private static GatewayNotification Notification(Guid id, string status = "2", string amount = "1000.00", string currency = "LKR", string? paymentId = null)
    {
        static string Hash(string v) => Convert.ToHexString(MD5.HashData(Encoding.UTF8.GetBytes(v)));
        return new("test-merchant", id.ToString("N"), paymentId ?? Guid.NewGuid().ToString(), amount, currency, status,
            Hash("test-merchant" + id.ToString("N") + amount + currency + status + Hash("test-secret")));
    }

    [Fact]
    public async Task VerifiedSuccess_CreditsOnce_AndLateFailureDoesNotUndoIt()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        Assert.Equal(0, driver.WalletBalance);
        var notification = Notification(order.Id);
        await Service.Notify(notification, default); await Service.Notify(notification, default);
        await Service.Notify(Notification(order.Id, "-2"), default);
        Assert.Equal(1000, driver.WalletBalance); Assert.Equal("Paid", order.Status);
        Assert.NotNull(order.CreditedAt); Assert.Equal(notification.PaymentId, order.PaymentId);
    }

    [Theory]
    [InlineData("999.00", "LKR")]
    [InlineData("1000.00", "USD")]
    public async Task SignedButMismatchedPayment_DoesNotCredit(string amount, string currency)
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Assert.ThrowsAsync<ArgumentException>(() => Service.Notify(Notification(order.Id, amount: amount, currency: currency), default));
        Assert.Equal(0, driver.WalletBalance);
    }

    [Fact]
    public async Task ForgedSignature_DoesNotCredit()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Assert.ThrowsAsync<ForbiddenAccessException>(() => Service.Notify(Notification(order.Id) with { Signature = new string('0', 32) }, default));
        Assert.Equal(0, driver.WalletBalance);
    }

    [Theory]
    [InlineData("0", "Pending")]
    [InlineData("-1", "Cancelled")]
    [InlineData("-2", "Failed")]
    public async Task UnsuccessfulPayment_NeverCredits(string status, string expected)
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Service.Notify(Notification(order.Id, status), default);
        Assert.Equal(0, driver.WalletBalance); Assert.Equal(expected, order.Status);
    }

    [Fact]
    public async Task Start_IsIdempotent_AndChangedAmountCannotReuseKey()
    {
        var driver = await Driver(); var request = Request();
        var first = await Service.Start(driver.Id, request, default);
        Assert.Equal(first.Id, (await Service.Start(driver.Id, request, default)).Id);
        await Assert.ThrowsAsync<PaymentConflictException>(() => Service.Start(driver.Id, request with { Amount = 2000 }, default));
        Assert.Single(await db.WalletTopUps.ToListAsync());
    }

    [Theory]
    [InlineData(0)]
    [InlineData(99)]
    [InlineData(50001)]
    [InlineData(100.001)]
    public async Task InvalidAmountsRejected(decimal amount)
    {
        var driver = await Driver();
        await Assert.ThrowsAsync<ArgumentException>(() => Service.Start(driver.Id, Request(amount), default));
        Assert.Empty(await db.WalletTopUps.ToListAsync());
    }

    [Fact]
    public async Task PaymentReferenceCannotCreditTwoOrders()
    {
        var driver = await Driver(); var first = await Service.Start(driver.Id, Request(), default);
        var second = await Service.Start(driver.Id, Request(), default);
        await Service.Notify(Notification(first.Id, paymentId: "same-payment"), default);
        await Assert.ThrowsAsync<PaymentConflictException>(() => Service.Notify(Notification(second.Id, paymentId: "same-payment"), default));
        Assert.Equal(1000, driver.WalletBalance);
    }

    [Fact]
    public async Task Checkout_UsesServerAmount_AndNeverExposesMerchantSecret()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        var fields = await Service.Checkout(order.Id, default);
        Assert.Equal("1000.00", fields["amount"]); Assert.Equal("LKR", fields["currency"]);
        Assert.DoesNotContain("test-secret", fields.Values);
        Assert.Equal(32, fields["hash"].Length);
        order.CreatedAt = DateTimeOffset.UtcNow.AddHours(-1);
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service.Checkout(order.Id, default));
    }

    [Fact]
    public async Task Chargeback_IsFlaggedWithoutSilentlyRemovingSpentFunds()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Service.Notify(Notification(order.Id), default);
        await Service.Notify(Notification(order.Id, "-3"), default);
        Assert.Equal("ChargebackReview", order.Status); Assert.Equal(1000, driver.WalletBalance);
        Assert.NotNull(order.CreditedAt);
    }

    [Fact]
    public async Task ChargebackBeforeSuccess_DoesNotCreditOutOfOrderSuccess()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Service.Notify(Notification(order.Id, "-3"), default);
        await Service.Notify(Notification(order.Id), default);
        Assert.Equal("ChargedBack", order.Status); Assert.Equal(0, driver.WalletBalance);
    }

    [Fact]
    public async Task DifferentPaymentOnPaidOrder_RequiresReconciliation()
    {
        var driver = await Driver(); var order = await Service.Start(driver.Id, Request(), default);
        await Service.Notify(Notification(order.Id), default);
        await Assert.ThrowsAsync<PaymentConflictException>(() => Service.Notify(Notification(order.Id), default));
        Assert.Equal(1000, driver.WalletBalance);
    }

    [Fact]
    public async Task MissingGatewayConfiguration_CannotCreateTopUp()
    {
        var driver = await Driver();
        var disabled = new WalletService(db, new PayHereGateway(Options.Create(new PayHereOptions())));
        await Assert.ThrowsAsync<InvalidOperationException>(() => disabled.Start(driver.Id, Request(), default));
        Assert.Empty(await db.WalletTopUps.ToListAsync());
    }
}
