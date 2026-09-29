using Application.Common.Interfaces;
using Application.Payments;
using Application.Payments.Models;
using Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/payments/invoices")]
[Authorize]
public sealed class PaymentsController : ControllerBase
{
    private readonly IPaymentService _payments;
    private readonly ICurrentUser _currentUser;

    public PaymentsController(IPaymentService payments, ICurrentUser currentUser)
    {
        _payments = payments;
        _currentUser = currentUser;
    }

    private Guid RequesterId => _currentUser.Id ?? Guid.Empty;
    private string RequesterRole => _currentUser.Role?.ToString() ?? string.Empty;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PaymentInvoiceDto>>> GetInvoices(
        [FromQuery] InvoiceFilter filter,
        CancellationToken cancellationToken)
    {
        var invoices = await _payments.GetInvoicesAsync(
            RequesterId, RequesterRole, filter, cancellationToken);
        return Ok(invoices);
    }

    [HttpGet("{userId:guid}")]
    public async Task<ActionResult<IReadOnlyList<PaymentInvoiceDto>>> GetForUser(
        Guid userId,
        [FromQuery] InvoiceStatus? status,
        CancellationToken cancellationToken)
    {
        var invoices = await _payments.GetInvoicesAsync(
            RequesterId,
            RequesterRole,
            new InvoiceFilter { UserId = userId, Status = status },
            cancellationToken);
        return Ok(invoices);
    }

    [HttpPost("{id:guid}/settle")]
    public async Task<ActionResult<PaymentInvoiceDto>> Settle(
        Guid id,
        [FromBody] SettleInvoiceRequest request,
        CancellationToken cancellationToken)
    {
        var invoice = await _payments.SettleAsync(
            RequesterId, RequesterRole, id, request, cancellationToken);
        return Ok(invoice);
    }
}
