using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Application.Wallets;
using Domain.Users;
using Domain.Wallets;
using Microsoft.Extensions.Options;

namespace Infrastructure.Payments;

public sealed class PayHereOptions
{
    public bool Enabled { get; set; }
    public bool Sandbox { get; set; } = true;
    public string MerchantId { get; set; } = "";
    public string MerchantSecret { get; set; } = "";
    public string PublicBaseUrl { get; set; } = "";
}

public sealed class PayHereGateway(IOptions<PayHereOptions> options) : IWalletGateway
{
    private PayHereOptions Settings => options.Value;
    public bool Sandbox => Settings.Sandbox;
    public string PublicBaseUrl => Settings.PublicBaseUrl.TrimEnd('/');
    public string CheckoutUrl => Sandbox ? "https://sandbox.payhere.lk/pay/checkout" : "https://www.payhere.lk/pay/checkout";
    public bool Available => Settings.Enabled && !string.IsNullOrWhiteSpace(Settings.MerchantId)
        && !string.IsNullOrWhiteSpace(Settings.MerchantSecret)
        && Uri.TryCreate(PublicBaseUrl, UriKind.Absolute, out var uri) && uri.Scheme == "https"
        && !uri.IsLoopback && string.IsNullOrEmpty(uri.Query) && string.IsNullOrEmpty(uri.Fragment);

    public Dictionary<string, string> CheckoutFields(WalletTopUp topUp, User user)
    {
        if (!Available) throw new InvalidOperationException("PayHere is not configured.");
        var amount = topUp.Amount.ToString("0.00", CultureInfo.InvariantCulture);
        var order = topUp.Id.ToString("N");
        var names = user.FullName.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        return new()
        {
            ["merchant_id"] = Settings.MerchantId,
            ["return_url"] = PublicBaseUrl + "/api/wallet/payhere/return",
            ["cancel_url"] = PublicBaseUrl + "/api/wallet/payhere/cancel",
            ["notify_url"] = PublicBaseUrl + "/api/wallet/payhere/notify",
            ["order_id"] = order,
            ["items"] = "ChargeSync wallet top-up",
            ["currency"] = topUp.Currency,
            ["amount"] = amount,
            ["first_name"] = names.FirstOrDefault() ?? "Driver",
            ["last_name"] = names.Length > 1 ? names[1] : names.FirstOrDefault() ?? "Driver",
            ["email"] = user.Email,
            ["phone"] = topUp.Phone,
            ["address"] = topUp.Address,
            ["city"] = topUp.City,
            ["country"] = "Sri Lanka",
            ["hash"] = Digest(Settings.MerchantId + order + amount + topUp.Currency + Digest(Settings.MerchantSecret))
        };
    }

    public bool Verify(GatewayNotification n)
    {
        if (!Available || n.MerchantId != Settings.MerchantId || n.Signature.Length != 32) return false;
        var expected = Digest(n.MerchantId + n.OrderId + n.Amount + n.Currency + n.StatusCode + Digest(Settings.MerchantSecret));
        return CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(expected), Encoding.ASCII.GetBytes(n.Signature.ToUpperInvariant()));
    }

    // MD5 is required by PayHere's signature protocol; it is not used for password storage.
    private static string Digest(string value) => Convert.ToHexString(MD5.HashData(Encoding.UTF8.GetBytes(value)));
}
