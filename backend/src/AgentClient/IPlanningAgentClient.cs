using AgentClient.Models;

namespace AgentClient;

public interface IPlanningAgentClient
{
    Task<PlanningResponse?> GenerateChargingPlanAsync(
        PlanningRequest request,
        CancellationToken cancellationToken = default);
}
