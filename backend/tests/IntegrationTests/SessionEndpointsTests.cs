using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Application.Authentication.Models;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Application.Sessions.Models;
using Domain.Entities;
using Domain.Enums;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class SessionEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly ChargeSyncApiFactory _factory;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() }
    };

    public SessionEndpointsTests(ChargeSyncApiFactory factory) => _factory = factory;

    [Fact]
    public async Task WalkIn_CreatesOneInProgressSession_AndDuplicateStartIsRejected()
    {
        var client = _factory.CreateClient();
        var owner = await RegisterOwnerAsync(client);
        var chargerId = await CreateChargerAsync(owner.User.Id);

        var response = await client.PostAsJsonAsync("/api/reservations/walk-in", new WalkInRequest
        {
            ChargerId = chargerId,
            StartTime = DateTimeOffset.UtcNow,
            EndTime = DateTimeOffset.UtcNow.AddHours(1)
        });
        response.EnsureSuccessStatusCode();
        var reservation = await response.Content.ReadFromJsonAsync<ReservationDto>(JsonOptions);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var session = await db.ChargingSessions.AsNoTracking()
            .SingleAsync(s => s.ReservationId == reservation!.Id);
        Assert.Equal(ChargingSessionStatus.InProgress, session.Status);
        Assert.Equal(owner.User.Id, session.StaffUserId);
        Assert.Equal(
            ChargerStatus.Occupied,
            await db.Chargers.Where(c => c.Id == chargerId).Select(c => c.Status).SingleAsync());

        var duplicate = await client.PostAsJsonAsync("/api/sessions/start", new StartSessionRequest
        {
            ReservationId = reservation!.Id
        });
        Assert.Equal(HttpStatusCode.BadRequest, duplicate.StatusCode);
    }

    [Fact]
    public async Task QrCheckIn_CreatesSession_ThatOwnerCanListAndStop()
    {
        var client = _factory.CreateClient();
        var owner = await RegisterOwnerAsync(client);
        var chargerId = await CreateChargerAsync(owner.User.Id);
        var qrCode = Guid.NewGuid().ToString("N");
        Guid reservationId;

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var reservation = Reservation.Create(
                owner.User.Id,
                chargerId,
                DateTimeOffset.UtcNow.AddMinutes(1),
                DateTimeOffset.UtcNow.AddHours(1),
                0m);
            reservation.ConfirmWithQrCode(qrCode);
            db.Reservations.Add(reservation);
            await db.SaveChangesAsync();
            reservationId = reservation.Id;
        }

        var checkIn = await client.PostAsJsonAsync("/api/reservations/staff-checkin", new StaffCheckinRequest
        {
            QrCode = qrCode
        });
        checkIn.EnsureSuccessStatusCode();

        var sessions = await client.GetFromJsonAsync<List<ChargingSessionDto>>(
            "/api/sessions?status=InProgress", JsonOptions);
        var session = Assert.Single(sessions!, s => s.ReservationId == reservationId);

        using var form = new MultipartFormDataContent();
        form.Add(new StringContent("12.50"), "staffOverriddenKwh");
        var stop = await client.PutAsync($"/api/sessions/{session.Id}/stop", form);
        stop.EnsureSuccessStatusCode();
        var completed = await stop.Content.ReadFromJsonAsync<ChargingSessionDto>(JsonOptions);

        Assert.Equal(12.50m, completed!.FinalEnergyDeliveredKwh);
        Assert.NotNull(completed.EndTime);
        Assert.NotEqual(ChargingSessionStatus.InProgress, completed.Status);

        using var verificationScope = _factory.Services.CreateScope();
        var verificationDb = verificationScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(
            ChargerStatus.Available,
            await verificationDb.Chargers
                .Where(c => c.Id == chargerId)
                .Select(c => c.Status)
                .SingleAsync());
    }

    [Fact]
    public async Task DifferentStationOwner_CannotReadOrStopSession()
    {
        var ownerClient = _factory.CreateClient();
        var owner = await RegisterOwnerAsync(ownerClient);
        var chargerId = await CreateChargerAsync(owner.User.Id);
        var walkIn = await ownerClient.PostAsJsonAsync("/api/reservations/walk-in", new WalkInRequest
        {
            ChargerId = chargerId,
            StartTime = DateTimeOffset.UtcNow,
            EndTime = DateTimeOffset.UtcNow.AddHours(1)
        });
        walkIn.EnsureSuccessStatusCode();
        var reservation = await walkIn.Content.ReadFromJsonAsync<ReservationDto>(JsonOptions);

        Guid sessionId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            sessionId = await db.ChargingSessions
                .Where(s => s.ReservationId == reservation!.Id)
                .Select(s => s.Id)
                .SingleAsync();
        }

        var otherOwnerClient = _factory.CreateClient();
        await RegisterOwnerAsync(otherOwnerClient);

        var read = await otherOwnerClient.GetAsync($"/api/sessions/{sessionId}");
        Assert.Equal(HttpStatusCode.NotFound, read.StatusCode);

        using var form = new MultipartFormDataContent();
        form.Add(new StringContent("10"), "staffOverriddenKwh");
        var stop = await otherOwnerClient.PutAsync($"/api/sessions/{sessionId}/stop", form);
        Assert.Equal(HttpStatusCode.Forbidden, stop.StatusCode);
    }

    private async Task<AuthResult> RegisterOwnerAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Session Test Owner",
            email = $"session-owner-{Guid.NewGuid():N}@example.com",
            password = "password123",
            role = "StationOwner"
        });
        response.EnsureSuccessStatusCode();
        var auth = await response.Content.ReadFromJsonAsync<AuthResult>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);
        return auth;
    }

    private async Task<Guid> CreateChargerAsync(Guid ownerId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var station = Station.Create("Session Station", "Test address", 6.9, 79.8, ownerId);
        db.Stations.Add(station);
        await db.SaveChangesAsync();

        var charger = Charger.Create(station.Id, $"CHR-{Guid.NewGuid():N}", "Bay 1", ConnectorType.CCS2, 50m, 40m);
        db.Chargers.Add(charger);
        await db.SaveChangesAsync();
        return charger.Id;
    }
}
