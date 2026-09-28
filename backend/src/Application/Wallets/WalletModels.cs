using System.ComponentModel.DataAnnotations;
using Domain.Wallets;
using Domain.Users;

namespace Application.Wallets;

public sealed record StartTopUpRequest(Guid RequestId, decimal Amount,
    [Required, StringLength(25), Phone] string Phone,
    [Required, StringLength(200)] string Address,
    [Required, StringLength(100)] string City);
public sealed record TopUpDto(Guid Id, decimal Amount, string Currency, string Status,
    bool Sandbox, DateTimeOffset CreatedAt, DateTimeOffset? CreditedAt);
public sealed record GatewayNotification(string MerchantId, string OrderId, string PaymentId,
    string Amount, string Currency, string StatusCode, string Signature);
public interface IWalletGateway
{
    bool Available { get; }
    bool Sandbox { get; }
    string PublicBaseUrl { get; }
    string CheckoutUrl { get; }
    Dictionary<string, string> CheckoutFields(WalletTopUp topUp, User user);
    bool Verify(GatewayNotification notification);
}
