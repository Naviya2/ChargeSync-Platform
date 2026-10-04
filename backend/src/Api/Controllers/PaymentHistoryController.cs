using Application.Common.Interfaces;
using Application.Payments;
using Application.Payments.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/payments/history")]
[Authorize(Roles = "Driver")]
public sealed class PaymentHistoryController(DriverPaymentHistoryService history, ICurrentUser user) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DriverPaymentHistoryItemDto>>> Get(CancellationToken ct) =>
        Ok(await history.GetAsync(user.Id!.Value, ct));
}
