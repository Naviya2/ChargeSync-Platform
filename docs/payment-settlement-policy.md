# Payment settlement policy

Status: implemented proposal for team review.

## Settlement

- Every charging session has at most one invoice.
- A pending invoice may be settled once by `Wallet` or `Cash`.
- Registered drivers may use wallet or cash. Wallet payment is rejected when the available balance is below the full amount due; partial wallet payments are not supported.
- Walk-ins have no driver account and therefore settle in cash only.
- The wallet deduction and invoice transition to `Paid` are saved together in one database transaction.
- Invoice status and wallet balance use optimistic concurrency checks. Simultaneous requests cannot pay one invoice twice or overwrite a newer wallet balance.

## Advance deposits and refunds

- The final invoice applies `min(advance deposit, gross amount)` as an advance credit.
- If a registered driver's advance exceeds the gross amount, the unused amount is returned to the same wallet while the session and invoice are completed.
- A fully covered invoice is marked paid automatically and does not deduct the wallet again.
- Walk-ins do not pay an advance deposit. If the team later introduces walk-in deposits, excess cash must be recorded as an explicit cash refund rather than being converted into wallet credit.
- Refunds after a paid invoice require a separate refund operation and audit record. They must not edit or delete the original payment record.

## Team decision requested

Confirm whether post-payment refunds will return to the original payment method or always become wallet credit. The recommended rule is to return wallet payments to the wallet and record cash refunds as cash, preserving the original payment method for reconciliation.
