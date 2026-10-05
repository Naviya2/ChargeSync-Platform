using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Application.Authentication.Models;
using Application.Payments.Models;
using Domain.Entities;
using Domain.Enums;
using Domain.Loyalty;
using Domain.Memberships;
using Domain.Users;
using Domain.Wallets;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class DriverPaymentHistoryEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly ChargeSyncApiFactory _factory;
    public DriverPaymentHistoryEndpointsTests(ChargeSyncApiFactory factory) => _factory = factory;

    [Fact]
    public async Task DriverSeesOnlyPostedOwnPaymentsAndCredits()
    {
        using var client = _factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/payments/history")).StatusCode);

        var registration = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "History Driver", email = $"history-{Guid.NewGuid()}@test.com",
            password = "password123", role = "Driver"
        });
        registration.EnsureSuccessStatusCode();
        var auth = (await registration.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var owner = User.Create("Owner", $"{Guid.NewGuid()}@test.com", "hash", UserRole.StationOwner);
            var other = User.Create("Other", $"{Guid.NewGuid()}@test.com", "hash", UserRole.Driver);
            db.Users.AddRange(owner, other);
            var station = Station.Create("History Station", "Address", 0, 0, owner.Id);
            db.Stations.Add(station);
            var charger = Charger.Create(station.Id, "CH1", "Bay", ConnectorType.CCS2, 20, 100);
            db.Chargers.Add(charger);
            await db.SaveChangesAsync();

            var start = DateTimeOffset.UtcNow.AddHours(4);
            var cancelled = Reservation.Create(auth.User.Id, charger.Id, start, start.AddMinutes(30), 500);
            cancelled.RecordCancellationFeesPaid(500);
            cancelled.ConfirmWithQrCode(Guid.NewGuid().ToString());
            cancelled.Cancel(cancelledAt: DateTimeOffset.UtcNow);
            var charged = Reservation.Create(auth.User.Id, charger.Id, start.AddHours(2), start.AddHours(3), 500);
            charged.ConfirmWithQrCode(Guid.NewGuid().ToString());
            charged.CheckIn();
            var covered = Reservation.Create(auth.User.Id, charger.Id, start.AddHours(6), start.AddHours(7), 500);
            covered.ConfirmWithQrCode(Guid.NewGuid().ToString());
            covered.CheckIn();
            var someoneElses = Reservation.Create(other.Id, charger.Id, start.AddHours(4), start.AddHours(5), 999);
            someoneElses.ConfirmWithQrCode(Guid.NewGuid().ToString());
            db.Reservations.AddRange(cancelled, charged, covered, someoneElses);
            await db.SaveChangesAsync();

            var session = ChargingSession.Start(charged, owner.Id, DateTimeOffset.UtcNow.AddHours(-1));
            session.Stop(DateTimeOffset.UtcNow, 20, null);
            var invoice = PaymentInvoice.Issue(session, auth.User.Id, 100, 500);
            invoice.Settle(PaymentMethod.Wallet);
            var coveredSession = ChargingSession.Start(covered, owner.Id, DateTimeOffset.UtcNow.AddHours(-1));
            coveredSession.Stop(DateTimeOffset.UtcNow.AddMinutes(-30), 20, null);
            var coveredInvoice = PaymentInvoice.Issue(coveredSession, auth.User.Id, 40, 500);
            db.ChargingSessions.AddRange(session, coveredSession);
            db.PaymentInvoices.AddRange(invoice, coveredInvoice);
            var plan = new MembershipPlan { Id = Guid.NewGuid(), Name = "Plus", MonthlyFee = 300 };
            db.MembershipPlans.Add(plan);
            db.Subscriptions.Add(new Subscription { DriverId = auth.User.Id, PlanId = plan.Id, Plan = plan,
                StartDate = DateTimeOffset.UtcNow, EndDate = DateTimeOffset.UtcNow.AddDays(30), FeePaid = 300, CreditApplied = 100 });
            db.WalletTopUps.Add(new WalletTopUp { DriverId = auth.User.Id, Amount = 1000, Status = "Paid",
                CreditedAt = DateTimeOffset.UtcNow });
            db.RewardRedemptions.Add(new RewardRedemption { DriverId = auth.User.Id, RewardId = Guid.NewGuid(),
                RequestId = Guid.NewGuid(), RewardDescription = "Test reward", WalletCredit = 50, Status = "Approved" });
            await db.SaveChangesAsync();
        }

        var jsonOptions = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        jsonOptions.Converters.Add(new JsonStringEnumConverter());
        var history = (await client.GetFromJsonAsync<List<DriverPaymentHistoryItemDto>>(
            "/api/payments/history", jsonOptions))!;
        Assert.Equal(12, history.Count);
        Assert.Equal(3, history.Count(item => item.Type == "ReservationAdvance" && item.Amount == 500));
        Assert.Contains(history, item => item.Type == "CancellationFee" && item.Amount == 500 && item.Direction == "Out");
        Assert.Contains(history, item => item.Type == "AdvanceRefund" && item.Amount == 500 && item.Direction == "In");
        var chargedInvoice = Assert.Single(history.Where(item => item.Type == "ChargingPayment" && item.Amount == 1500));
        Assert.Equal("Out", chargedInvoice.Direction);
        Assert.Equal(chargedInvoice.ReferenceId, chargedInvoice.Invoice?.Id);
        Assert.Equal("History Station", chargedInvoice.Invoice?.StationName);
        Assert.Equal(500, chargedInvoice.Invoice?.AdvanceDeducted);
        Assert.Equal(1500, chargedInvoice.Invoice?.NetAmountDue);
        var advancePaidInvoice = Assert.Single(history.Where(item => item.Type == "ChargingPayment" && item.Amount == 0));
        Assert.Equal("Info", advancePaidInvoice.Direction);
        Assert.Equal(400, advancePaidInvoice.Invoice?.GrossAmount);
        Assert.Equal(400, advancePaidInvoice.Invoice?.AdvanceDeducted);
        Assert.Equal(0, advancePaidInvoice.Invoice?.NetAmountDue);
        Assert.Contains(history, item => item.Type == "AdvanceRefund" && item.Amount == 100 && item.Direction == "In");
        Assert.Contains(history, item => item.Type == "MembershipPayment" && item.Amount == 300);
        Assert.Contains(history, item => item.Type == "MembershipCredit" && item.Amount == 100);
        Assert.Contains(history, item => item.Type == "WalletTopUp" && item.Amount == 1000);
        Assert.Contains(history, item => item.Type == "RewardCredit" && item.Amount == 50);
        Assert.DoesNotContain(history, item => item.Amount == 999);
        Assert.Equal(history.Select(item => item.OccurredAt).OrderByDescending(date => date),
            history.Select(item => item.OccurredAt));

        var adminLogin = await client.PostAsJsonAsync("/api/auth/login", new
        { email = ChargeSyncApiFactory.AdminEmail, password = ChargeSyncApiFactory.AdminPassword });
        adminLogin.EnsureSuccessStatusCode();
        var admin = (await adminLogin.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync("/api/payments/history")).StatusCode);
    }
}
