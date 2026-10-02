using AgentClient.Models;

namespace AgentClient;

public interface IVehicleAgentClient
{
    Task<AgentCompatibilityResponse?> EvaluateCompatibilityAsync(
        AgentCompatibilityRequest request,
        CancellationToken cancellationToken = default);
}
