# Membership and loyalty (Student 4, Step 5)

## Product rules

These are ChargeSync starting rates in LKR, chosen for this implementation. They are not advertised market prices from a Sri Lankan provider. Membership catalogs and reward costs are seeded by `AddMembershipAndLoyalty` and stored in the database.

| Plan | Fee per 30 days | Charging discount |
| --- | ---: | ---: |
| Pay as you go (no subscription) | 0 | Loyalty tier discount only |
| Plus | 500 | 5% |
| Premium | 1,000 | 10% |

Membership fees are deducted from the wallet. Drivers can fund it through **Wallet · Add money** after the team configures [PayHere sandbox top-up](wallet-top-up.md). Subscriptions last 30 days and renewal is manual; no background recurring charge is made.

Upgrades/downgrades take effect immediately. Unused time on the previous plan is credited proportionally, then the full new 30-day fee is deducted in the same transaction. Changes retain a historical period. Cancellation preserves benefits to the original end date and gives no cash or wallet refund. Expiry is evaluated from the server clock, so expired subscriptions cannot grant discounts even without a background job.

The higher of the plan discount and loyalty tier discount applies at invoice creation. They do not stack. Both the rate and discount amount are stored on the invoice. Advance deposits are applied after discount. Existing invoices are unchanged.

## Points and tiers

- A registered driver's newly paid charging invoice earns `floor((gross amount - discount) / 100)` points. This provides up to 1% wallet-credit value.
- Both cash and wallet payments qualify. An invoice fully covered by its advance deposit qualifies when it is issued as Paid. Pending invoices, walk-ins, membership fees and refunded invoices do not trigger new awards.
- A unique invoice reference in the append-only points ledger prevents a second award for the same payment. Old already-paid invoices are not backfilled.
- Bronze: under 1,000 lifetime points, 0% discount. Silver: 1,000 to 4,999, 2%. Gold: 5,000+, 5%.
- Redemption reduces available points, not lifetime earned points; it does not downgrade the tier.
- History displays the latest 100 entries.

## Rewards and approval

- 100 points => LKR 100 wallet credit, immediately approved.
- 6,000 points => LKR 6,000 wallet credit, mandatory admin approval.
- The server loads the reward price/value; clients cannot set them. Any reward flagged for approval or costing over 5,000 points waits for review. When adding rewards, flag any reward whose monetary value exceeds the SRS's USD 50 equivalent as well; current rewards are LKR-denominated and no live FX conversion is implemented.
- Pending requests reserve points immediately. Approval credits the wallet once; rejection restores points once. The reviewer ID and time are retained.
- Clients send a request UUID. Retrying the same request returns the existing redemption; reusing it for another reward is rejected.
- Admins review rewards in the React portal under **Approvals > Loyalty reward approvals**. Drivers cannot approve their own rewards.
- Post-payment refunds and loyalty clawbacks are not implemented by this step. A future refund operation must add a reversing ledger entry atomically with the refund, rather than deleting the earned-points record.

## Ownership and transactions

Driver IDs for mutations come from the authenticated token. Drivers can only view their own balance/history/subscriptions or change/cancel their own subscription. Only Admin can review redemptions. The balance-by-user route permits the matching driver or Admin.

Each mutation commits once through EF SaveChanges, which is transactional with PostgreSQL. Wallet balance, membership version, points-account version and redemption status use concurrency checks. Duplicate invoice awards and repeated redemption request IDs have database uniqueness constraints. Concurrent conflicts return 409 and require a refresh/retry.

The SRS's separate loyalty-account identifier is represented by `DriverId` as the primary key here, enforcing one account per driver. Tiers are derived from lifetime points. Period snapshots and loyalty entries extend the SRS to preserve billing and points history.

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /api/membership-plans | Available plans |
| GET / POST | /api/subscriptions | Own history / subscribe with planId |
| PUT | /api/subscriptions/{id}/change | Change own plan |
| DELETE | /api/subscriptions/{id} | Cancel own plan |
| GET | /api/loyalty/me | Balance, lifetime points, tier, next tier, wallet |
| GET | /api/loyalty/{userId} | Authorized balance lookup |
| GET | /api/loyalty/history | Own points ledger |
| GET | /api/loyalty/rewards | Reward catalog |
| POST | /api/loyalty/redeem | Redeem with rewardId and requestId |
| GET | /api/loyalty/redemptions | Own requests (Admin sees recent requests across drivers) |
| POST | /api/loyalty/redemptions/{id}/review | Admin approval/rejection with approve boolean |

## How to check

1. Restart the backend normally, without `--no-build`, so startup applies the migration. Restart Flutter. Do not run a second API process on the same port.
2. Sign in as a **Driver**, open the home **Membership & rewards** card. Expect actual points (zero for a new account), Bronze tier, plans, and reward catalog.
3. With less than LKR 500 in the wallet, try Plus. Expect an insufficient-balance error and no subscription.
4. With a funded test wallet, subscribe to Plus. Expect LKR 500 deducted, Active status, and an end date 30 days ahead.
5. Change to Premium. Expect proportional credit for unused Plus time, the new fee charged, and a history row. Cancel: benefits remain until the displayed end date.
6. Complete and pay a registered-driver charging session. The invoice shows the membership/tier discount. Refresh the driver's membership screen: e.g. LKR 1,000 gross with Plus gives LKR 50 discount and 9 points when paid. Repeating the settlement must not add more points.
7. Once the driver has 100 points, redeem the small reward. Expect exactly 100 points deducted and LKR 100 credited. Insufficient-point attempts must fail even through the API.
8. With 6,000 points, request the large reward. Expect Pending and points reserved, but no wallet credit. Sign in as Admin in React and approve or reject under Approvals. Refresh the driver screen and verify wallet credit or points release.
9. Sign in as another driver. The first driver's subscription ID/balance must not be accessible for mutation/read.

Automated tests use an isolated EF InMemory database with funded test users. They cover business rules and API authorization but do not prove PostgreSQL transaction rollback. No real user's wallet or points are prefilled by this feature. Device/browser smoke testing remains necessary.
