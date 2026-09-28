using System.Net.Http.Json;
using AgentClient.Models;
using Microsoft.Extensions.Logging;

namespace AgentClient;

public sealed class PlanningAgentClient : IPlanningAgentClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PlanningAgentClient>? _logger;

    public PlanningAgentClient(HttpClient httpClient, ILogger<PlanningAgentClient>? logger = null)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<PlanningResponse?> GenerateChargingPlanAsync(
        PlanningRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("/api/charging-plan/generate", request, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<PlanningResponse>(
                    cancellationToken: cancellationToken);
            }

            _logger?.LogWarning("Agent AI service returned status {StatusCode}: {Body}",
                response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
            return null;
        }
        catch (Exception ex)
        {
            _logger?.LogWarning(ex, "Failed to call Agent AI service for planning.");
            return null;
        }
    }
}
