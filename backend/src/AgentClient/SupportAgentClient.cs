using System.Net.Http.Json;
using System.Text.Json;
using Application.Support;

namespace AgentClient;

public sealed class SupportAgentClient(HttpClient http) : ISupportAgentClient
{
    public async Task<SupportSuggestion?> AnalyzeAsync(SupportAnalysisInput input, CancellationToken ct)
    {
        try
        {
            using var response = await http.PostAsJsonAsync("/api/support/analyze", input, ct);
            if (!response.IsSuccessStatusCode) return null;
            var result = await response.Content.ReadFromJsonAsync<SupportSuggestion>(cancellationToken: ct);
            if (result is null || !new[] { "Charging", "Reservation", "Payment", "Refund", "Technical", "Membership", "Other" }.Contains(result.Category) ||
                !new[] { "Low", "Medium", "High", "Urgent" }.Contains(result.Priority) ||
                string.IsNullOrWhiteSpace(result.Explanation) || result.Explanation.Length > 4000 ||
                string.IsNullOrWhiteSpace(result.DraftReply) || result.DraftReply.Length > 4000) return null;
            return result;
        }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested) { return null; }
        catch (HttpRequestException) { return null; }
        catch (JsonException) { return null; }
    }
}
