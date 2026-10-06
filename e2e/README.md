# Student 4: isolated E2E database preparation

This runs a real Flutter Chrome → ASP.NET → PostgreSQL → Python AI → React approval test. Preparation creates accounts and an isolated API and React portal; the separate runner executes and verifies the workflow. A successful preparation message alone does not prove E2E success.

## 1. Create a NEW Supabase project

Create a project named `chargesync-e2e`. Use an empty project dedicated to tests. Do not copy the normal application's data. Record the new database password locally.

In the new project's dashboard click **Connect → Session pooler**. Copy its host, port, username and database name. Use session mode on port 5432 for this setup. Session pooling supports IPv4; see [Supabase connection documentation](https://supabase.com/docs/guides/database/connecting-to-postgres).

The project reference is the 20-character identifier in the dashboard project URL and at the end of the pooler username `postgres.PROJECT_REF`.

## 2. Fill in the local settings file

From the repository root in PowerShell:

```powershell
Copy-Item e2e/settings.example.json e2e/settings.local.json
notepad e2e/settings.local.json
```

Change:

- `disposableDatabase` to `true` only after creating the separate project.
- `supabaseProjectRef` to the NEW project's reference.
- `postgresConnection` to the NEW project's Npgsql connection string, using the values from Connect. Keep `SSL Mode=Require`.
- `agentServiceApiKey` to your local Python service's `AGENT_SERVICE_API_KEY` value. This is an internal service secret, not a Supabase key or Groq key.

Example connection format (use your own new test values):

```text
Host=YOUR_POOLER_HOST;Port=5432;Database=postgres;Username=postgres.YOUR_NEW_PROJECT_REF;Password=YOUR_TEST_DB_PASSWORD;SSL Mode=Require;Timeout=20
```

This is not the `postgresql://...` URL. The backend uses Npgsql's `Host=...;...` format. If the password contains connection-string punctuation such as `;`, quote it according to Npgsql connection-string rules; escape double quotes and backslashes when putting it inside JSON. A long generated password containing letters and digits is simpler to configure.

`settings.local.json` and the generated `runtime.local.json` are ignored by Git. Keep their contents private. If you share a failure, share the error text, not these files.

## 3. Prepare accounts and schema

```powershell
.\e2e\Prepare.ps1 -CheckConfigOnly
.\e2e\Prepare.ps1
```

The first command checks the configuration without connecting. The second applies the existing EF migrations and creates:

| Fixture | Purpose |
| --- | --- |
| Driver account | Booking, invoice, support request and wallet verification |
| StationOwner account | Session checkout and wallet settlement |
| Admin account | React workflow review and approval |
| Driver wallet: LKR 10,000 | Test funding; no payment gateway or real top-up |
| Approved station and CCS2 charger | Test reservation and session |
| Vehicle and operating hours | Valid reservation data |

Generated account passwords and IDs go into `e2e/runtime.local.json`. Every preparation creates fresh users and assets. Earlier test data remains in the test project. No database is dropped or reset.

The tool refuses an existing database with public tables unless it was previously marked by this E2E preparer. If you receive that refusal, select the empty test project rather than deleting tables.

## 4. Run the isolated applications

Start the real Python AI service using its normal setup and working provider key. If it is already running on port 8000, leave it running. This is the real agent service; the future workflow test must not substitute the mock server in `agentic-ai/tests`.

In one PowerShell terminal from the repository root:

```powershell
.\e2e\Start-Backend.ps1
```

In a second PowerShell terminal from the repository root:

```powershell
.\e2e\Start-Web.ps1
```

Test API: `http://127.0.0.1:5036`; test React: `http://127.0.0.1:5174`. These scripts do not edit the ordinary backend settings or Flutter `.env`. Stop each server with Ctrl+C when finished.

## 5. Run the automated workflow

First install the test dependencies once:

```powershell
cd e2e
npm.cmd ci
cd ..
cd mobile-flutter
flutter pub get
cd ..
```

Keep Python, the E2E backend and E2E React running. From a third terminal at the repository root:

```powershell
.\e2e\Run.ps1
```

Google Chrome must be installed in its standard Windows location and `flutter`, `node` and `dotnet` must be on PATH. The runner downloads a matching ChromeDriver into the ignored `e2e/.browsers` folder. Ports 4444, 4567 and 7357 must be available. It opens browsers automatically and closes its own browsers and driver afterward. Leave them untouched while the test runs.

The test performs these checks:

1. Validates the E2E database marker, fresh fixture accounts, JWT issuer and React API proxy.
2. Logs in and creates a reservation through the real API, then performs staff QR check-in through the real API.
3. Uses the actual Flutter checkout screen to complete the charging session and settle the invoice using Wallet.
4. Uses the actual Flutter support form to submit a LKR 20 refund request for that paid invoice.
5. Waits for the real Python AI to return structured analysis and for backend validation to require approval.
6. Confirms the wallet has not changed before approval.
7. Logs into React as the test Admin, selects that same ticket and approves its workflow through the UI.
8. Checks that a duplicate approval is rejected and the wallet is credited only once.
9. Checks the driver's approved refund screen, wallet and invoice through Flutter and the real API.
10. Independently reads PostgreSQL and verifies the completed reservation/session, invoice arithmetic, refund and administrator decision.

This covers the checkout/refund path across both frontends and the backend/database/AI. Login, booking and QR check-in in Flutter use real API calls rather than the login/booking screens or a camera. Meter photo upload, cash settlement, membership purchase and other alternative paths are outside this scenario.

Flutter uses `flutter drive` and the SDK `integration_test` package; React uses Playwright with installed Chrome. See [Flutter integration testing](https://docs.flutter.dev/cookbook/testing/integration/introduction).

## 6. Evidence and reruns

The result and screenshots are in `e2e/artifacts/RUN_ID-TIMESTAMP/`:

- `result.json`: actual pass/fail, successful checks and record identifiers.
- `react-pending-approval.png`: review state before approval.
- `react-refund-approved.png`: completed approval.
- `react-*-detail.png`: close-up views of the workflow panel for report evidence.
- `outcome.json`: identifiers for the final database checks.

A failure can produce only some of these files. A folder or screenshot does not itself mean the test passed. Do not submit a failed result as a pass. Credentials, tokens and connection strings are excluded from these evidence files; no authenticated network trace is recorded.

For another run, stop the E2E backend, run `Prepare.ps1` to create fresh fixtures, and restart `Start-Backend.ps1` before `Run.ps1`. The new runtime has a new JWT key, so an already-running backend must be restarted. Leave earlier test data in the disposable project.

For a retry with the same database connection and the existing E2E backend still running, use `.\e2e\Prepare.ps1 -KeepJwtKey` instead. This creates fresh accounts and assets while retaining only the verified test JWT key, so the test API can stay running. It refuses to reuse that key if the configured database connection changed.

If the real AI fails, check its Python terminal and service/provider configuration. The runner reports a failure; it never replaces the real agent with a canned response or mock server.

Database setup and passing unit/widget tests are not E2E evidence. Record the E2E result only after that complete workflow has actually executed successfully.
