using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Application.Authentication.Models;
using Application.Common.Interfaces;
using Domain.Users;
using Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace IntegrationTests;

public sealed class SupportEndpointsTests(ChargeSyncApiFactory factory) : IClassFixture<ChargeSyncApiFactory>
{
    private async Task<(HttpClient Client, Guid Id)> Driver()
    {
        var client = factory.CreateClient(); var email = $"support-driver-{Guid.NewGuid()}@test.com";
        var response = await client.PostAsJsonAsync("/api/auth/register", new { fullName = "Ticket Driver", email, password = "password123", role = "Driver" });
        response.EnsureSuccessStatusCode(); var auth = (await response.Content.ReadFromJsonAsync<AuthResult>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken); return (client, auth.User.Id);
    }
    private async Task<(HttpClient Client, Guid Id)> SupportManager()
    {
        var email = $"manager-{Guid.NewGuid()}@test.com"; const string password = "password123";
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>(); var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
            var user = User.Create("Support Manager", email, hasher.Hash(password), UserRole.SupportManager); db.Users.Add(user); await db.SaveChangesAsync();
        }
        var client = factory.CreateClient(); var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password }); login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResult>())!; client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken); return (client, auth.User.Id);
    }

    [Fact]
    public async Task DriverOwnershipAndSupportWorkflowAreEnforced()
    {
        var (owner, _) = await Driver(); var (other, _) = await Driver(); var (manager, managerId) = await SupportManager();
        var created = await owner.PostAsJsonAsync("/api/support-tickets", new { category = "Technical", subject = "Application does not refresh", description = "The charging application is not refreshing correctly." }); created.EnsureSuccessStatusCode();
        var ticket = (await created.Content.ReadFromJsonAsync<Application.Support.SupportTicketDto>())!;
        Assert.Equal(HttpStatusCode.Forbidden, (await other.GetAsync($"/api/support-tickets/{ticket.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await owner.PostAsync($"/api/support-tickets/{ticket.Id}/analysis", null)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await manager.PostAsync($"/api/support-tickets/{Guid.NewGuid()}/analysis", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await owner.PutAsJsonAsync($"/api/support-tickets/{ticket.Id}/status", new { status = "Resolved" })).StatusCode);
        (await manager.PutAsJsonAsync($"/api/support-tickets/{ticket.Id}/assignee", new { assigneeId = managerId })).EnsureSuccessStatusCode();
        (await manager.PostAsJsonAsync($"/api/support-tickets/{ticket.Id}/messages", new { body = "We are investigating this report." })).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.DeleteAsync($"/api/support-tickets/{ticket.Id}")).StatusCode);
        var resolved = await manager.PutAsJsonAsync($"/api/support-tickets/{ticket.Id}/status", new { status = "Resolved" }); resolved.EnsureSuccessStatusCode();
        var final = (await resolved.Content.ReadFromJsonAsync<Application.Support.SupportTicketDto>())!;
        Assert.Equal("Resolved", final.Status); Assert.Equal(managerId, final.AssignedToUserId);
    }

    [Fact]
    public async Task InvalidCategoryAndRefundWithoutInvoiceAreRejected()
    {
        var (driver, _) = await Driver();
        Assert.Equal(HttpStatusCode.BadRequest, (await driver.PostAsJsonAsync("/api/support-tickets", new { category = "Fake", subject = "Valid subject", description = "A sufficiently detailed description." })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await driver.PostAsJsonAsync("/api/support-tickets", new { category = "Refund", subject = "Refund request", description = "Please refund the disputed invoice.", requestedRefundAmount = 100 })).StatusCode);
    }

    [Fact]
    public async Task AdminCanAssignTicketToSelf()
    {
        var (driver, _) = await Driver();
        var created = await driver.PostAsJsonAsync("/api/support-tickets", new { category = "Payment", subject = "Payment needs review", description = "Please review the payment attached to my account." });
        created.EnsureSuccessStatusCode(); var ticket = (await created.Content.ReadFromJsonAsync<Application.Support.SupportTicketDto>())!;
        var admin = factory.CreateClient(); var login = await admin.PostAsJsonAsync("/api/auth/login", new { email = ChargeSyncApiFactory.AdminEmail, password = ChargeSyncApiFactory.AdminPassword }); login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResult>())!; admin.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        var assigned = await admin.PutAsJsonAsync($"/api/support-tickets/{ticket.Id}/assignee", new { assigneeId = auth.User.Id }); assigned.EnsureSuccessStatusCode();
        Assert.Equal(auth.User.Id, (await assigned.Content.ReadFromJsonAsync<Application.Support.SupportTicketDto>())!.AssignedToUserId);
    }
}
