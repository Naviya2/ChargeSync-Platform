using Application.Common.Interfaces;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Infrastructure.BackgroundJobs;

public class ReservationTimeoutService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ReservationTimeoutService> _logger;

    public ReservationTimeoutService(IServiceProvider serviceProvider, ILogger<ReservationTimeoutService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
                
                var now = DateTimeOffset.UtcNow;
                var timeoutThreshold = now.AddMinutes(-30);

                var expiredReservations = await db.Reservations
                    .Where(r => (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed) 
                                && r.StartTime <= timeoutThreshold)
                    .ToListAsync(stoppingToken);

                foreach (var res in expiredReservations)
                {
                    res.Cancel();
                    
                    // No-show penalty: Advance deposit is NOT refunded.
                    // Notification would be dispatched here.
                    if (res.DriverId.HasValue)
                    {
                        _logger.LogInformation("Notification sent to Driver {DriverId}: Your reservation was cancelled due to a no-show. Advance payment was not refunded.", res.DriverId);
                    }

                    _logger.LogInformation("Cancelled reservation {ReservationId} due to 30-minute timeout.", res.Id);
                }

                if (expiredReservations.Any())
                {
                    await db.SaveChangesAsync(stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred executing ReservationTimeoutService.");
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
