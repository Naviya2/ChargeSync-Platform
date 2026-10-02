# Support management (Student 4)

## Roles and workflow

Drivers open **Profile → Support tickets** in Flutter. They can create categories Charging, Reservation, Payment, Refund, Technical, Membership or Other; read only their tickets; add messages; and withdraw an unassigned Open ticket. Closing or withdrawing a ticket makes its conversation read-only.

SupportManager and Admin accounts open **Support Tickets** in the React portal. The queue uses real API data and supports search, status filtering, assignment, replies, status changes and refund decisions. StationOwner is not authorized to access support APIs even if its portal navigation is visible.

Priority is server-controlled: Refund, Payment and Charging start High; a requested refund above LKR 5,000 or text reporting an unsafe condition becomes Urgent; Technical is Medium; other categories are Low. This deterministic triage is auditable and works without the optional AI service.

## Refund rules

- A refund ticket must reference the authenticated driver's paid invoice.
- The requested amount must be positive and cannot exceed the invoice amount after discount.
- Only one PendingReview or Approved request is allowed for an invoice, enforced by the service and a filtered unique database index.
- Every refund requires human approval. A pending refund prevents the ticket from being Resolved or Closed.
- SupportManager or Admin approval credits the driver's wallet once in the same database transaction as the review record and audit message. Repeated approval is rejected.
- LKR 5,000 is the configured local high-value review threshold used for triage. Because every refund requires review, exchange-rate movement cannot bypass human approval.
- This feature does not mark the charging invoice Refunded or reverse previously awarded loyalty points. Those accounting operations require a separate refund ledger/reversal design before production use.

## API

- `GET /api/support-tickets` — own tickets for Driver; queue for SupportManager/Admin.
- `GET /api/support-tickets/{id}` — authorized ticket and conversation.
- `POST /api/support-tickets` — Driver creates a ticket.
- `POST /api/support-tickets/{id}/messages` — authorized public conversation reply.
- `PUT /api/support-tickets/{id}/assignee` — SupportManager/Admin assignment.
- `PUT /api/support-tickets/{id}/status` — SupportManager/Admin workflow update.
- `POST /api/support-tickets/{id}/refund-review` — SupportManager/Admin approval or rejection.
- `DELETE /api/support-tickets/{id}` — Driver withdraws an unassigned Open ticket; history is retained.

## Manual test

1. Restart the API normally so `AddSupportTickets` is applied.
2. Sign in as a Driver, open Profile → Support tickets, create a Technical ticket, add a message and verify another driver cannot access its ID.
3. Sign in to React as SupportManager, open Support Tickets, find the real ticket, assign it to yourself, reply and resolve it. Refresh Flutter and check the complete conversation.
4. As Driver, create a Refund ticket and choose a paid invoice. Try an amount above the paid amount: it must fail.
5. In React, approve the valid refund once. Refresh the driver's wallet and verify one credit. A repeated decision and a second pending request for the same invoice must fail.
6. Create an ordinary unassigned ticket and withdraw it as Driver. It remains in history as Withdrawn and cannot receive messages.

Automated tests use EF InMemory and verify business rules and API authorization. Perform a PostgreSQL and browser/device smoke test before merging.
