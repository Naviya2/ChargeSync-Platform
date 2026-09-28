# Wallet top-up with PayHere

## What is implemented

Drivers open **Home → Membership & rewards → Wallet · Add money**, choose LKR 100–50,000, enter billing details, prepare checkout, then press **Open secure checkout**. The hosted checkout uses PayHere; card details are never collected by ChargeSync. Return to Wallet and refresh after paying. The screen also refreshes when the app resumes.

Only a valid server notification for the exact stored order, LKR amount and merchant can credit a wallet. A browser return URL never credits money. Each order and payment reference is unique, with optimistic concurrency on both wallet and order; EF commits the receipt and credit together. Duplicate success notifications are acknowledged without another credit. Top-up does not earn charging loyalty points.

Top-up history contains the latest 50 attempts. Pending means confirmation has not arrived; do not pay again merely because a callback is delayed. Checkout links expire after 30 minutes; verified late payments are still processed. A chargeback is flagged for operator reconciliation, without silently deducting already-spent funds. Automated refunds/chargeback recovery are outside this integration; resolve flagged records before enabling production.

## Required setup (sandbox first)

1. Create a [PayHere sandbox account](https://sandbox.payhere.lk/). Obtain your sandbox Merchant ID and a Merchant Secret for the approved integration domain from Integrations. Do not paste the secret into chat or commit it.
2. Expose the backend through a public HTTPS development address. PayHere cannot call `localhost`. Configure your gateway domain to match that address. Follow your team's hosting/network policy when making the API public.
3. From `backend`, set .NET user secrets (replace placeholders locally):

```powershell
dotnet user-secrets set "PayHere:Enabled" "true" --project src/Api
dotnet user-secrets set "PayHere:Sandbox" "true" --project src/Api
dotnet user-secrets set "PayHere:MerchantId" "YOUR_SANDBOX_MERCHANT_ID" --project src/Api
dotnet user-secrets set "PayHere:MerchantSecret" "YOUR_SANDBOX_MERCHANT_SECRET" --project src/Api
dotnet user-secrets set "PayHere:PublicBaseUrl" "https://YOUR_PUBLIC_API_HOST" --project src/Api
```

4. Restart the API normally (without `--no-build`); startup applies `AddWalletTopUps`. Restart Flutter. Without valid configuration, Wallet explains that setup is incomplete and does not offer a fake payment button.
5. Use the test cards in [PayHere's sandbox guide](https://support.payhere.lk/sandbox-and-testing), never a real card. Sandbox credits change the development wallet only; they do not represent real funds.

Do not enable sandbox payments against a production wallet database. Use separate sandbox/live databases and credentials. Persist ASP.NET Data Protection keys on the API host (share them across replicas) so checkout links remain valid between requests/restarts. HTTPS and a production CORS policy are required for live deployment.

## Manual checks

- Add LKR 1,000 through sandbox; wait for status Paid, then verify the wallet increased exactly by 1,000.
- Refresh repeatedly: no additional credit. Subscribe to Plus and verify 500 is deducted.
- Cancel or fail checkout: no wallet increase. Closing the browser alone may leave an order Pending until a gateway notification arrives.
- A return URL opened manually must not credit money.
- Try a second driver: their wallet/history must be separate.
- Missing merchant configuration: useful setup message, no invented balance.
- Keep a pending order visible if notification is delayed; inspect backend logs and PayHere records rather than paying again.

## Routes and operations

- `GET /api/wallet`: driver's balance, gateway availability and own top-up history.
- `POST /api/wallet/top-ups`: authenticated Driver; requestId, amount, phone, address, city. Returns a short-lived checkout URL.
- `GET /api/wallet/payhere/checkout?ticket=...`: encrypted checkout capability, no JWT in the URL. Do not share these links or log their query strings.
- `POST /api/wallet/payhere/notify`: form-encoded signed PayHere notification, anonymous by design, maximum 16 KB.
- `GET /api/wallet/payhere/return` and `/cancel`: informational pages only.

After any webhook 409/5xx, arrange redelivery/reconciliation from gateway records; never manually credit based solely on a customer's screenshot. Monitor `WalletTopUps.Status = 'ChargebackReview'` and aged Pending records. No background gateway reconciliation worker is included.

Official protocol: [PayHere Checkout API](https://support.payhere.lk/api-%26-mobile-sdk/checkout-api).
