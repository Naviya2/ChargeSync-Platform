using AgentClient.Models;

namespace AgentClient;

public interface IVehicleAgentClient
{
    Task<AgentCompatibilityResponse?> EvaluateCompatibilityAsync(
        AgentCompatibilityRequest request,
        CancellationToken cancellationToken = default);

    Task<AgentBatchCompatibilityResponse?> BatchEvaluateCompatibilityAsync(
        AgentBatchCompatibilityRequest request,
        CancellationToken cancellationToken = default);
}
