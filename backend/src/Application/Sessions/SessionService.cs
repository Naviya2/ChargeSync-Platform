using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Sessions.Models;
using Application.Payments;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Sessions;

public sealed class SessionService : ISessionService
{
    private readonly IAppDbContext _db;
    private readonly IPaymentService _payments;

    public SessionService(IAppDbContext db, IPaymentService payments)
    {
        _db = db;
        _payments = payments;
    }

    public async Task<ChargingSessionDto> StartAsync(
        Guid requesterId,
        string requesterRole,
        Guid reservationId,
        CancellationToken cancellationToken = default)
    {
        var reservation = await _db.Reservations
            .FirstOrDefaultAsync(r => r.Id == reservationId, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), reservationId);

        await EnsureCanManageAsync(requesterId, requesterRole, reservation.ChargerId, cancellationToken);
        await AddSessionAsync(reservation, requesterId, cancellationToken);
        await MarkChargerOccupiedAsync(reservation.ChargerId, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);

        var session = await _db.ChargingSessions
            .AsNoTracking()
            .Include(s => s.Reservation)
            .SingleAsync(s => s.ReservationId == reservationId, cancellationToken);
        return await ToDtoAsync(session, cancellationToken);
    }

    public async Task StartForCheckedInReservationAsync(
        Reservation reservation,
        Guid staffUserId,
        CancellationToken cancellationToken = default)
    {
        var staff = await _db.Users.AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == staffUserId, cancellationToken)
            ?? throw new NotFoundException(nameof(User), staffUserId);

        await EnsureCanManageAsync(staffUserId, staff.Role.ToString(), reservation.ChargerId, cancellationToken);
        await AddSessionAsync(reservation, staffUserId, cancellationToken);
        await MarkChargerOccupiedAsync(reservation.ChargerId, cancellationToken);
    }

    public async Task<IReadOnlyList<ChargingSessionDto>> GetListAsync(
        Guid requesterId,
        string requesterRole,
        SessionFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.ChargingSessions.AsNoTracking().Include(s => s.Reservation).AsQueryable();

        if (requesterRole == UserRole.Driver.ToString())
            query = query.Where(s => s.Reservation.DriverId == requesterId);
        else if (requesterRole == UserRole.StationOwner.ToString())
            query = query.Where(s => _db.Chargers
                .Where(c => c.Id == s.Reservation.ChargerId)
                .Any(c => _db.Stations.Any(st => st.Id == c.StationId && st.OwnerId == requesterId)));
        else if (requesterRole is not (nameof(UserRole.Admin) or nameof(UserRole.SupportManager)))
            throw new ForbiddenAccessException();

        if (filter.Status.HasValue)
            query = query.Where(s => s.Status == filter.Status.Value);

        return await query.OrderByDescending(s => s.StartTime).Select(s => new ChargingSessionDto
        {
            Id = s.Id,
            HasMeterPhoto = s.MeterPhoto != null,
            ReservationId = s.ReservationId,
            ChargerId = s.Reservation.ChargerId,
            DriverId = s.Reservation.DriverId,
            StationName = _db.Stations
                .Where(st => _db.Chargers.Any(c => c.Id == s.Reservation.ChargerId && c.StationId == st.Id))
                .Select(st => st.Name)
                .FirstOrDefault() ?? string.Empty,
            ChargerIdentifier = _db.Chargers
                .Where(c => c.Id == s.Reservation.ChargerId)
                .Select(c => c.Identifier)
                .FirstOrDefault() ?? string.Empty,
            BayLabel = _db.Chargers
                .Where(c => c.Id == s.Reservation.ChargerId)
                .Select(c => c.BayLabel)
                .FirstOrDefault() ?? string.Empty,
            ChargerPowerKw = _db.Chargers
                .Where(c => c.Id == s.Reservation.ChargerId)
                .Select(c => c.PowerKw)
                .FirstOrDefault(),
            TariffPerKwh = _db.Chargers
                .Where(c => c.Id == s.Reservation.ChargerId)
                .Select(c => c.Tariff)
                .FirstOrDefault(),
            StartTime = s.StartTime,
            EndTime = s.EndTime,
            AutoCalculatedKwh = s.AutoCalculatedKwh,
            StaffOverriddenKwh = s.StaffOverriddenKwh,
            FinalEnergyDeliveredKwh = s.FinalEnergyDeliveredKwh,
            StaffUserId = s.StaffUserId,
            Status = s.Status
        }).ToListAsync(cancellationToken);
    }

    public async Task<ChargingSessionDto?> GetByIdAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var session = await _db.ChargingSessions.AsNoTracking()
            .Include(s => s.Reservation)
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);
        if (session is null) return null;

        if (!await CanReadAsync(requesterId, requesterRole, session, cancellationToken))
            return null;

        return await ToDtoAsync(session, cancellationToken);
    }

    public async Task<SessionCompletionDto> StopAsync(
        Guid requesterId,
        string requesterRole,
        Guid id,
        decimal? staffOverriddenKwh,
        CancellationToken cancellationToken = default,
        MeterPhotoUpload? meterPhoto = null)
    {
        var session = await _db.ChargingSessions
            .Include(s => s.Reservation)
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new NotFoundException(nameof(ChargingSession), id);

        await EnsureCanManageAsync(requesterId, requesterRole, session.Reservation.ChargerId, cancellationToken);
        var charger = await _db.Chargers
            .FirstOrDefaultAsync(c => c.Id == session.Reservation.ChargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), session.Reservation.ChargerId);

        session.Stop(DateTimeOffset.UtcNow, charger.PowerKw, staffOverriddenKwh);
        if (meterPhoto is not null)
            session.AttachMeterPhoto(meterPhoto.Data, meterPhoto.ContentType);
        var invoice = await _payments.IssueForSessionAsync(session, charger, cancellationToken);
        charger.SetStatus(ChargerStatus.Available);
        session.Reservation.Complete();
        _db.ReservationStatusHistories.Add(ReservationStatusHistory.Record(
            session.ReservationId,
            ReservationStatus.CheckedIn,
            ReservationStatus.Completed,
            requesterId));
        await _db.SaveChangesAsync(cancellationToken);
        return new SessionCompletionDto
        {
            Session = await ToDtoAsync(session, cancellationToken),
            Invoice = await _payments.ToDtoAsync(invoice, cancellationToken)
        };
    }

    public async Task<MeterPhotoUpload?> GetMeterPhotoAsync(Guid requesterId, string requesterRole,
        Guid id, CancellationToken cancellationToken = default)
    {
        var session = await _db.ChargingSessions.AsNoTracking().Include(s => s.Reservation)
            .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);
        if (session is null || !await CanReadAsync(requesterId, requesterRole, session, cancellationToken))
            return null;
        return session.MeterPhoto is null ? null : new MeterPhotoUpload(session.MeterPhoto, session.MeterPhotoContentType!);
    }

    private async Task AddSessionAsync(
        Reservation reservation,
        Guid staffUserId,
        CancellationToken cancellationToken)
    {
        if (reservation.ChargingSession is not null || await _db.ChargingSessions
                .AnyAsync(s => s.ReservationId == reservation.Id, cancellationToken))
            throw new InvalidOperationException("A charging session already exists for this reservation.");

        _db.ChargingSessions.Add(ChargingSession.Start(reservation, staffUserId));
    }

    private async Task MarkChargerOccupiedAsync(Guid chargerId, CancellationToken cancellationToken)
    {
        var charger = await _db.Chargers
            .FirstOrDefaultAsync(c => c.Id == chargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), chargerId);

        if (charger.Status != ChargerStatus.Available)
            throw new InvalidOperationException("The charger is not available for a new session.");

        charger.SetStatus(ChargerStatus.Occupied);
    }

    private async Task<bool> CanReadAsync(
        Guid requesterId,
        string requesterRole,
        ChargingSession session,
        CancellationToken cancellationToken)
    {
        if (requesterRole is nameof(UserRole.Admin) or nameof(UserRole.SupportManager)) return true;
        if (requesterRole == UserRole.Driver.ToString())
            return session.Reservation.DriverId == requesterId;
        if (requesterRole != UserRole.StationOwner.ToString()) return false;

        return await OwnsChargerAsync(requesterId, session.Reservation.ChargerId, cancellationToken);
    }

    private async Task EnsureCanManageAsync(
        Guid requesterId,
        string requesterRole,
        Guid chargerId,
        CancellationToken cancellationToken)
    {
        if (requesterRole == UserRole.Admin.ToString()) return;
        if (requesterRole != UserRole.StationOwner.ToString() ||
            !await OwnsChargerAsync(requesterId, chargerId, cancellationToken))
            throw new ForbiddenAccessException();
    }

    private Task<bool> OwnsChargerAsync(Guid requesterId, Guid chargerId, CancellationToken cancellationToken) =>
        _db.Chargers.AnyAsync(c => c.Id == chargerId &&
            _db.Stations.Any(s => s.Id == c.StationId && s.OwnerId == requesterId), cancellationToken);

    private async Task<ChargingSessionDto> ToDtoAsync(
        ChargingSession session,
        CancellationToken cancellationToken)
    {
        var charger = await _db.Chargers.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == session.Reservation.ChargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), session.Reservation.ChargerId);
        var stationName = await _db.Stations.AsNoTracking()
            .Where(s => s.Id == charger.StationId)
            .Select(s => s.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;

        return new ChargingSessionDto
        {
            Id = session.Id,
            HasMeterPhoto = session.MeterPhoto != null,
            ReservationId = session.ReservationId,
            ChargerId = charger.Id,
            DriverId = session.Reservation.DriverId,
            StationName = stationName,
            ChargerIdentifier = charger.Identifier,
            BayLabel = charger.BayLabel,
            ChargerPowerKw = charger.PowerKw,
            TariffPerKwh = charger.Tariff,
            StartTime = session.StartTime,
            EndTime = session.EndTime,
            AutoCalculatedKwh = session.AutoCalculatedKwh,
            StaffOverriddenKwh = session.StaffOverriddenKwh,
            FinalEnergyDeliveredKwh = session.FinalEnergyDeliveredKwh,
            StaffUserId = session.StaffUserId,
            Status = session.Status
        };
    }
}
