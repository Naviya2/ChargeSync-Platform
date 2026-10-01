using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AgentClient;

public static class DependencyInjection
{
    public static IServiceCollection AddAgentClient(this IServiceCollection services, IConfiguration configuration)
    {
        var agentBaseUrl = configuration["AGENT_SERVICE_BASE_URL"] ?? configuration["AgenticAi:BaseUrl"] ?? "http://localhost:8000";
        var serviceKey = configuration["AGENT_SERVICE_API_KEY"] ?? configuration["AgenticAi:ApiKey"];

        services.AddHttpClient<IVehicleAgentClient, VehicleAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);
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
