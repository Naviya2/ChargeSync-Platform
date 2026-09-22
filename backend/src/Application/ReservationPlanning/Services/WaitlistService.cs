using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.ReservationPlanning.DTOs;
using Application.ReservationPlanning.Models;
using Domain.Entities;
using Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Application.ReservationPlanning;

/// <inheritdoc cref="IWaitlistService"/>
public sealed class WaitlistService : IWaitlistService
{
    private readonly IAppDbContext _db;

    public WaitlistService(IAppDbContext db) => _db = db;

    // ── Join waitlist ─────────────────────────────────────────────────────────

    public async Task<WaitlistEntryDto> JoinAsync(
        Guid driverId,
        WaitlistRequest request,
        CancellationToken cancellationToken = default)
    {
        var chargerExists = await _db.Chargers
            .AnyAsync(c => c.Id == request.ChargerId, cancellationToken);
        if (!chargerExists)
            throw new NotFoundException(nameof(Charger), request.ChargerId);

        // Prevent a driver from joining the same charger waitlist twice.
        var alreadyWaiting = await _db.WaitlistEntries
            .AnyAsync(w =>
                w.ChargerId == request.ChargerId &&
                w.DriverId == driverId &&
                w.Status == WaitlistStatus.Waiting,
                cancellationToken);

        if (alreadyWaiting)
            throw new InvalidOperationException(
                "You are already on the waitlist for this charger.");

        var entry = WaitlistEntry.Create(driverId, request.ChargerId, request.RequestedStartTime);
        _db.WaitlistEntries.Add(entry);
        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(entry);
    }

    // ── List driver's own waitlist entries ────────────────────────────────────

    public async Task<IReadOnlyList<WaitlistEntryDto>> GetMineAsync(
        Guid driverId,
        CancellationToken cancellationToken = default)
    {
        return await _db.WaitlistEntries
            .AsNoTracking()
            .Where(w => w.DriverId == driverId && w.Status == WaitlistStatus.Waiting)
            .OrderBy(w => w.Priority)
            .ThenBy(w => w.CreatedAt)
            .Select(w => new WaitlistEntryDto
            {
                Id = w.Id,
                ChargerId = w.ChargerId,
                DriverId = w.DriverId,
                RequestedStartTime = w.RequestedStartTime,
                Priority = w.Priority,
                Status = w.Status,
                CreatedAt = w.CreatedAt
            })
            .ToListAsync(cancellationToken);
    }

    // ── Promote next entry ────────────────────────────────────────────────────

    public async Task<bool> TryPromoteNextAsync(
        Guid chargerId,
        DateTimeOffset slotStart,
        DateTimeOffset slotEnd,
        CancellationToken cancellationToken = default)
    {
        // Find the highest-priority waiting entry for this charger.
        // Lower Priority value = higher queue position; FIFO within the same priority level.
        var next = await _db.WaitlistEntries
            .Where(w =>
                w.ChargerId == chargerId &&
                w.Status == WaitlistStatus.Waiting)
            .OrderBy(w => w.Priority)
            .ThenBy(w => w.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (next is null) return false;

        // Promote the waitlist entry.
        next.Promote();

        // Create a confirmed reservation for the promoted driver using the freed slot.
        var promoted = Reservation.Create(
            next.DriverId,
            chargerId,
            slotStart,
            slotEnd,
            advanceDepositAmount: 0m); // Promoted entries do not require advance payment.

        var qrToken = Convert.ToHexString(
            System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));
        promoted.ConfirmWithQrCode(qrToken);

        _db.Reservations.Add(promoted);

        // Record the initial history for the promoted reservation.
        _db.ReservationStatusHistories.Add(
            ReservationStatusHistory.Record(
                promoted.Id,
                oldStatus: null,
                newStatus: ReservationStatus.Confirmed,
                changedByUserId: null)); // System-automated transition.

        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static WaitlistEntryDto ToDto(WaitlistEntry w) => new()
    {
        Id = w.Id,
        ChargerId = w.ChargerId,
        DriverId = w.DriverId,
        RequestedStartTime = w.RequestedStartTime,
        Priority = w.Priority,
        Status = w.Status,
        CreatedAt = w.CreatedAt
    };
}
