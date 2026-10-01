# Validation & Support Agent

React calls `POST /api/support-tickets/{id}/analysis`. ASP.NET loads the ticket,
recent messages and linked invoice/session through the existing EF/Supabase
connection. Deterministic backend checks produce findings. The Python service
receives only ticket text, recent message bodies and findings at
`POST /api/support/analyze`; it has no database credentials or transaction tools.
LangGraph runs interpretation and structured-output validation. Ollama supplies
category, priority, explanation and draft reply. Staff explicitly copy the edited
draft into the reply composer and send it through the normal backend endpoint.

## Configuration

- Configure ASP.NET `AgenticAi:BaseUrl` (default `http://localhost:8000`).
- Install `agentic-ai/requirements.txt` in a Python virtual environment.
- Configure `OLLAMA_BASE_URL` and `OLLAMA_MODEL` in `agentic-ai/.env` and make the
  selected model available in Ollama. This support workflow currently uses Ollama.
- Run `uvicorn main:app --host 127.0.0.1 --port 8000` from `agentic-ai`.
- Keep Python on the backend's private network; React talks only to ASP.NET.
- Review the `AddInvoiceRefundAccounting` and `AddSupportAgentWorkflows` EF migrations
  before deploying the backend. The existing API startup calls `MigrateAsync` for
  relational databases; starting it against PostgreSQL applies pending migrations.
  Verification tests use an isolated in-memory database and do not migrate live data.

## Validation and decisions

SupportManager/Admin can analyze tickets and independently validate an invoice
through `GET /api/support-tickets/invoices/{id}/validation`, including walk-ins.
Invoice ownership is checked before including linked records in ticket analysis.
Any ticket category may link an invoice belonging to its driver. Checks cover
final versus overridden energy, differences strictly above 15%, invoice gross,
discount, advance and total. Automatic energy is recalculated using elapsed time
and current charger power. Historical power is not snapshotted, so mismatches
require investigation; meter photos are not interpreted.

Analysis never approves a decision, mutates a ticket, credits a wallet or sends a
reply. All requested refunds remain Pending approval until a SupportManager/Admin
explicitly reviews them. Reward recommendations in explanations must use the
existing reward redemption/admin approval workflow; analysis creates no rewards.
The workflow refund threshold is LKR 15 (`SupportWorkflow:RefundApprovalThresholdLkr`).
An LKR 8 request can complete read-only analysis without the workflow approval gate;
an LKR 20 request enters PendingApproval. Completing analysis does not execute a
refund: the existing refund operation still requires staff authorization. The
optional `SupportWorkflow:RequireAllRefundsApproval=true` enforces a stricter gate.
Refund urgency also uses LKR 15. Missing or malformed model output, connection
failure and model timeout yield backend findings and a standard draft. Normal
support actions never depend on the AI service.

## Refund accounting

Approval rechecks ownership, paid status, amount precision and remaining paid
amount. Invoice refunded amount, wallet credit, proportional loyalty reversal,
ticket decision and audit message are committed in the same EF SaveChanges
transaction. Full refunds mark the invoice Refunded; partial refunds retain Paid
and expose RefundedAmount in the invoice API. Ticket, invoice refund total,
wallet and loyalty concurrency checks prevent duplicate concurrent effects.
The existing unique invoice refund index allows one pending/approved request per
invoice. Original loyalty awards remain immutable; reversal ledger descriptions
reference both invoice and ticket. If points were spent/reserved or the loyalty
account is missing, approval fails before any balance is changed.

Historical refunds approved before this migration need reconciliation: the old
flow only credited wallets. The migration does not retroactively debit loyalty
balances or infer old refund accounting. Audit previously Approved support
tickets against invoices and loyalty entries before production rollout. Do not
credit their wallets again.

## Verification

Run `dotnet test backend/tests/UnitTests`, `dotnet test backend/tests/IntegrationTests`,
`python -m pytest` from `agentic-ai`, and `npm run build` from `web-react`.
Python tests use a fake model; a live Ollama response is a separate deployment
smoke test. Prompt-injection tests verify data separation and rejection of extra
authority fields; staff must still review generated prose for accuracy.

See [Student 4 backend verification](student4-backend-verification.md) for the
request/result matrix, cross-service test commands and test limitations.
