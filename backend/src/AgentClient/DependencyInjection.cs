using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AgentClient;

public static class DependencyInjection
{
    public static IServiceCollection AddAgentClient(this IServiceCollection services, IConfiguration configuration)
    {
        var agentBaseUrl = configuration["AgenticAi:BaseUrl"] ?? "http://localhost:8000";
        var geminiApiKey = configuration["Gemini:ApiKey"];
        var geminiModel = configuration["Gemini:Model"];

        services.AddHttpClient<IVehicleAgentClient, VehicleAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(120);
            if (!string.IsNullOrWhiteSpace(geminiApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Gemini-Api-Key", geminiApiKey);
            }
            if (!string.IsNullOrWhiteSpace(geminiModel))
            {
                client.DefaultRequestHeaders.Add("X-Gemini-Model", geminiModel);
            }
        });

        services.AddHttpClient<IPlanningAgentClient, PlanningAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(120);
            if (!string.IsNullOrWhiteSpace(geminiApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Gemini-Api-Key", geminiApiKey);
            }
            if (!string.IsNullOrWhiteSpace(geminiModel))
            {
                client.DefaultRequestHeaders.Add("X-Gemini-Model", geminiModel);
            }
        });

        return services;
    }
}
