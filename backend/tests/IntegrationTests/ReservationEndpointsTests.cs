using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Infrastructure.Persistence;
using Domain.Entities;

namespace IntegrationTests;

public sealed class ReservationEndpointsTests : IClassFixture<ChargeSyncApiFactory>
{
    private readonly HttpClient _client;
    private readonly ChargeSyncApiFactory _factory;

    public ReservationEndpointsTests(ChargeSyncApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private sealed record AuthResponse(string AccessToken);

    [Fact]
    public async Task CreateReservation_WithoutAuth_ReturnsUnauthorized()
    {
        var response = await _client.PostAsJsonAsync("/api/reservations", new CreateReservationRequest
        {
            ChargerId = Guid.NewGuid(),
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow,
            EndTime = DateTimeOffset.UtcNow.AddHours(1),
            AdvanceDepositAmount = 10.0m
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreateReservation_WithInsufficientBalance_ReturnsBadRequest()
    {
        // 1. Register a new driver (balance will be 0 by default)
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Test Driver",
            email = $"driver-{Guid.NewGuid():N}@example.com",
            password = "password123",
            role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var auth = await register.Content.ReadFromJsonAsync<AuthResponse>();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        // 2. Try to create reservation requiring 10.0m deposit
        var request = new CreateReservationRequest
        {
            ChargerId = Guid.NewGuid(),
            VehicleId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow.AddHours(1),
            EndTime = DateTimeOffset.UtcNow.AddHours(2),
            AdvanceDepositAmount = 10.0m
        };

        var response = await _client.PostAsJsonAsync("/api/reservations", request);

        // Should be BadRequest because balance is 0
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateWalkIn_AsDriver_ReturnsForbidden()
    {
        // Walk-in is only allowed for StationOwner/Admin
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Test Driver 2",
            email = $"driver2-{Guid.NewGuid():N}@example.com",
            password = "password123",
            role = "Driver"
        });
        register.EnsureSuccessStatusCode();
        var auth = await register.Content.ReadFromJsonAsync<AuthResponse>();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        var request = new WalkInRequest
        {
            ChargerId = Guid.NewGuid(),
            StartTime = DateTimeOffset.UtcNow,
            EndTime = DateTimeOffset.UtcNow.AddHours(1)
        };

        var response = await _client.PostAsJsonAsync("/api/reservations/walk-in", request);
        
        // ASP.NET Core returns 403 Forbidden when authenticated but role/policy fails
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
