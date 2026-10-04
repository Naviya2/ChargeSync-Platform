using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Support;
using Domain.Support;
using Microsoft.EntityFrameworkCore;

namespace Api;

public sealed class SupportWorkflowWorker(IServiceScopeFactory scopes, IConfiguration config,
    ILogger<SupportWorkflowWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!config.GetValue("AgenticAi:WorkflowsEnabled", true)) return;
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                using var scope = scopes.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
                var now = DateTimeOffset.UtcNow;
                var id = await db.AgentWorkflowRuns.AsNoTracking()
                    .Where(r => r.Status == AgentWorkflowStatus.Running && r.NextAttemptAt <= now && (r.LeaseUntil == null || r.LeaseUntil <= now))
                    .OrderBy(r => r.NextAttemptAt).Select(r => (Guid?)r.Id).FirstOrDefaultAsync(stoppingToken);
                if (id.HasValue) await scope.ServiceProvider.GetRequiredService<SupportWorkflowService>().ProcessAsync(id.Value, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (PaymentConflictException) { /* Another worker or reviewer won the version check. */ }
            catch (Exception ex)
            {
                // Do not log request bodies, model text, headers or credentials.
                logger.LogWarning("Support workflow processing failed ({ExceptionType}). Pending work will be retried.", ex.GetType().Name);
            }
        }
    }
}
