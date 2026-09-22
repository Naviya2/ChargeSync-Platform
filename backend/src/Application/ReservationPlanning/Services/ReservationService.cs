using System.Security.Cryptography;
using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.ReservationPlanning;

/// <inheritdoc cref="IReservationService"/>
public sealed class ReservationService : IReservationService
{
    private readonly IAppDbContext _db;
    private readonly IWaitlistService _waitlist;

    public ReservationService(IAppDbContext db, IWaitlistService waitlist)
    {
        _db = db;
        _waitlist = waitlist;
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
        if (driver.WalletBalance < request.AdvanceDepositAmount)
            throw new InvalidOperationException(
                $"Insufficient wallet balance. Available: {driver.WalletBalance:C}, required: {request.AdvanceDepositAmount:C}.");

        // 3. Verify the charger exists.
        var chargerExists = await _db.Chargers
            .AnyAsync(c => c.Id == request.ChargerId, cancellationToken);
        if (!chargerExists)
            throw new NotFoundException(nameof(Charger), request.ChargerId);

        // 4. Create the reservation domain object.
        var reservation = Reservation.Create(
            driverId,
            request.ChargerId,
            request.StartTime,
            request.EndTime,
            request.AdvanceDepositAmount,
            request.VehicleId);

        // 5. Deduct the advance deposit from the driver's wallet.
        driver.DeductBalance(request.AdvanceDepositAmount);

        // 6. Generate a cryptographically unique QR token and confirm the reservation.
        var qrToken = GenerateQrToken();
        reservation.ConfirmWithQrCode(qrToken);

        // 7. Persist both the reservation and the wallet update atomically.
        _db.Reservations.Add(reservation);
        RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.Pending, actorId: driverId);
        RecordHistory(reservation, oldStatus: ReservationStatus.Pending, newStatus: ReservationStatus.Confirmed, actorId: driverId);

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

        var reservation = Reservation.CreateWalkIn(
            request.ChargerId,
            request.StartTime,
            request.EndTime);

        _db.Reservations.Add(reservation);
        RecordHistory(reservation, oldStatus: null, newStatus: ReservationStatus.CheckedIn, actorId: staffUserId);

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(reservation);
    }

    // ── List reservations ─────────────────────────────────────────────────────

    public async Task<PagedResult<ReservationSummaryDto>> GetListAsync(
        Guid requesterId,
        string requesterRole,
        ReservationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Reservations.AsNoTracking().AsQueryable();

        // Drivers can only see their own reservations.
        if (requesterRole == UserRole.Driver.ToString())
            query = query.Where(r => r.DriverId == requesterId);

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
            .Select(r => new ReservationSummaryDto
            {
                Id = r.Id,
                DriverId = r.DriverId,
                ChargerId = r.ChargerId,
                StartTime = r.StartTime,
                EndTime = r.EndTime,
                Status = r.Status,
                IsWalkIn = r.DriverId == null
            })
            .ToListAsync(cancellationToken);

        return new PagedResult<ReservationSummaryDto>
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
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

        if (reservation is null) return null;

        // Drivers may only view their own reservations.
        if (requesterRole == UserRole.Driver.ToString() && reservation.DriverId != requesterId)
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

        // Only the owning driver or an admin/staff can cancel.
        if (reservation.DriverId != null && reservation.DriverId != requesterId)
        {
            var requester = await _db.Users.AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == requesterId, cancellationToken)
                ?? throw new NotFoundException(nameof(User), requesterId);

            if (requester.Role == UserRole.Driver)
                throw new ForbiddenAccessException();
        }

        var oldStatus = reservation.Status;
        reservation.Cancel();

        // Refund the advance deposit back to the driver's wallet.
        if (reservation.DriverId.HasValue && reservation.AdvanceDepositAmount > 0)
        {
            var driver = await _db.Users
                .FirstOrDefaultAsync(u => u.Id == reservation.DriverId.Value, cancellationToken);
            driver?.CreditBalance(reservation.AdvanceDepositAmount);
        }

        RecordHistory(reservation, oldStatus, ReservationStatus.Cancelled, actorId: requesterId);
        await _db.SaveChangesAsync(cancellationToken);

        // Attempt to promote the next waitlist entry for this charger slot.
        await _waitlist.TryPromoteNextAsync(
            reservation.ChargerId,
            reservation.StartTime,
            reservation.EndTime,
            cancellationToken);
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

        var oldStatus = reservation.Status;
        reservation.CheckIn();

        RecordHistory(reservation, oldStatus, ReservationStatus.CheckedIn, actorId: staffUserId);
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
            reservation.Id,
            oldStatus,
            newStatus,
            actorId);
        _db.ReservationStatusHistories.Add(entry);
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
        Status = r.Status,
        CreatedAt = r.CreatedAt
    };
}
