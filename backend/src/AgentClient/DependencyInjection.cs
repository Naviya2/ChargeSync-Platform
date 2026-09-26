using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AgentClient;

public static class DependencyInjection
{
    public static IServiceCollection AddAgentClient(this IServiceCollection services, IConfiguration configuration)
    {
        var agentBaseUrl = configuration["AgenticAi:BaseUrl"] ?? "http://localhost:8000";

        services.AddHttpClient<IVehicleAgentClient, VehicleAgentClient>(client =>
        {
            client.BaseAddress = new Uri(agentBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);
        });

        return services;
    }
}
