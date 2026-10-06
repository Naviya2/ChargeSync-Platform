# Student 4 automated E2E test result

The checkout/refund workflow passed on **5 October 2026** against the separate Supabase E2E database. The successful run ID is `77dead59cb28`.

The test uses Flutter `integration_test` with ChromeDriver, Playwright for React, the real ASP.NET API, the real Python AI service and PostgreSQL. It does not use mocked HTTP or a canned AI response.

| Test case | Expected result | Actual result | Status |
| --- | --- | --- | --- |
| Reservation and staff check-in | Booking is confirmed and starts a session | Real API returned Confirmed and CheckedIn; active session loaded | Pass |
| Flutter session checkout | Stopping the session generates a valid invoice | Invoice generated; persisted energy and tariff matched the gross amount | Pass |
| Flutter wallet settlement | Invoice becomes Paid and wallet is debited correctly | Wallet payment recorded; driver balance matched the invoice debit | Pass |
| Flutter refund request | Paid invoice can be linked to a LKR 20 refund ticket | Support form submitted the linked ticket in PendingReview | Pass |
| AI analysis and validation | Structured analysis requires approval and does not credit money | Real AI analysis returned; backend reached PendingApproval; wallet unchanged | Pass |
| React approval | Admin can approve the pending workflow | React approval succeeded; workflow became Completed with decision Approved | Pass |
| Duplicate approval | Old approval cannot apply a second refund | Second request returned HTTP 409; wallet credited only once | Pass |
| Driver and database verification | Approved refund and accounting persist correctly | Driver screen showed Refund: Approved; PostgreSQL verified refund, invoice, session and wallet | Pass |

## Evidence

Files are in `e2e/artifacts/77dead59cb28-1791220515592/`:

- `result.json`: actual successful result and completed checks.
- `outcome.json`: identifiers used for independent database verification.
- `react-pending-approval.png`: workflow before approval.
- `react-refund-approved.png`: workflow immediately after approval.
- `react-refund-approved-detail.png`: clear read-only capture of the completed workflow panel after the test.

The artifact folder is ignored by Git. Copy the selected evidence into your report submission separately. Keep `settings.local.json` and `runtime.local.json` private; they contain credentials.

## Run it yourself

Keep the Python service, E2E API on port 5036 and E2E React on port 5174 running. In a third PowerShell terminal at the repository root:

```powershell
.\e2e\Prepare.ps1 -KeepJwtKey
.\e2e\Run.ps1
```

Preparation creates fresh accounts and assets and retains the existing test JWT key. The runner opens Chrome and performs the steps automatically. Wait for `E2E PASSED`; a setup message alone does not mean the workflow passed.

## Coverage limits

Flutter login, booking and staff QR check-in use real API calls. Checkout, payment settlement and refund-ticket submission use actual Flutter screens; approval uses the React UI. Camera scanning, meter-photo upload, cash settlement, membership purchase and unrelated workflows are outside this scenario.

The existing Flutter unit/widget suite was also rerun after the Chrome login fix: **61 tests passed**. Those tests are separate from this live E2E scenario.
