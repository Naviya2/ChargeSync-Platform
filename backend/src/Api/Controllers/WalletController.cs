using System.Net;
using System.Security.Cryptography;
using Application.Common.Interfaces;
using Application.Common.Exceptions;
using Application.Wallets;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/wallet")]
[Authorize(Roles = "Driver")]
public sealed class WalletController(WalletService wallet, IWalletGateway gateway, ICurrentUser user,
    IDataProtectionProvider protection, IServiceScopeFactory scopes) : ControllerBase
{
    private ITimeLimitedDataProtector Tickets => protection.CreateProtector("ChargeSync.WalletCheckout.v1").ToTimeLimitedDataProtector();

    [HttpGet]
    public async Task<IActionResult> Overview(CancellationToken ct) => Ok(await wallet.Overview(user.Id!.Value, ct));

    [HttpPost("top-ups")]
    public async Task<IActionResult> Start(StartTopUpRequest request, CancellationToken ct)
    {
        var topUp = await wallet.Start(user.Id!.Value, request, ct);
        var ticket = Tickets.Protect(topUp.Id.ToString(), TimeSpan.FromMinutes(30));
        return Ok(new { topUp = WalletService.ToDto(topUp), checkoutUrl = gateway.PublicBaseUrl +
            "/api/wallet/payhere/checkout?ticket=" + Uri.EscapeDataString(ticket) });
    }

    // A short-lived encrypted capability opens only this checkout; the app's JWT is never put in a URL.
    [AllowAnonymous]
    [HttpGet("payhere/checkout")]
    public async Task<IActionResult> Checkout(string ticket, CancellationToken ct)
    {
        Guid id;
        try { id = Guid.Parse(Tickets.Unprotect(ticket)); }
        catch (Exception ex) when (ex is CryptographicException or FormatException)
        { return BadRequest("Checkout link expired or invalid. Return to ChargeSync and try again."); }
        var fields = await wallet.Checkout(id, ct);
        var inputs = string.Join("", fields.Select(f => $"<input type=\"hidden\" name=\"{WebUtility.HtmlEncode(f.Key)}\" value=\"{WebUtility.HtmlEncode(f.Value)}\">"));
        return Page("Add money to ChargeSync", $"<p>{(gateway.Sandbox ? "Sandbox test payment • No real money" : "Secure payment through PayHere")}</p><h2>LKR {fields["amount"]}</h2><form method=\"post\" action=\"{gateway.CheckoutUrl}\">{inputs}<button type=\"submit\">Continue to PayHere</button></form><p>Return to the app after checkout and refresh your wallet. Credit appears only after payment verification.</p>");
    }

    [AllowAnonymous]
    [HttpPost("payhere/notify")]
    [Consumes("application/x-www-form-urlencoded")]
    [RequestSizeLimit(16384)]
    public async Task<IActionResult> Notify(CancellationToken ct)
    {
        var form = await Request.ReadFormAsync(ct);
        string Field(string key) => form[key].Count == 1 ? form[key].ToString() : "";
        var notification = new GatewayNotification(Field("merchant_id"), Field("order_id"), Field("payment_id"),
            Field("payhere_amount"), Field("payhere_currency"), Field("status_code"), Field("md5sig"));
        // A simultaneous membership purchase or callback may change the wallet version.
        // Retry from a fresh context, never from the failed context's mutated balance.
        for (var attempt = 0; ; attempt++)
        {
            await using var scope = scopes.CreateAsyncScope();
            try
            {
                await scope.ServiceProvider.GetRequiredService<WalletService>().Notify(notification, ct);
                return Ok();
            }
            catch (PaymentConflictException) when (attempt < 2) { }
        }
    }

    [AllowAnonymous]
    [HttpGet("payhere/return")]
    public IActionResult Return() => Page("Return to ChargeSync", "<p>Checkout has returned. Open your wallet in ChargeSync and tap Refresh to check the verified payment status.</p><p>This page does not confirm that money was received.</p>");

    [AllowAnonymous]
    [HttpGet("payhere/cancel")]
    public IActionResult Cancel() => Page("Checkout closed", "<p>Return to your ChargeSync wallet and refresh before trying again. Only a verified payment can add money.</p>");

    private ContentResult Page(string title, string body)
    {
        Response.Headers.CacheControl = "no-store";
        Response.Headers["Referrer-Policy"] = "no-referrer";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        Response.Headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; form-action https://sandbox.payhere.lk https://www.payhere.lk; frame-ancestors 'none'; base-uri 'none'";
        return Content($"<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>{title}</title><style>body{{font:17px system-ui;background:#10181c;color:#eef5f4;margin:0;padding:24px}}main{{max-width:440px;margin:8vh auto;padding:28px;border:1px solid #31504b;border-radius:20px}}p{{line-height:1.6;color:#b6cbc5}}button{{background:#45d2a1;color:#08271e;border:0;border-radius:10px;padding:16px 24px;font:inherit;cursor:pointer;width:100%}}</style></head><body><main><h1>{title}</h1>{body}</main></body></html>", "text/html");
    }
}
