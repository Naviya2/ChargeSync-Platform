using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Application.Authentication.Models;
using Application.ReservationPlanning.DTOs;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class LateCancellationEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly ChargeSyncApiFactory _factory;
    public LateCancellationEndpointsTests(ChargeSyncApiFactory factory) => _factory = factory;

    [Fact]
    public async Task DriverCancellation_RefundsAndNextBookingCollectsFee_WithVisibleQuoteAndHistory()
    {
        using var client = _factory.CreateClient();
        var register = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Fee Test Driver", email = $"fee-{Guid.NewGuid()}@test.com", password = "password123", role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var auth = (await register.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        Guid originalId, chargerId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var driver = await db.Users.SingleAsync(u => u.Id == auth.User.Id);
            driver.CreditBalance(1000); // balance after original 500 advance
            var owner = User.Create("Owner", $"{Guid.NewGuid()}@test.com", "hash", UserRole.StationOwner);
            db.Users.Add(owner);
            var station = Station.Create("Fee test", "Address", 0, 0, owner.Id);
            station.UpdateOperatingHours(Enumerable.Range(0, 7).Select(day =>
                OperatingHour.Create(station.Id, day, true, TimeSpan.Zero, new TimeSpan(23, 59, 59))).ToList());
            db.Stations.Add(station);
            var charger = Charger.Create(station.Id, "CH1", "Bay", ConnectorType.CCS2, 20, 100);
            db.Chargers.Add(charger);
            var original = Reservation.Create(driver.Id, charger.Id, DateTimeOffset.UtcNow.AddMinutes(60),
                DateTimeOffset.UtcNow.AddMinutes(90), 500, Guid.NewGuid());
            original.ConfirmWithQrCode(Guid.NewGuid().ToString());
            db.Reservations.Add(original);
            await db.SaveChangesAsync();
            originalId = original.Id;
            chargerId = charger.Id;
        }

        var cancel = await client.PutAsync($"/api/reservations/{originalId}/cancel", null);
        Assert.Equal(HttpStatusCode.NoContent, cancel.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsync($"/api/reservations/{originalId}/cancel", null)).StatusCode);
        var quote = (await client.GetFromJsonAsync<BookingChargesDto>("/api/reservations/booking-charges"))!;
        Assert.Equal(1500, quote.WalletBalance);
        Assert.Equal(500, quote.PendingCancellationFees);
        var wallet = await client.GetFromJsonAsync<JsonElement>("/api/wallet");
        Assert.Equal(500, wallet.GetProperty("pendingCancellationFees").GetDecimal());

        var start = new DateTimeOffset(DateTime.UtcNow.Date.AddDays(1).AddHours(4), TimeSpan.Zero);
        var stale = await client.PostAsJsonAsync("/api/reservations", new
        {
            chargerId, vehicleId = (Guid?)null, startTime = start, endTime = start.AddMinutes(30), advanceDepositAmount = 500
        });
        Assert.Equal(HttpStatusCode.Conflict, stale.StatusCode);
        var created = await client.PostAsJsonAsync("/api/reservations", new
        {
            chargerId, vehicleId = (Guid?)null, startTime = start, endTime = start.AddMinutes(30),
            advanceDepositAmount = 500, expectedCancellationFees = 500
        });
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var booking = await created.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(500, booking.GetProperty("cancellationFeesPaid").GetDecimal());
        Assert.Equal(500, booking.GetProperty("advanceDepositAmount").GetDecimal());
        var after = (await client.GetFromJsonAsync<BookingChargesDto>("/api/reservations/booking-charges"))!;
        Assert.Equal(500, after.WalletBalance);
        Assert.Equal(0, after.PendingCancellationFees);
        var source = await client.GetFromJsonAsync<JsonElement>($"/api/reservations/{originalId}");
        Assert.Equal(500, source.GetProperty("lateCancellationFee").GetDecimal());
        Assert.Equal("Cancelled", source.GetProperty("status").GetString());
    }

    [Fact]
    public async Task BookingCharges_RequiresDriverAuthentication()
    {
        using var client = _factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/reservations/booking-charges")).StatusCode);
        var login = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = ChargeSyncApiFactory.AdminEmail, password = ChargeSyncApiFactory.AdminPassword
        });
        login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync("/api/reservations/booking-charges")).StatusCode);
    }
}
