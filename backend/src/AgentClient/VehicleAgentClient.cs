using System.Net.Http.Json;
using System.Text.Json;
using AgentClient.Models;
using Microsoft.Extensions.Logging;

namespace AgentClient;

public sealed class VehicleAgentClient : IVehicleAgentClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<VehicleAgentClient>? _logger;

    public VehicleAgentClient(HttpClient httpClient, ILogger<VehicleAgentClient>? logger = null)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<AgentCompatibilityResponse?> EvaluateCompatibilityAsync(
        AgentCompatibilityRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("/api/compatibility/evaluate", request, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<AgentCompatibilityResponse>(
                    cancellationToken: cancellationToken);
            }

            _logger?.LogWarning("Agent AI service returned status {StatusCode}: {Body}",
                response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
            return null;
        }
        catch (Exception ex)
        {
            _logger?.LogWarning(ex, "Failed to call Agent AI service, falling back to deterministic calculations.");
            return null;
        }
    }
}
