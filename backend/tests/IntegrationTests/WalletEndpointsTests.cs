using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Application.Authentication.Models;
using Infrastructure.Payments;
using Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class WalletEndpointsTests : IDisposable
{
    private readonly Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactory<Program> app = new ChargeSyncApiFactory()
        .WithWebHostBuilder(builder => builder.ConfigureServices(services => services.PostConfigure<PayHereOptions>(o =>
        {
            o.Enabled = true; o.Sandbox = true; o.MerchantId = "test-merchant";
            o.MerchantSecret = "test-secret"; o.PublicBaseUrl = "https://test.example";
        })));
    public void Dispose() => app.Dispose();
    private async Task<(HttpClient Client, Guid Id)> Driver()
    {
        var client = app.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new { fullName = "Wallet Driver", email = $"wallet-{Guid.NewGuid()}@test.com", password = "password123", role = "Driver" });
        response.EnsureSuccessStatusCode(); var auth = (await response.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        return (client, auth.User.Id);
    }
    private static object Request(Guid? driverId = null) => new { requestId = Guid.NewGuid(), amount = 1000, phone = "0771234567", address = "12 Test Road", city = "Colombo", driverId };

    [Fact]
    public async Task CheckoutRequiresAuth_AndUsesSignedCapability_NotReturnPage_ForCredit()
    {
        var anonymous = app.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/wallet")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.PostAsJsonAsync("/api/wallet/top-ups", Request())).StatusCode);
        var (client, id) = await Driver(); var (_, otherId) = await Driver();
        var start = await client.PostAsJsonAsync("/api/wallet/top-ups", Request(otherId)); start.EnsureSuccessStatusCode();
        var json = await start.Content.ReadFromJsonAsync<JsonElement>();
        var url = new Uri(json.GetProperty("checkoutUrl").GetString()!);
        var checkout = await anonymous.GetAsync(url.PathAndQuery); checkout.EnsureSuccessStatusCode();
        var html = await checkout.Content.ReadAsStringAsync();
        Assert.Contains("https://sandbox.payhere.lk/pay/checkout", html); Assert.DoesNotContain("test-secret", html);
        Assert.Equal(HttpStatusCode.BadRequest, (await anonymous.GetAsync("/api/wallet/payhere/checkout?ticket=forged")).StatusCode);
        (await anonymous.GetAsync("/api/wallet/payhere/return?status_code=2")).EnsureSuccessStatusCode();
        using var scope = app.Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(0, (await db.Users.FindAsync(id))!.WalletBalance);
        Assert.Equal(id, db.WalletTopUps.Single().DriverId); // Client cannot choose recipient.
    }

    [Fact]
    public async Task SignedFormCallback_CreditsOnce_AndOtherDriverCannotSeeOrder()
    {
        var (client, id) = await Driver(); var (other, _) = await Driver();
        var start = await client.PostAsJsonAsync("/api/wallet/top-ups", Request()); start.EnsureSuccessStatusCode();
        var order = (await start.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("topUp").GetProperty("id").GetGuid().ToString("N");
        static string Hash(string value) => Convert.ToHexString(MD5.HashData(Encoding.UTF8.GetBytes(value)));
        var fields = new Dictionary<string, string> { ["merchant_id"] = "test-merchant", ["order_id"] = order,
            ["payment_id"] = "payment-123", ["payhere_amount"] = "1000.00", ["payhere_currency"] = "LKR", ["status_code"] = "2",
            ["md5sig"] = Hash("test-merchant" + order + "1000.00LKR2" + Hash("test-secret")) };
        var anonymous = app.CreateClient();
        (await anonymous.PostAsync("/api/wallet/payhere/notify", new FormUrlEncodedContent(fields))).EnsureSuccessStatusCode();
        (await anonymous.PostAsync("/api/wallet/payhere/notify", new FormUrlEncodedContent(fields))).EnsureSuccessStatusCode();
        fields["payhere_amount"] = "5000.00";
        Assert.Equal(HttpStatusCode.Forbidden, (await anonymous.PostAsync("/api/wallet/payhere/notify", new FormUrlEncodedContent(fields))).StatusCode);
        var ownWallet = await client.GetFromJsonAsync<JsonElement>("/api/wallet");
        Assert.Equal(1000, ownWallet.GetProperty("balance").GetDecimal());
        Assert.Single(ownWallet.GetProperty("topUps").EnumerateArray());
        var otherWallet = await other.GetFromJsonAsync<JsonElement>("/api/wallet");
        Assert.Empty(otherWallet.GetProperty("topUps").EnumerateArray());
        Assert.Equal(0, otherWallet.GetProperty("balance").GetDecimal());
    }
}
