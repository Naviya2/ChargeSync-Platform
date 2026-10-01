using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AgentClient;

public static class DependencyInjection
{
    public static IServiceCollection AddAgentClient(this IServiceCollection services, IConfiguration configuration)
    {
        var agentBaseUrl = configuration["AGENT_SERVICE_BASE_URL"] ?? configuration["AgenticAi:BaseUrl"] ?? "http://localhost:8000";
        var serviceKey = configuration["AGENT_SERVICE_API_KEY"] ?? configuration["AgenticAi:ApiKey"];
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

        services.AddHttpClient<Application.Support.ISupportAgentClient, SupportAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(25);
            if (!string.IsNullOrWhiteSpace(serviceKey)) client.DefaultRequestHeaders.Add("X-Agent-Service-Key", serviceKey);
        });
        services.AddHttpClient<Application.Support.ISupportWorkflowClient, SupportWorkflowClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(25);
            if (!string.IsNullOrWhiteSpace(serviceKey)) client.DefaultRequestHeaders.Add("X-Agent-Service-Key", serviceKey);
        });
        return services;
    }
}
