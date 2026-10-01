using System.Net.Http.Json;
using System.Text.Json;
using Application.Support;

namespace AgentClient;

public sealed class SupportWorkflowClient(HttpClient http) : ISupportWorkflowClient
{
    public async Task<SupportWorkflowOutput?> RunAsync(SupportWorkflowInput input, CancellationToken ct)
    {
        try
        {
            using var response = await http.PostAsJsonAsync("/api/workflows/support", input, ct);
            if (!response.IsSuccessStatusCode) return null;
            return await response.Content.ReadFromJsonAsync<SupportWorkflowOutput>(cancellationToken: ct);
        }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested) { return null; }
        catch (HttpRequestException) { return null; }
        catch (JsonException) { return null; }
    }
}
