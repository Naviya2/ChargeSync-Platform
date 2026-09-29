using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AgentClient;

public static class DependencyInjection
{
    public static IServiceCollection AddAgentClient(this IServiceCollection services, IConfiguration configuration)
    {
        var agentBaseUrl = configuration["AgenticAi:BaseUrl"] ?? "http://localhost:8000";
        var groqApiKey = configuration["Groq:ApiKey"];
        var groqModel = configuration["Groq:Model"];

        services.AddHttpClient<IVehicleAgentClient, VehicleAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(120);
            if (!string.IsNullOrWhiteSpace(groqApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Groq-Api-Key", groqApiKey);
            }
            if (!string.IsNullOrWhiteSpace(groqModel))
            {
                client.DefaultRequestHeaders.Add("X-Groq-Model", groqModel);
            }
        });

        services.AddHttpClient<IPlanningAgentClient, PlanningAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(120);
            if (!string.IsNullOrWhiteSpace(groqApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Groq-Api-Key", groqApiKey);
            }
            if (!string.IsNullOrWhiteSpace(groqModel))
            {
                client.DefaultRequestHeaders.Add("X-Groq-Model", groqModel);
            }
        });

        return services;
    }
}
