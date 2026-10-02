using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Application.Authentication.Models;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Application.Sessions.Models;
using Application.Payments.Models;
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
            StartTime = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(5.5)),
            EndTime = DateTimeOffset.UtcNow.AddHours(1).ToOffset(TimeSpan.FromHours(5.5))
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

        var stopRequest = new StopSessionRequest
        {
            StaffOverriddenKwh = 8.25m,
            MeterPhotoUrl = "https://cloudinary.com/dummy.png"
        };
        var stop = await client.PutAsJsonAsync($"/api/sessions/{session.Id}/stop", stopRequest);
        stop.EnsureSuccessStatusCode();
        var completion = await stop.Content.ReadFromJsonAsync<SessionCompletionDto>(JsonOptions);
        Assert.Null(completion!.Invoice.DriverId);
        Assert.Equal("https://cloudinary.com/dummy.png", completion.Session.MeterPhotoUrl);


        var cashPayment = await client.PostAsJsonAsync(
            $"/api/payments/invoices/{completion.Invoice.Id}/settle",
            new SettleInvoiceRequest { PaymentMethod = PaymentMethod.Cash });
        cashPayment.EnsureSuccessStatusCode();
        var cashInvoice = await cashPayment.Content.ReadFromJsonAsync<PaymentInvoiceDto>(JsonOptions);
        Assert.Equal(PaymentMethod.Cash, cashInvoice!.PaymentMethod);
        Assert.Equal(InvoiceStatus.Paid, cashInvoice.Status);
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
                DateTimeOffset.UtcNow.AddMinutes(-1),
                DateTimeOffset.UtcNow.AddHours(1),
                0m);
            reservation.ConfirmWithQrCode(qrCode);
            var driver = await db.Users.SingleAsync(u => u.Id == owner.User.Id);
            driver.CreditBalance(1000m);
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

        var stopRequest = new StopSessionRequest { StaffOverriddenKwh = 12.50m };
        var stop = await client.PutAsJsonAsync($"/api/sessions/{session.Id}/stop", stopRequest);
        stop.EnsureSuccessStatusCode();
        var completed = await stop.Content.ReadFromJsonAsync<SessionCompletionDto>(JsonOptions);

        Assert.Equal(12.50m, completed!.Session.FinalEnergyDeliveredKwh);
        Assert.NotNull(completed.Session.EndTime);
        Assert.NotEqual(ChargingSessionStatus.InProgress, completed.Session.Status);
        Assert.Equal(500m, completed.Invoice.GrossAmount);
        Assert.Equal(500m, completed.Invoice.NetAmountDue);
        Assert.Equal(InvoiceStatus.Pending, completed.Invoice.Status);

        var settlementUrl = $"/api/payments/invoices/{completed.Invoice.Id}/settle";
        var settlements = await Task.WhenAll(
            client.PostAsJsonAsync(
                settlementUrl,
                new SettleInvoiceRequest { PaymentMethod = PaymentMethod.Wallet }),
            client.PostAsJsonAsync(
                settlementUrl,
                new SettleInvoiceRequest { PaymentMethod = PaymentMethod.Wallet }));
        var settlement = Assert.Single(settlements, response => response.IsSuccessStatusCode);
        Assert.Single(settlements, response =>
            response.StatusCode is HttpStatusCode.BadRequest or HttpStatusCode.Conflict);
        var paidInvoice = await settlement.Content.ReadFromJsonAsync<PaymentInvoiceDto>(JsonOptions);
        Assert.Equal(InvoiceStatus.Paid, paidInvoice!.Status);
        Assert.Equal(PaymentMethod.Wallet, paidInvoice.PaymentMethod);

        using var verificationScope = _factory.Services.CreateScope();
        var verificationDb = verificationScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(
            ChargerStatus.Available,
            await verificationDb.Chargers
                .Where(c => c.Id == chargerId)
                .Select(c => c.Status)
                .SingleAsync());
        Assert.Equal(
            500m,
            await verificationDb.Users
                .Where(u => u.Id == owner.User.Id)
                .Select(u => u.WalletBalance)
                .SingleAsync());
    }

    [Fact]
    public async Task WalletSettlement_WithInsufficientBalance_LeavesInvoicePending()
    {
        var client = _factory.CreateClient();
        var owner = await RegisterOwnerAsync(client);
        var chargerId = await CreateChargerAsync(owner.User.Id);
        Guid invoiceId;

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var reservation = Reservation.Create(
                owner.User.Id,
                chargerId,
                DateTimeOffset.UtcNow.AddMinutes(1),
                DateTimeOffset.UtcNow.AddHours(1),
                0m);
            reservation.ConfirmWithQrCode(Guid.NewGuid().ToString("N"));
            reservation.CheckIn();
            db.Reservations.Add(reservation);
            await db.SaveChangesAsync();

            var session = ChargingSession.Start(
                reservation,
                owner.User.Id,
                DateTimeOffset.UtcNow.AddHours(-1));
            session.Stop(DateTimeOffset.UtcNow, 50m, 20m);
            db.ChargingSessions.Add(session);
            await db.SaveChangesAsync();

            var invoice = PaymentInvoice.Issue(session, owner.User.Id, 40m, 0m);
            db.PaymentInvoices.Add(invoice);
            await db.SaveChangesAsync();
            invoiceId = invoice.Id;
        }

        var response = await client.PostAsJsonAsync(
            $"/api/payments/invoices/{invoiceId}/settle",
            new SettleInvoiceRequest { PaymentMethod = PaymentMethod.Wallet });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        using var verificationScope = _factory.Services.CreateScope();
        var verificationDb = verificationScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(
            InvoiceStatus.Pending,
            await verificationDb.PaymentInvoices
                .Where(i => i.Id == invoiceId)
                .Select(i => i.Status)
                .SingleAsync());
        Assert.Equal(
            0m,
            await verificationDb.Users
                .Where(u => u.Id == owner.User.Id)
                .Select(u => u.WalletBalance)
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
        var otherSessions = await otherOwnerClient.GetFromJsonAsync<List<ChargingSessionDto>>("/api/sessions", JsonOptions);
        Assert.DoesNotContain(otherSessions!, s => s.Id == sessionId);

        var stopRequest = new StopSessionRequest { StaffOverriddenKwh = 10m };
        var stop = await otherOwnerClient.PutAsJsonAsync($"/api/sessions/{sessionId}/stop", stopRequest);
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
        
        var operatingHours = Enumerable.Range(0, 7)
            .Select(day => OperatingHour.Create(station.Id, day, true, TimeSpan.Zero, new TimeSpan(23, 59, 59)))
            .ToList();
        station.UpdateOperatingHours(operatingHours);

        db.Stations.Add(station);
        await db.SaveChangesAsync();

        var charger = Charger.Create(station.Id, $"CHR-{Guid.NewGuid():N}", "Bay 1", ConnectorType.CCS2, 50m, 40m);
        db.Chargers.Add(charger);
        await db.SaveChangesAsync();
        return charger.Id;
    }
}
