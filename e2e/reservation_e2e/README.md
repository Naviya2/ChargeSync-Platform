# Reservation & AI Charging Planning E2E Test Suite (Component 3 / Student 3)

Automated end-to-end integration and system test suite validating the complete lifecycle of **Component 3: Reservation and AI Charging Planning**.

## Workflows Tested

1. **Phase 1: Environment Health & Infrastructure Validation**
   - Verifies ASP.NET Core API (`:5035`), React Web Portal (`:5173`), and local PostgreSQL (`ChargeSync-Test:5432`).
   - Asserts operating hours (06:00 to 23:00) seeded for test charging stations.
2. **Phase 2: Dynamic Account Provisioning**
   - Creates isolated Driver funded with LKR 10,000.00 wallet balance.
   - Registers Driver EV with CCS2 connector and 62 kWh battery.
   - Registers Station Owner and assigns station ownership.
3. **Phase 3: Flow A – Standard Advance Reservation**
   - Verifies 65 available 60-minute slots.
   - Deducts LKR 500 advance deposit from driver wallet.
   - Generates 64-character cryptographic QR token (`Status = Confirmed`).
4. **Phase 4: Anti-Double-Booking Concurrency Lock**
   - Attempts overlapping booking on the same charger.
   - Asserts rejection with HTTP 400 via domain buffer guard and PostgreSQL GiST exclusion lock.
5. **Phase 5: Flow B – AI Buffer Detection & Deferred Deposit**
   - Flags edge-case booking finishing within 15-minute closing buffer.
   - Creates `Status = Pending` reservation with LKR 0 upfront deposit (QR deferred).
6. **Phase 6: Station Owner Approval (Playwright UI Automation)**
   - Automates Chrome browser login on React Web Portal (`http://localhost:5173`).
   - Filters pending bookings, inspects `ReservationDetailsModal`, captures UI screenshot.
   - Clicks "Approve Request" and confirms. Captures approved state UI screenshot.
   - Verifies backend status transition to `Confirmed` and LKR 500 deposit capture.
7. **Phase 7: Flow C – Staff Cryptographic QR Check-In**
   - Creates check-in eligible reservation for current time window.
   - Submits QR token via `POST /api/reservations/staff-checkin`.
   - Transitions reservation to `CheckedIn` and automatically initiates physical `ChargingSession`.
8. **Phase 8: Direct PostgreSQL Relational Ledger Audit**
   - Verifies rows in `Reservations`, `ReservationStatusHistory`, and `ChargingSessions`.
   - Verifies exact financial ledger balance: LKR 10,000 - 3 × 500 = **LKR 8,500.00**.

## How to Run

### Option 1: PowerShell Runner
```powershell
.\e2e\reservation_e2e\Run-Reservation-Planning-E2E.ps1
```
Or via forwarding runner:
```powershell
.\e2e\Run-Reservation-Planning-E2E.ps1
```

### Option 2: Direct Node Execution
```bash
cd e2e/reservation_e2e
node run_reservation_planning_e2e.mjs
```

## Generated Evidence & Artifacts

All outputs are written to timestamped folders under `e2e/reservation_e2e/artifacts/<run-id>/`:
- `reservation_planning_e2e_report.md` (Markdown report with summary tables)
- `reservation_planning_e2e_report.html` (Styled standalone HTML report)
- `reservation_planning_e2e_result.json` (Machine-readable test results)
- `screenshots/react_e2e_reservation_pending.png` (Modal screenshot before approval)
- `screenshots/react_e2e_reservation_approved.png` (Modal screenshot after approval)
