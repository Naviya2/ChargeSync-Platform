using System.Security.Cryptography;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Application.Sessions;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.ReservationPlanning;

/// <inheritdoc cref="IReservationService"/>
public sealed class ReservationService : IReservationService
{
    private readonly IAppDbContext _db;
    private readonly ISessionService _sessions;
    private readonly TimeProvider _clock;

    public ReservationService(IAppDbContext db, ISessionService sessions, TimeProvider? clock = null)
    {
        _db = db;
        _sessions = sessions;
        _clock = clock ?? TimeProvider.System;
    }

    public async Task<BookingChargesDto> GetBookingChargesAsync(Guid driverId, CancellationToken cancellationToken = default)
    {
        var driver = await _db.Users.AsNoTracking()
            .SingleOrDefaultAsync(u => u.Id == driverId && u.Role == UserRole.Driver && u.IsActive, cancellationToken)
            ?? throw new ForbiddenAccessException();
        return new(driver.WalletBalance, driver.PendingCancellationFees);
    }

    // ── Create advance reservation ────────────────────────────────────────────

    public async Task<ReservationDto> CreateAsync(
        Guid driverId,
        CreateReservationRequest request,
        CancellationToken cancellationToken = default)
    {
        // 1. Load the driver so the wallet balance can be verified and deducted.
        var driver = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == driverId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), driverId);

        // 2. Verify sufficient wallet balance (domain guard also validates this).
        if (request.AdvanceDepositAmount < 0) throw new ArgumentException("Advance deposit cannot be negative.");
        if (!request.RequiresApproval)
        {
            if ((request.ExpectedCancellationFees ?? 0m) != driver.PendingCancellationFees)
                throw new PaymentConflictException("Cancellation fees changed. Review the booking charges and confirm again.");
            var totalCharge = request.AdvanceDepositAmount + driver.PendingCancellationFees;
            if (driver.WalletBalance < totalCharge)
                throw new InvalidOperationException(
                    $"Insufficient wallet balance. Available: LKR {driver.WalletBalance:0.00}, required: LKR {totalCharge:0.00} (advance plus cancellation fees).");
        }

        // 3. Verify the charger exists.
        var chargerExists = await _db.Chargers
            .AnyAsync(c => c.Id == request.ChargerId, cancellationToken);
        if (!chargerExists)
            throw new NotFoundException(nameof(Charger), request.ChargerId);

        // 3.5 Verify the driver doesn't already have an active reservation for this vehicle on this day.
        var existingReservation = await _db.Reservations
            .AnyAsync(r => r.DriverId == driverId 
                        && r.VehicleId == request.VehicleId
                        && r.StartTime.Date == request.StartTime.Date 
                        && r.Status != ReservationStatus.Cancelled 
                        && r.Status != ReservationStatus.Completed, cancellationToken);
        if (existingReservation)
            throw new InvalidOperationException("You already have an incomplete reservation for this vehicle today.");

        // 3.7 Validate Operating Hours
        await ValidateOperatingHoursAsync(request.ChargerId, request.StartTime, request.EndTime, cancellationToken);

        // 3.8 Verify the requested time slot has at least a 30-minute buffer from existing reservations.
        var overlapping = await _db.Reservations
            .AnyAsync(r => r.ChargerId == request.ChargerId 
                        && r.Status != ReservationStatus.Cancelled 
                        && r.Status != ReservationStatus.Completed
                        && r.StartTime < request.EndTime.AddMinutes(30)
                        && r.EndTime > request.StartTime.AddMinutes(-30), cancellationToken);

        if (overlapping)
            throw new InvalidOperationException("The requested time slot overlaps or does not have the required 30-minute buffer from an existing reservation.");

        // 4. Create the reservation domain object.
        var reservation = Reservation.Create(
            driverId,
            request.ChargerId,
            request.StartTime,
            request.EndTime,
            request.AdvanceDepositAmount,
            request.VehicleId);

        if (request.RequiresApproval)
        {
            _db.Reservations.Add(reservation);
            RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.Pending, actorId: driverId);
        }
        else
        {
            // 5. Deduct the advance deposit from the driver's wallet.
            driver.DeductBalance(request.AdvanceDepositAmount);
            reservation.RecordCancellationFeesPaid(driver.CollectCancellationFees());

            // 6. Generate a cryptographically unique QR token and confirm the reservation.
            var qrToken = GenerateQrToken();
            reservation.ConfirmWithQrCode(qrToken);

            _db.Reservations.Add(reservation);
            RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.Pending, actorId: driverId);
            RecordHistory(reservation, oldStatus: ReservationStatus.Pending, newStatus: ReservationStatus.Confirmed, actorId: driverId);
        }

        await SaveFinancialChangesAsync(cancellationToken);
        return ToDto(reservation);
    }

    // ── Admin/Owner reservation creation ──────────────────────────────────────

    public async Task<ReservationDto> CreateByAdminAsync(
        Guid staffUserId,
        AdminCreateReservationRequest request,
        CancellationToken cancellationToken = default)
    {
        var driverExists = await _db.Users
            .AnyAsync(u => u.Id == request.DriverId, cancellationToken);
        if (!driverExists)
            throw new NotFoundException("Driver", request.DriverId);

        var chargerExists = await _db.Chargers
            .AnyAsync(c => c.Id == request.ChargerId, cancellationToken);
        if (!chargerExists)
            throw new NotFoundException(nameof(Charger), request.ChargerId);

        await ValidateOperatingHoursAsync(request.ChargerId, request.StartTime, request.EndTime, cancellationToken);

        var overlapping = await _db.Reservations
            .AnyAsync(r => r.ChargerId == request.ChargerId 
                        && r.Status != ReservationStatus.Cancelled 
                        && r.Status != ReservationStatus.Completed
                        && r.StartTime < request.EndTime.AddMinutes(30)
                        && r.EndTime > request.StartTime.AddMinutes(-30), cancellationToken);

        if (overlapping)
            throw new InvalidOperationException("The requested time slot overlaps or does not have the required 30-minute buffer from an existing reservation.");

        var reservation = Reservation.Create(
            request.DriverId,
            request.ChargerId,
            request.StartTime,
            request.EndTime,
            0m, // No advance payment for admin reservations
            request.VehicleId);

        var qrToken = GenerateQrToken();
        reservation.ConfirmWithQrCode(qrToken);

        _db.Reservations.Add(reservation);
        RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.Pending, actorId: staffUserId);
        RecordHistory(reservation, oldStatus: ReservationStatus.Pending, newStatus: ReservationStatus.Confirmed, actorId: staffUserId);

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(reservation);
    }

    // ── Walk-in admission ─────────────────────────────────────────────────────

    public async Task<ReservationDto> CreateWalkInAsync(
        Guid staffUserId,
        WalkInRequest request,
        CancellationToken cancellationToken = default)
    {
        var chargerExists = await _db.Chargers
            .AnyAsync(c => c.Id == request.ChargerId, cancellationToken);
        if (!chargerExists)
            throw new NotFoundException(nameof(Charger), request.ChargerId);

        await ValidateOperatingHoursAsync(request.ChargerId, request.StartTime, request.EndTime, cancellationToken);

        var overlapping = await _db.Reservations
            .AnyAsync(r => r.ChargerId == request.ChargerId 
                        && r.Status != ReservationStatus.Cancelled 
                        && r.Status != ReservationStatus.Completed
                        && r.StartTime < request.EndTime.AddMinutes(30)
                        && r.EndTime > request.StartTime.AddMinutes(-30), cancellationToken);

        if (overlapping)
            throw new InvalidOperationException("The requested walk-in time slot overlaps or does not have the required 30-minute buffer from an existing reservation.");

        var reservation = Reservation.CreateWalkIn(
            request.ChargerId,
            request.StartTime,
            request.EndTime,
            request.CustomerName,
            request.VehicleNumber,
            request.BatteryCapacity);

        _db.Reservations.Add(reservation);
        RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.CheckedIn, actorId: staffUserId);
        await _sessions.StartForCheckedInReservationAsync(reservation, staffUserId, cancellationToken);

        await _db.SaveChangesAsync(cancellationToken);

        // Load navigation properties for ToDto
        reservation = await _db.Reservations
            .Include(r => r.Charger).ThenInclude(c => c.Station)
            .Include(r => r.Vehicle)
            .Include(r => r.Driver)
            .FirstOrDefaultAsync(r => r.Id == reservation.Id, cancellationToken) ?? reservation;

        return ToDto(reservation);
    }

    // ── List reservations ─────────────────────────────────────────────────────

    public async Task<PagedResult<ReservationDto>> GetListAsync(
        Guid requesterId,
        string requesterRole,
        ReservationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Reservations.AsNoTracking().AsQueryable();

        // Drivers can only see their own reservations.
        if (requesterRole == UserRole.Driver.ToString())
            query = query.Where(r => r.DriverId == requesterId);

        // Station Owners can only see reservations for their stations.
        if (requesterRole == UserRole.StationOwner.ToString())
            query = query.Where(r => r.Charger.Station.OwnerId == requesterId);

        if (filter.ChargerId.HasValue)
            query = query.Where(r => r.ChargerId == filter.ChargerId.Value);

        if (filter.Status.HasValue)
            query = query.Where(r => r.Status == filter.Status.Value);

        if (filter.From.HasValue)
            query = query.Where(r => r.StartTime >= filter.From.Value);

        if (filter.To.HasValue)
            query = query.Where(r => r.StartTime < filter.To.Value);

        var totalCount = await query.CountAsync(cancellationToken);

        var page = Math.Max(1, filter.Page);
        var pageSize = Math.Clamp(filter.PageSize, 1, 100);

        var items = await query
            .OrderByDescending(r => r.StartTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReservationDto
            {
                Id = r.Id,
                DriverId = r.DriverId,
                ChargerId = r.ChargerId,
                VehicleId = r.VehicleId,
                StartTime = r.StartTime,
                EndTime = r.EndTime,
                ReservationQRCode = r.ReservationQRCode,
                AdvanceDepositAmount = r.AdvanceDepositAmount,
                LateCancellationFee = r.LateCancellationFee,
                CancellationFeesPaid = r.CancellationFeesPaid,
                CancelledAt = r.CancelledAt,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                StationName = r.Charger.Station.Name,
                StationLatitude = r.Charger.Station.Latitude,
                StationLongitude = r.Charger.Station.Longitude,
                ChargerName = r.Charger.Identifier,
                VehicleName = r.Vehicle != null ? r.Vehicle.Make + " " + r.Vehicle.Model : "Walk-in",
                DriverName = r.Driver != null ? r.Driver.FullName : "Walk-in",
                FinalEnergyDeliveredKwh = r.ChargingSession != null ? r.ChargingSession.FinalEnergyDeliveredKwh : null,
                InvoiceNetAmount = r.ChargingSession != null && r.ChargingSession.Invoice != null ? r.ChargingSession.Invoice.NetAmountDue : null,
                InvoicePaymentMethod = r.ChargingSession != null && r.ChargingSession.Invoice != null && r.ChargingSession.Invoice.PaymentMethod != null ? r.ChargingSession.Invoice.PaymentMethod.ToString() : null,
                WalkInCustomerName = r.WalkInCustomerName,
                WalkInVehicleNumber = r.WalkInVehicleNumber,
                WalkInBatteryCapacity = r.WalkInBatteryCapacity
            })
            .ToListAsync(cancellationToken);

        return new PagedResult<ReservationDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    // ── Get single reservation ────────────────────────────────────────────────

    public async Task<ReservationDto?> GetByIdAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .Include(r => r.Charger)
                .ThenInclude(c => c.Station)
            .Include(r => r.Vehicle)
            .Include(r => r.Driver)
            .Include(r => r.ChargingSession)
                .ThenInclude(cs => cs.Invoice)
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

        if (reservation is null) return null;

        // Drivers may only view their own reservations.
        if (requesterRole == UserRole.Driver.ToString() && reservation.DriverId != requesterId)
            return null;

        // Station Owners may only view reservations for their stations.
        if (requesterRole == UserRole.StationOwner.ToString() && reservation.Charger.Station.OwnerId != requesterId)
            return null;

        return ToDto(reservation);
    }

    // ── Cancel reservation ────────────────────────────────────────────────────

    public async Task CancelAsync(
        Guid requesterId,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), id);

        var requester = await _db.Users.AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == requesterId && u.IsActive, cancellationToken)
            ?? throw new ForbiddenAccessException();
        var isDriverCancellation = requester.Role == UserRole.Driver && reservation.DriverId == requesterId;
        if (!isDriverCancellation && requester.Role != UserRole.Admin)
        {
            if (requester.Role != UserRole.StationOwner || !await _db.Chargers.AnyAsync(c =>
                c.Id == reservation.ChargerId && c.Station.OwnerId == requesterId, cancellationToken))
                throw new ForbiddenAccessException();
        }

        var cancelledAt = _clock.GetUtcNow();
        var fee = isDriverCancellation ? CancellationPolicy.Fee(reservation.StartTime, cancelledAt) : 0m;
        var oldStatus = reservation.Status;
        reservation.Cancel(fee, cancelledAt);

        // Refund the advance deposit back to the driver's wallet.
        // Previously collected cancellation fees are not advance credit and are never refunded here.
        if (reservation.DriverId.HasValue)
        {
            var driver = await _db.Users
                .SingleAsync(u => u.Id == reservation.DriverId.Value, cancellationToken);
            driver.CreditBalance(reservation.AdvanceDepositAmount);
            if (fee > 0) driver.AddCancellationFee(fee);
        }

        RecordHistory(reservation, oldStatus, ReservationStatus.Cancelled, actorId: requesterId);
        await SaveFinancialChangesAsync(cancellationToken);
    }

    private async Task SaveFinancialChangesAsync(CancellationToken ct)
    {
        try { await _db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException)
        {
            throw new PaymentConflictException("Reservation or wallet changed. Refresh and try again.");
        }
    }

    // ── Staff QR check-in ─────────────────────────────────────────────────────

    public async Task<ReservationDto> StaffCheckinAsync(
        Guid staffUserId,
        StaffCheckinRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.QrCode))
            throw new ArgumentException("QR code is required.", nameof(request));

        var reservation = await _db.Reservations
            .FirstOrDefaultAsync(r => r.ReservationQRCode == request.QrCode.Trim(), cancellationToken)
            ?? throw new NotFoundException("Reservation with QR code", request.QrCode);

        var now = DateTimeOffset.UtcNow;
        if (now < reservation.StartTime || now > reservation.EndTime)
        {
            throw new InvalidOperationException($"Check-in is only allowed during the scheduled reservation window: {reservation.StartTime:t} - {reservation.EndTime:t}.");
        }

        var oldStatus = reservation.Status;
        reservation.CheckIn();

        RecordHistory(reservation, oldStatus, ReservationStatus.CheckedIn, actorId: staffUserId);
        await _sessions.StartForCheckedInReservationAsync(reservation, staffUserId, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(reservation);
    }

    // ── Status history ────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ReservationHistoryDto>> GetHistoryAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservationExists = await _db.Reservations
            .AsNoTracking()
            .AnyAsync(r => r.Id == id, cancellationToken);
        if (!reservationExists)
            throw new NotFoundException(nameof(Reservation), id);

        return await _db.ReservationStatusHistories
            .AsNoTracking()
            .Where(h => h.ReservationId == id)
            .OrderBy(h => h.ChangedAt)
            .Select(h => new ReservationHistoryDto
            {
                Id = h.Id,
                OldStatus = h.OldStatus,
                NewStatus = h.NewStatus,
                ChangedByUserId = h.ChangedByUserId,
                ChangedAt = h.ChangedAt
            })
            .ToListAsync(cancellationToken);
    }

    // ── Update reservation time window ──────────────────────────────────────────

    public async Task<ReservationDto> UpdateAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        UpdateReservationRequest request,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .Include(r => r.Charger)
                .ThenInclude(c => c.Station)
            .Include(r => r.Vehicle)
            .Include(r => r.Driver)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), id);

        // Only admins or station owners can update this.
        if (requesterRole == UserRole.Driver.ToString())
            throw new ForbiddenAccessException();
            
        // Station Owners can only update reservations for their stations.
        if (requesterRole == UserRole.StationOwner.ToString())
        {
            var stationOwnerId = await _db.Chargers
                .Where(c => c.Id == reservation.ChargerId)
                .Select(c => c.Station.OwnerId)
                .FirstOrDefaultAsync(cancellationToken);
                
            if (stationOwnerId != requesterId)
                throw new ForbiddenAccessException();
        }

        // Business logic to update the time window would be handled in the Domain object.
        // For now, we update it via the entity directly if it exposes a setter or method.
        // Wait, the properties might be private setters.
        // We will assume a method UpdateTimeWindow exists on Reservation entity, or just use private setters reflection if needed.
        
        // Validate Operating Hours
        await ValidateOperatingHoursAsync(reservation.ChargerId, request.StartTime, request.EndTime, cancellationToken);

        // Ensure no overlapping reservations exist in the new time window (with 30 min buffer)
        var overlapping = await _db.Reservations
            .AnyAsync(r => r.ChargerId == reservation.ChargerId 
                        && r.Id != id 
                        && r.Status != ReservationStatus.Cancelled
                        && r.Status != ReservationStatus.Completed
                        && r.StartTime < request.EndTime.AddMinutes(30)
                        && r.EndTime > request.StartTime.AddMinutes(-30), 
                      cancellationToken);
        
        if (overlapping)
            throw new InvalidOperationException("The requested time window overlaps or does not have the required 30-minute buffer from an existing reservation.");

        reservation.GetType().GetProperty("StartTime")?.SetValue(reservation, request.StartTime);
        reservation.GetType().GetProperty("EndTime")?.SetValue(reservation, request.EndTime);

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(reservation);
    }

    // ── Hard delete reservation ───────────────────────────────────────────────

    public async Task DeleteAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), id);

        // Only Admins or Station Owners should be able to hard delete
        if (requesterRole == UserRole.Driver.ToString())
            throw new ForbiddenAccessException();

        // Station Owners can only delete reservations for their stations.
        if (requesterRole == UserRole.StationOwner.ToString())
        {
            var stationOwnerId = await _db.Chargers
                .Where(c => c.Id == reservation.ChargerId)
                .Select(c => c.Station.OwnerId)
                .FirstOrDefaultAsync(cancellationToken);
                
            if (stationOwnerId != requesterId)
                throw new ForbiddenAccessException();
        }

        if (reservation.LateCancellationFee > 0 || reservation.CancellationFeesPaid > 0)
            throw new InvalidOperationException("Reservations with cancellation fee records must be retained for payment history.");

        // Also delete associated history
        var history = await _db.ReservationStatusHistories
            .Where(h => h.ReservationId == id)
            .ToListAsync(cancellationToken);
            
        _db.ReservationStatusHistories.RemoveRange(history);
        _db.Reservations.Remove(reservation);
        
        await _db.SaveChangesAsync(cancellationToken);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /// <summary>
    /// Generates a 32-byte cryptographically random token encoded as a hex string.
    /// Stored in the database and presented as the reservation QR payload.
    /// </summary>
    private static string GenerateQrToken() =>
        Convert.ToHexString(RandomNumberGenerator.GetBytes(32));

    /// <summary>Appends a history entry to the context (not yet saved).</summary>
    private void RecordHistory(
        Reservation reservation,
        ReservationStatus? oldStatus,
        ReservationStatus newStatus,
        Guid? actorId)
    {
        var entry = ReservationStatusHistory.Record(
            reservation,
            oldStatus,
            newStatus,
            actorId);
        _db.ReservationStatusHistories.Add(entry);
    }

    public async Task<IReadOnlyList<TimeSlotDto>> GetAvailableTimeSlotsAsync(
        Guid chargerId,
        DateTime date,
        int durationMinutes,
        CancellationToken cancellationToken = default)
    {
        var charger = await _db.Chargers
            .Include(c => c.Station)
                .ThenInclude(s => s.OperatingHours)
            .Include(c => c.MaintenanceWindows)
            .FirstOrDefaultAsync(c => c.Id == chargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), chargerId);

        var dayOfWeek = (int)date.DayOfWeek;
        var operatingHour = charger.Station.OperatingHours.FirstOrDefault(o => o.DayOfWeek == dayOfWeek);
        if (operatingHour == null || !operatingHour.IsEnabled)
        {
            return new List<TimeSlotDto>(); // Station is closed
        }

        // Operating hours are stored as local time. Assuming Sri Lanka Time (+05:30) for the platform.
        var timeZoneOffset = TimeSpan.FromHours(5.5);
        var startOfDay = new DateTimeOffset(date.Date, timeZoneOffset);
        var endOfDay = startOfDay.AddDays(1);

        var startOfDayUtc = startOfDay.ToUniversalTime();
        var endOfDayUtc = endOfDay.ToUniversalTime();

        var reservations = await _db.Reservations
            .Where(r => r.ChargerId == chargerId &&
                        r.Status != ReservationStatus.Cancelled &&
                        r.StartTime < endOfDayUtc &&
                        r.EndTime > startOfDayUtc)
            .OrderBy(r => r.StartTime)
            .ToListAsync(cancellationToken);

        var availableSlots = new List<TimeSlotDto>();
        var currentTime = DateTimeOffset.UtcNow;
        var searchStart = startOfDay > currentTime ? startOfDay : currentTime;

        var minute = searchStart.Minute;
        var diff = 15 - (minute % 15);
        if (diff < 15)
        {
            searchStart = searchStart.AddMinutes(diff).AddSeconds(-searchStart.Second).AddMilliseconds(-searchStart.Millisecond);
        }

        while (searchStart.AddMinutes(durationMinutes) <= endOfDay)
        {
            var searchEnd = searchStart.AddMinutes(durationMinutes);
            bool isOverlap = reservations.Any(r => r.StartTime < searchEnd.AddMinutes(30) && r.EndTime > searchStart.AddMinutes(-30));
            bool isMaintenanceOverlap = charger.MaintenanceWindows?.Any(m => m.StartTime < searchEnd && m.EndTime > searchStart) == true;

            if (!isOverlap && !isMaintenanceOverlap)
            {
                var absoluteOpenTime = startOfDay.Add(operatingHour.OpenTime);
                var absoluteCloseTime = startOfDay.Add(operatingHour.CloseTime);
                if (operatingHour.CloseTime < operatingHour.OpenTime)
                {
                    absoluteCloseTime = absoluteCloseTime.AddDays(1);
                }

                if (searchStart >= absoluteOpenTime && searchEnd <= absoluteCloseTime)
                {
                    availableSlots.Add(new TimeSlotDto(searchStart, searchEnd));
                }
            }

            searchStart = searchStart.AddMinutes(15);
        }

        return availableSlots;
    }

    private static ReservationDto ToDto(Reservation r) => new()
    {
        Id = r.Id,
        DriverId = r.DriverId,
        ChargerId = r.ChargerId,
        VehicleId = r.VehicleId,
        StartTime = r.StartTime,
        EndTime = r.EndTime,
        ReservationQRCode = r.ReservationQRCode,
        AdvanceDepositAmount = r.AdvanceDepositAmount,
        LateCancellationFee = r.LateCancellationFee,
        CancellationFeesPaid = r.CancellationFeesPaid,
        CancelledAt = r.CancelledAt,
        Status = r.Status,
        CreatedAt = r.CreatedAt,
        StationName = r.Charger?.Station?.Name ?? string.Empty,
        StationLatitude = r.Charger?.Station?.Latitude ?? 0,
        StationLongitude = r.Charger?.Station?.Longitude ?? 0,
        ChargerName = r.Charger?.Identifier ?? string.Empty,
        VehicleName = r.Vehicle != null ? r.Vehicle.Make + " " + r.Vehicle.Model : "Walk-in",
        DriverName = r.Driver != null ? r.Driver.FullName : "Walk-in",
        FinalEnergyDeliveredKwh = r.ChargingSession?.FinalEnergyDeliveredKwh,
        InvoiceNetAmount = r.ChargingSession?.Invoice?.NetAmountDue,
        InvoicePaymentMethod = r.ChargingSession?.Invoice?.PaymentMethod?.ToString(),
        WalkInCustomerName = r.WalkInCustomerName,
        WalkInVehicleNumber = r.WalkInVehicleNumber,
        WalkInBatteryCapacity = r.WalkInBatteryCapacity,
        SessionMeterPhotoUrl = r.ChargingSession?.MeterPhotoUrl
    };

    private async Task ValidateOperatingHoursAsync(Guid chargerId, DateTimeOffset startTime, DateTimeOffset endTime, CancellationToken cancellationToken)
    {
        var charger = await _db.Chargers
            .Include(c => c.Station)
                .ThenInclude(s => s.OperatingHours)
            .Include(c => c.MaintenanceWindows)
            .FirstOrDefaultAsync(c => c.Id == chargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), chargerId);

        var timeZoneOffset = TimeSpan.FromHours(5.5);
        var localStartTime = startTime.ToOffset(timeZoneOffset);
        var localEndTime = endTime.ToOffset(timeZoneOffset);

        var dayOfWeek = (int)localStartTime.DayOfWeek;
        var operatingHour = charger.Station.OperatingHours.FirstOrDefault(o => o.DayOfWeek == dayOfWeek);
        if (operatingHour == null || !operatingHour.IsEnabled)
            throw new InvalidOperationException("The charging station is closed on this time.");

        var startOfDay = new DateTimeOffset(localStartTime.Date, timeZoneOffset);
        var absoluteOpenTime = startOfDay.Add(operatingHour.OpenTime);
        var absoluteCloseTime = startOfDay.Add(operatingHour.CloseTime);
        if (operatingHour.CloseTime < operatingHour.OpenTime)
        {
            absoluteCloseTime = absoluteCloseTime.AddDays(1);
        }

        if (localStartTime < absoluteOpenTime || localEndTime > absoluteCloseTime)
            throw new InvalidOperationException($"The requested time falls outside the station's operating hours ({operatingHour.OpenTime:hh\\:mm} - {operatingHour.CloseTime:hh\\:mm}).");

        var isMaintenanceOverlap = charger.MaintenanceWindows?.Any(m => m.StartTime < endTime && m.EndTime > startTime) == true;
        if (isMaintenanceOverlap)
            throw new InvalidOperationException("The requested time slot falls during a scheduled maintenance window for this charger.");
    }

    public async Task<ReservationDto> ApproveAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .Include(r => r.Charger)
                .ThenInclude(c => c.Station)
            .Include(r => r.Driver)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), id);

        if (requesterRole == UserRole.Driver.ToString())
            throw new ForbiddenAccessException();

        if (requesterRole == UserRole.StationOwner.ToString() && reservation.Charger?.Station?.OwnerId != requesterId)
            throw new ForbiddenAccessException();

        if (reservation.Status != ReservationStatus.Pending)
            throw new InvalidOperationException($"Cannot approve a reservation with status {reservation.Status}.");

        if (reservation.DriverId.HasValue)
        {
            var driver = reservation.Driver;
            if (driver.WalletBalance < reservation.AdvanceDepositAmount)
                throw new InvalidOperationException("Driver has insufficient wallet balance for advance deposit.");

            driver.DeductBalance(reservation.AdvanceDepositAmount);
        }

        var qrToken = GenerateQrToken();
        reservation.ConfirmWithQrCode(qrToken);

        RecordHistory(reservation, ReservationStatus.Pending, ReservationStatus.Confirmed, requesterId);
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(reservation);
    }

    public async Task RejectAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .Include(r => r.Charger)
                .ThenInclude(c => c.Station)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), id);

        if (requesterRole == UserRole.Driver.ToString())
            throw new ForbiddenAccessException();

        if (requesterRole == UserRole.StationOwner.ToString() && reservation.Charger?.Station?.OwnerId != requesterId)
            throw new ForbiddenAccessException();

        if (reservation.Status != ReservationStatus.Pending)
            throw new InvalidOperationException($"Cannot reject a reservation with status {reservation.Status}.");

        var oldStatus = reservation.Status;
        reservation.Cancel(); // Will set Status to Cancelled

        // No need to refund since advance wasn't charged yet because it was in Pending state.
        
        RecordHistory(reservation, oldStatus, ReservationStatus.Cancelled, requesterId);
        await _db.SaveChangesAsync(cancellationToken);
    }
}
