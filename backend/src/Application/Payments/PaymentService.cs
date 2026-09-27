using Application.Common.Exceptions;
using Application.Common.Interfaces;
using Application.Payments.Models;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Application.Payments;

public sealed class PaymentService : IPaymentService
{
    private readonly IAppDbContext _db;

    public PaymentService(IAppDbContext db) => _db = db;

    public async Task<PaymentInvoice> IssueForSessionAsync(
        ChargingSession session,
        Charger charger,
        CancellationToken cancellationToken = default)
    {
        if (session.Invoice is not null || await _db.PaymentInvoices
                .AnyAsync(i => i.SessionId == session.Id, cancellationToken))
            throw new InvalidOperationException("An invoice already exists for this charging session.");

        var reservation = session.Reservation;
        var invoice = PaymentInvoice.Issue(
            session,
            reservation.DriverId,
            charger.Tariff,
            reservation.AdvanceDepositAmount);

        var excessAdvance = reservation.AdvanceDepositAmount - invoice.AdvanceDeducted;
        if (excessAdvance > 0 && reservation.DriverId.HasValue)
        {
            var driver = await _db.Users
                .FirstOrDefaultAsync(u => u.Id == reservation.DriverId.Value, cancellationToken)
                ?? throw new NotFoundException(nameof(User), reservation.DriverId.Value);
            driver.CreditBalance(excessAdvance);
        }

        _db.PaymentInvoices.Add(invoice);
        return invoice;
    }

    public async Task<PaymentInvoiceDto> SettleAsync(
        Guid requesterId,
        string requesterRole,
        Guid invoiceId,
        SettleInvoiceRequest request,
        CancellationToken cancellationToken = default)
    {
        var invoice = await InvoiceQuery(tracking: true)
            .FirstOrDefaultAsync(i => i.Id == invoiceId, cancellationToken)
            ?? throw new NotFoundException(nameof(PaymentInvoice), invoiceId);

        await EnsureCanSettleAsync(requesterId, requesterRole, invoice, request.PaymentMethod, cancellationToken);

        if (request.PaymentMethod == PaymentMethod.Wallet)
        {
            if (!invoice.DriverId.HasValue)
                throw new InvalidOperationException("Walk-in invoices cannot be paid from a wallet.");

            var driver = await _db.Users
                .FirstOrDefaultAsync(u => u.Id == invoice.DriverId.Value, cancellationToken)
                ?? throw new NotFoundException(nameof(User), invoice.DriverId.Value);
            driver.DeductBalance(invoice.NetAmountDue);
        }

        invoice.Settle(request.PaymentMethod);
        await _db.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(invoice, cancellationToken);
    }

    public async Task<IReadOnlyList<PaymentInvoiceDto>> GetInvoicesAsync(
        Guid requesterId,
        string requesterRole,
        InvoiceFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = InvoiceQuery(tracking: false);

        if (requesterRole == UserRole.Driver.ToString())
        {
            if (filter.UserId.HasValue && filter.UserId.Value != requesterId)
                throw new ForbiddenAccessException();
            query = query.Where(i => i.DriverId == requesterId);
        }
        else if (requesterRole == UserRole.StationOwner.ToString())
        {
            query = query.Where(i => _db.Chargers.Any(c =>
                c.Id == i.Session.Reservation.ChargerId &&
                _db.Stations.Any(s => s.Id == c.StationId && s.OwnerId == requesterId)));
            if (filter.UserId.HasValue)
                query = query.Where(i => i.DriverId == filter.UserId.Value);
        }
        else if (requesterRole is nameof(UserRole.Admin) or nameof(UserRole.SupportManager))
        {
            if (filter.UserId.HasValue)
                query = query.Where(i => i.DriverId == filter.UserId.Value);
        }
        else
        {
            throw new ForbiddenAccessException();
        }

        if (filter.Status.HasValue)
            query = query.Where(i => i.Status == filter.Status.Value);

        var invoices = await query.OrderByDescending(i => i.IssuedAt).ToListAsync(cancellationToken);
        var result = new List<PaymentInvoiceDto>(invoices.Count);
        foreach (var invoice in invoices)
            result.Add(await ToDtoAsync(invoice, cancellationToken));
        return result;
    }

    public async Task<PaymentInvoiceDto> ToDtoAsync(
        PaymentInvoice invoice,
        CancellationToken cancellationToken = default)
    {
        var charger = await _db.Chargers.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == invoice.Session.Reservation.ChargerId, cancellationToken)
            ?? throw new NotFoundException(nameof(Charger), invoice.Session.Reservation.ChargerId);
        var stationName = await _db.Stations.AsNoTracking()
            .Where(s => s.Id == charger.StationId)
            .Select(s => s.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;

        return new PaymentInvoiceDto
        {
            Id = invoice.Id,
            SessionId = invoice.SessionId,
            DriverId = invoice.DriverId,
            ChargerId = charger.Id,
            StationName = stationName,
            ChargerIdentifier = charger.Identifier,
            BayLabel = charger.BayLabel,
            EnergyDeliveredKwh = invoice.Session.FinalEnergyDeliveredKwh ?? 0,
            TariffPerKwh = invoice.TariffPerKwh,
            GrossAmount = invoice.GrossAmount,
            AdvanceDeducted = invoice.AdvanceDeducted,
            NetAmountDue = invoice.NetAmountDue,
            PaymentMethod = invoice.PaymentMethod,
            Status = invoice.Status,
            IssuedAt = invoice.IssuedAt,
            SettledAt = invoice.SettledAt
        };
    }

    private IQueryable<PaymentInvoice> InvoiceQuery(bool tracking)
    {
        var query = _db.PaymentInvoices
            .Include(i => i.Session)
            .ThenInclude(s => s.Reservation)
            .AsQueryable();
        return tracking ? query : query.AsNoTracking();
    }

    private async Task EnsureCanSettleAsync(
        Guid requesterId,
        string requesterRole,
        PaymentInvoice invoice,
        PaymentMethod method,
        CancellationToken cancellationToken)
    {
        if (requesterRole == UserRole.Admin.ToString()) return;

        if (requesterRole == UserRole.Driver.ToString())
        {
            if (invoice.DriverId != requesterId || method != PaymentMethod.Wallet)
                throw new ForbiddenAccessException();
            return;
        }

        if (requesterRole == UserRole.StationOwner.ToString() &&
            await OwnsChargerAsync(requesterId, invoice.Session.Reservation.ChargerId, cancellationToken))
            return;

        throw new ForbiddenAccessException();
    }

    private Task<bool> OwnsChargerAsync(Guid ownerId, Guid chargerId, CancellationToken cancellationToken) =>
        _db.Chargers.AnyAsync(c => c.Id == chargerId &&
            _db.Stations.Any(s => s.Id == c.StationId && s.OwnerId == ownerId), cancellationToken);
}
