using Application.Common.Interfaces;
using Application.Reservations;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Application.Stations;

public class AvailabilityService : IAvailabilityService
{
    private readonly IAppDbContext _context;
    private readonly IReservationService? _reservationService;

    public AvailabilityService(IAppDbContext context, IServiceProvider serviceProvider)
    {
        _context = context;
        _reservationService = serviceProvider.GetService(typeof(IReservationService)) as IReservationService;
    }

    public async Task<bool> IsChargerAvailableAsync(Guid chargerId, DateTimeOffset checkTime, CancellationToken cancellationToken = default)
    {
        return await IsChargerAvailableForPeriodAsync(chargerId, checkTime, checkTime.AddMinutes(1), cancellationToken);
    }

    public async Task<bool> IsChargerAvailableForPeriodAsync(Guid chargerId, DateTimeOffset startTime, DateTimeOffset endTime, CancellationToken cancellationToken = default)
    {
        var charger = await _context.Chargers
            .Include(c => c.Station)
                .ThenInclude(s => s.OperatingHours)
            .Include(c => c.MaintenanceWindows)
            .FirstOrDefaultAsync(c => c.Id == chargerId, cancellationToken);

        if (charger == null) return false;

        // Station Level Validation
        if (charger.Station.Status != StationStatus.Active)
            return false;
            
        // Check Operating Hours
        var dayOfWeek = (int)startTime.DayOfWeek;
        var operatingHour = charger.Station.OperatingHours.FirstOrDefault(o => o.DayOfWeek == dayOfWeek);
        if (operatingHour == null || !operatingHour.IsEnabled) return false;

        var timeOfDay = startTime.TimeOfDay;
        var endTimeOfDay = endTime.TimeOfDay;
        if (timeOfDay < operatingHour.OpenTime || endTimeOfDay > operatingHour.CloseTime)
            return false;

        // Charger Level Validation
        if (charger.Status == ChargerStatus.Offline || charger.Status == ChargerStatus.Maintenance)
            return false;

        // Check Maintenance Windows
        var hasMaintenance = charger.MaintenanceWindows.Any(m => 
            (startTime >= m.StartTime && startTime < m.EndTime) ||  // overlaps start
            (endTime > m.StartTime && endTime <= m.EndTime) ||      // overlaps end
            (startTime <= m.StartTime && endTime >= m.EndTime)      // envelopes maintenance
        );
        if (hasMaintenance) return false;

        // Active Reservations Validation
        if (_reservationService != null)
        {
            var hasReservation = await _reservationService.HasActiveReservationAsync(chargerId, startTime, endTime, cancellationToken);
            if (hasReservation) return false;
        }

        return true;
    }
}
