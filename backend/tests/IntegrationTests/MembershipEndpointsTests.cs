using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Application.Authentication.Models;
using Domain.Loyalty;
using Domain.Memberships;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class MembershipEndpointsTests(ChargeSyncApiFactory factory) : IClassFixture<ChargeSyncApiFactory>
{
    private async Task<(HttpClient Client, Guid Id)> Driver()
    {
        var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new { fullName = "Membership Driver", email = $"member-{Guid.NewGuid()}@test.com", password = "password123", role = "Driver" });
        response.EnsureSuccessStatusCode();
        var auth = (await response.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        return (client, auth.User.Id);
    }

    [Fact]
    public async Task DriverCannotReadOthersPointsOrApproveRewards()
    {
        var (first, _) = await Driver(); var (_, secondId) = await Driver();
        Assert.Equal(HttpStatusCode.Forbidden, (await first.GetAsync($"/api/loyalty/{secondId}")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await first.PostAsJsonAsync($"/api/loyalty/redemptions/{Guid.NewGuid()}/review", new { approve = true })).StatusCode);
    }

    [Fact]
    public async Task RedemptionIgnoresClientPriceAndRetriesReturnSameRecord()
    {
        var (client, id) = await Driver();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var account = new LoyaltyAccount { DriverId = id }; account.Earn(150); db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        }
        var rewards = (await client.GetFromJsonAsync<List<Reward>>("/api/loyalty/rewards"))!;
        var payload = new { rewardId = rewards[0].Id, requestId = Guid.NewGuid(), pointsCost = 1, walletCredit = 1000000 };
        var response = await client.PostAsJsonAsync("/api/loyalty/redeem", payload); response.EnsureSuccessStatusCode();
        var redemption = (await response.Content.ReadFromJsonAsync<RewardRedemption>())!;
        Assert.Equal(100, redemption.PointsRedeemed); Assert.Equal(100m, redemption.WalletCredit);
        var repeat = await client.PostAsJsonAsync("/api/loyalty/redeem", payload); repeat.EnsureSuccessStatusCode();
        Assert.Equal(redemption.Id, (await repeat.Content.ReadFromJsonAsync<RewardRedemption>())!.Id);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/loyalty/redeem", new { rewardId = rewards[0].Id, requestId = Guid.NewGuid() })).StatusCode);
        using var verify = factory.Services.CreateScope(); var context = verify.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(50, (await context.LoyaltyAccounts.FindAsync(id))!.PointsBalance);
        Assert.Equal(100m, (await context.Users.FindAsync(id))!.WalletBalance);
    }

    [Fact]
    public async Task InsufficientMembershipFunds_DoNotCreateSubscription_AndOtherDriverCannotCancel()
    {
        var (client, id) = await Driver(); var (other, _) = await Driver();
        var plans = (await client.GetFromJsonAsync<List<MembershipPlan>>("/api/membership-plans"))!;
        var failed = await client.PostAsJsonAsync("/api/subscriptions", new { planId = plans[0].Id });
        Assert.Equal(HttpStatusCode.BadRequest, failed.StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            Assert.False(await db.Subscriptions.AnyAsync(s => s.DriverId == id));
            (await db.Users.FindAsync(id))!.CreditBalance(1000); await db.SaveChangesAsync();
        }
        var created = await client.PostAsJsonAsync("/api/subscriptions", new { planId = plans[0].Id }); created.EnsureSuccessStatusCode();
        var subscription = (await created.Content.ReadFromJsonAsync<Application.Memberships.SubscriptionDto>())!;
        Assert.Equal(HttpStatusCode.NotFound, (await other.DeleteAsync($"/api/subscriptions/{subscription.Id}")).StatusCode);
        (await client.DeleteAsync($"/api/subscriptions/{subscription.Id}")).EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task AdminApproval_CreditsReservedRewardExactlyOnce()
    {
        var (driver, id) = await Driver();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var account = new LoyaltyAccount { DriverId = id }; account.Earn(6000);
            db.LoyaltyAccounts.Add(account); await db.SaveChangesAsync();
        }
        var rewards = (await driver.GetFromJsonAsync<List<Reward>>("/api/loyalty/rewards"))!;
        var request = await driver.PostAsJsonAsync("/api/loyalty/redeem", new { rewardId = rewards[1].Id, requestId = Guid.NewGuid() });
        request.EnsureSuccessStatusCode();
        var redemption = (await request.Content.ReadFromJsonAsync<RewardRedemption>())!;
        Assert.Equal("Pending", redemption.Status);
        var admin = factory.CreateClient();
        var login = await admin.PostAsJsonAsync("/api/auth/login", new { email = ChargeSyncApiFactory.AdminEmail, password = ChargeSyncApiFactory.AdminPassword });
        login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResult>())!;
        admin.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        var approved = await admin.PostAsJsonAsync($"/api/loyalty/redemptions/{redemption.Id}/review", new { approve = true });
        approved.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync($"/api/loyalty/redemptions/{redemption.Id}/review", new { approve = true })).StatusCode);
        using var verify = factory.Services.CreateScope(); var context = verify.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(6000m, (await context.Users.FindAsync(id))!.WalletBalance);
        Assert.Equal(0, (await context.LoyaltyAccounts.FindAsync(id))!.PointsBalance);
        Assert.Equal(auth.User.Id, (await context.RewardRedemptions.FindAsync(redemption.Id))!.ReviewedBy);
    }
}
