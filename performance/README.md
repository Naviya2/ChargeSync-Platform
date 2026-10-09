# ChargeSync performance checks

The sustained API test uses the same separate, disposable Supabase database as the E2E test. It checks the E2E database marker and JWT issuer before sending load. It uses the prepared Driver account to make read-only requests to the isolated API on `127.0.0.1:5036`; it does not create reservations, payments, or refunds.

From the repository root, start the isolated API in one PowerShell terminal:

```powershell
.\e2e\Start-Backend.ps1 -QuietLogs
```

In another terminal, run:

```powershell
.\performance\Run.ps1 -Sustained
```

The test starts with an unscored 30-second warm-up, then runs three sequential 60-second measured phases with 1, 5, and 10 constant virtual users. Each user rotates through stations, wallet, and payment-history GET requests with a 0.5-second pause between requests. k6 checks HTTP 200 and response shape, then records latency by phase and endpoint. A complete run takes about three and a half minutes. The command returns a nonzero exit code when the 500 ms p95 target or the team failure/check targets are not met, but it still writes evidence to `performance/artifacts/sustained-TIMESTAMP/`:

- `result.json`: concise machine-readable verdict and measurements.
- `report.md`: report-ready summary and limitations.
- `k6-summary.json`: raw k6 metrics and threshold results.

The 500 ms p95 target comes from the ChargeSync group SRS for standard API calls. The <1% HTTP failure and >99% response-check targets are team criteria. This is a sustained read-only API test, not a stress test or a full frontend-to-database user journey. It uses one test Driver and a small database, so it does not establish production capacity. The Python AI service is not needed for this test; the earlier `Run.ps1` baseline includes two real-AI requests when it is running.
