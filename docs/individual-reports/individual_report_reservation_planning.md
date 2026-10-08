# INDIVIDUAL REPORT
**Member [Student 3]:** [Student Name]  
**Student ID:** [Student ID]  
**Project:** ChargeSync – Intelligent EV Charging Reservation and Recommendation Platform  
**Academic Year / Cohort:** Year 3, Semester 1, 2026 (SE3090 – Software Engineering Frameworks)  

---

## 1. Contribution Statement

| Item | Details |
| :--- | :--- |
| **Student Name** | [Student Name] |
| **Student ID** | [Student ID] |
| **Assigned Component** | **Component 3: Reservation & AI Charging Planning** |
| **Main Responsibility** | Architecture, full-stack implementation, testing, and AI integration for standard map-based advance reservations, on-site staff walk-in admissions, QR check-in flows, AI recommendation edge-case buffer detection, station owner approval gates (HITL), and multi-agent AI charging itinerary coordination. |
| **Technologies** | ASP.NET Core (.NET 8, C# 12), PostgreSQL 15 (EF Core, Npgsql), React 18 (Vite, TanStack Query, Tailwind/Vanilla CSS), Flutter 3 (Dart, Riverpod), Python 3.11 (LangGraph, FastAPI, Groq LLM). |

### Overall Contribution Summary
As the owner of Component 3 (**Reservation & AI Charging Planning**), I engineered the core scheduling, reservation lifecycle, and AI-driven itinerary planning engine for the ChargeSync platform. My technical contributions span the complete full-stack spectrum:
1. **Backend & Architecture**: Designed and implemented the domain logic, transaction handling, and RESTful APIs in ASP.NET Core for standard direct reservations, wallet deposit deductions, on-site staff walk-in admissions, and station-owner approval workflows (`ApproveAsync` / `RejectAsync`).
2. **Database & Concurrency**: Modeled the relational schema in PostgreSQL using Entity Framework Core, enforcing mathematical anti-double-booking guarantees via PostgreSQL GiST exclusion constraints and pessimistic row locking.
3. **Web Portal (React)**: Developed the station management and administrative booking interface, including the real-time reservations table, modal dialogs for time-slot editing and visual meter photo inspection, and the operator pending approvals widget.
4. **Mobile Application (Flutter)**: Implemented dual driver and staff workflows—enabling EV drivers to book chargers directly via map discovery or generate constraint-aware AI recommendations, and providing station staff with a high-throughput POS interface for camera-based QR code check-ins and walk-in admissions.
5. **Agentic AI Subsystem**: Developed and fine-tuned the `PlanningCoordinatorAgent` using Python and LangGraph, orchestrating vehicle compatibility checks and station congestion metrics to produce ranked charging itineraries while enforcing deterministic charge durations and human-in-the-loop (HITL) approval gates for operational edge cases (sessions completing within 15 minutes of closing or maintenance).
6. **Quality Assurance**: Authored extensive automated test suites comprising 90 backend xUnit tests (62 in `ReservationServiceTests`, 4 in `ReservationTimezoneTests`, 2 in `ChargingPlansControllerTests`, 22 in `LateCancellationFeeTests`), 4 Python pytest suites, 24 React Vitest unit/integration tests, and 8 Flutter unit tests.

---

## 2. Owned Component and Technical Work

### 2.1 Component Overview
* **Purpose:** To eliminate charger congestion, scheduling uncertainty, and station operational conflicts by delivering conflict-free advance bookings, automated staff check-ins, instantaneous walk-in allocations, and intelligent, constraint-aware charging itineraries.
* **Users Involved:**
  * **EV Drivers:** Search for stations via the interactive map, select custom charging slots, generate AI charging plans tailored to deadlines and budgets, book slots with advance wallet deposits, and present signed QR tokens upon arrival.
  * **Station Owner:** Scan driver QR codes to execute check-ins, admit unregistered walk-in drivers on-demand, and review/approve edge-case reservation requests flagged by the AI planning coordinator.
  * **Platform Administrators:** Supervise global reservation audit trails, inspect session telemetry, and verify physical meter photo evidence attached to completed bookings.
* **Main Features:**
  * **Direct Map-Based Reservation:** Drivers select any available station and charger from the map/list, select a time slot, and confirm with immediate wallet deposit deduction and QR issuance.
  * **AI-Assisted Charging Planning:** Multi-agent coordinator that analyzes vehicle specs, station tariffs, and congestion to generate ranked itineraries tailored to driver constraints.
  * **AI Operational Buffer Detection (HITL):** Evaluates AI-recommended itineraries against station closing times and maintenance windows. Recommendations finishing within a 15-minute buffer threshold are flagged for manual Station Owner approval, deferring advance deposit deduction.
  * **Operator Approval Dashboard:** Station owners review pending edge-case bookings, with one-click `Approve` (capturing deposit and issuing QR) and `Reject` (releasing slot with zero penalty).
  * **Cryptographic QR Tokens:** Unique, tamper-proof `ReservationQRCode` generated upon confirmation for driver presentation.
  * **On-Site Staff QR Check-In:** Station attendants scan driver QR codes using the Flutter mobile app to validate arrival and instantly initiate charging sessions.
  * **Walk-In Admission:** Attendants admit unregistered drivers on-site, locking the charger with `DriverId = NULL` to prevent online double-bookings.
  * **Audit Logging:** Every lifecycle transition is recorded in `ReservationStatusHistory`.

* **Business Workflow:**
  ChargeSync supports two distinct reservation creation pathways for drivers (Standard Direct Map Reservation and AI-Assisted Recommendation), alongside an on-site staff walk-in flow:

  1. **Flow A: Standard Map-Based Reservation (Normal Operation)**
     * The driver browses stations on the interactive map or station list.
     * The driver inspects station details, charger power ratings, and tariffs.
     * The driver selects an available time slot and duration, then taps "Confirm Reservation".
     * Because this is a standard user-selected slot, no AI buffer constraints are triggered: the LKR 500.00 advance deposit is immediately deducted from the driver's wallet, the reservation is marked as `Confirmed`, and a cryptographically signed QR token is issued immediately.

  2. **Flow B: AI-Assisted Smart Planning (With Operational Buffer Evaluation)**
     * The driver enters route constraints (destination, arrival deadline, max distance, price preference).
     * The `PlanningCoordinatorAgent` screens candidate stations for connector compatibility and congestion, synthesizes ranked itineraries, and calculates exact session finish times.
     * **Operational Buffer Check:** The AI coordinator evaluates whether the recommended session concludes within 15 minutes of the station's closing time or a scheduled charger maintenance window.
       * *No Conflict ($\ge 15$m buffer):* Standard itinerary; confirms normally with immediate LKR 500.00 deposit and QR code.
       * *Edge-Case Conflict ($< 15$m proximity):* The coordinator flags `requires_approval = True`. An advisory banner warns the driver, the advance deposit is deferred (LKR 0.00 deducted upfront), and the booking is saved as `PendingApproval`.
     * **Station Owner Review:** The station owner reviews the pending request. Upon approval, the deposit is captured and QR issued; upon rejection, the slot is released without financial penalty.

  3. **Flow C: On-Site Arrival & Check-In**
     * The driver presents the QR code at the station.
     * Station staff scans the QR token via the Flutter POS app, which validates the reservation and transitions it to `CheckedIn`, starting the charging session.

```
                              [Driver Reservation Options]
                                           │
            ┌──────────────────────────────┴──────────────────────────────┐
            ▼                                                             ▼
  [Flow A: Direct Map Booking]                               [Flow B: AI Smart Planner]
• Browse stations on map/list                              • Input deadline, distance & budget
• Select charger, date & time slot                         • PlanningCoordinatorAgent evaluates
• Normal operation (no buffer checks)                      • Evaluates 15m closing/maint buffer
            │                                                             │
            │                                              ┌──────────────┴──────────────┐
            │                                              ▼                             ▼
            │                                     [Standard AI Slot]             [Buffer Conflict (<15m)]
            │                                   (>=15m safety buffer)         (Finishes within 15m buffer)
            │                                              │                             │
            └──────────────────────┬───────────────────────┘               [Deposit Deferred (LKR 0.00)]
                                   │                                                     │
                     [Deduct LKR 500 Advance Deposit]                         [Status: PendingApproval]
                                   │                                                     │
                          [Status: Confirmed]                               [Station Owner Portal Alert]
                                   │                                                     │
                      [Generate Signed QR Token]                                  ┌──────┴──────┐
                                   │                                              ▼             ▼
                                   │                                      [Owner Approves] [Owner Rejects]
                                   │                                              │             │
                                   │                                      [Deduct LKR 500] [Release Slot]
                                   │                                      [Generate QR]    [Status: Rejected]
                                   │                                      [Status: Confirmed]   │
                                   │                                              │             ▼
                                   └──────────────────────┬───────────────────────┘     [Notify Driver]
                                                          ▼
                                             [Driver Arrives at Station]
                                                          │
                                           [Staff Scans QR via Flutter POS]
                                                          │
                                       [Validation & Session Start: CheckedIn]
```

---

### 2.2 Backend / API Work
* **Controllers:**
  * `ReservationsController.cs`: Exposes REST endpoints for advance reservation creation, admin-delegated booking, walk-in customer creation, status filtering, QR check-in, slot cancellation, updating time windows, and operator `approve`/`reject` operations.
  * `ChargingPlansController.cs`: Exposes `POST /api/charging-plan/generate`, gathering authenticated driver profiles, active vehicle specifications, and real-time candidate station metrics (including operating hours and scheduled maintenance) before dispatching the payload to the internal Python Agentic AI microservice via `IPlanningAgentClient`.
* **DTOs:**
  * `CreateReservationRequest`: Payload containing `ChargerId`, `VehicleId`, `StartTime`, `EndTime`, and `RequiresApproval` flag (set to `true` when booking an AI-flagged edge-case slot).
  * `ReservationDto`: Full response object detailing reservation identifiers, driver details, charger details, start/end timestamps, QR code payload, `AdvanceDepositAmount`, `ApprovalRequired`, `ApprovalReason`, current `Status`, and linked session data.
  * `AdminCreateReservationRequest`: Administrative payload allowing staff to book on behalf of registered drivers without advance fee deduction.
  * `WalkInRequest`: Payload for on-site unregistered walk-ins (`ChargerId`, `StartTime`, `EndTime`, `Notes`).
  * `StaffCheckinRequest`: Payload containing the scanned `ReservationQRCode` and `StaffUserId`.
  * `UpdateReservationRequest`: DTO to modify reservation time boundaries subject to slot availability.
  * `TimeSlotDto`: Time representation indicating available start/end slots and duration.
  * `ReservationHistoryDto`: Audit log DTO containing `OldStatus`, `NewStatus`, `ChangedByUserId`, and `ChangedAt`.
* **Services / Business Logic (`ReservationService.cs`):**
  * **Advance Reservation Pipeline (`CreateAsync`):** Validates the 7-day advance booking horizon; verifies driver wallet balance; checks charger operating hours and maintenance overlaps. If `request.RequiresApproval` is flagged (from an AI buffer conflict), deposit deduction is deferred and status is set to `PendingApproval`; otherwise, LKR 500.00 is deducted immediately, status is set to `Confirmed`, and a cryptographically signed QR token is issued.
  * **Operator Approval Actions (`ApproveAsync` / `RejectAsync`):** Restricts review to Station Owners and Admins; verifies the reservation is currently in `PendingApproval`; on approval, executes an ACID transaction deducting LKR 500.00 from the driver's wallet, updates status to `Confirmed`, generates the unique QR token, logs status history, and sends an in-app notification; on rejection, immediately marks status as `Rejected` and releases the calendar slot without charging the driver.
  * **Walk-In Admission (`CreateWalkInAsync`):** Creates an on-site reservation record with `DriverId = null`, locking the charger against online bookings, immediately transitioning the reservation to `CheckedIn` status, and triggering charging session creation.
  * **Staff Check-In (`StaffCheckinAsync`):** Validates the scanned cryptographic QR token, checks that the arrival window is within valid check-in tolerance, marks the reservation as `CheckedIn`, and establishes the linked `ChargingSession`.
  * **Availability Algorithm (`GetAvailableTimeSlotsAsync`):** Computes open charging windows for any selected date by calculating the station's daily operating hours, subtracting existing reservations and scheduled maintenance windows, and enforcing safety buffers.
* **API Endpoints:**

| Method | Endpoint | Authorization | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/reservations` | Driver | Create advance reservation (direct confirmation or deferred `PendingApproval`) |
| `POST` | `/api/reservations/walk-in` | StationOwner / Staff | Immediate on-site walk-in customer admission (locks charger, `DriverId=null`) |
| `POST` | `/api/reservations/admin` | StationOwner / Admin | Create reservation on behalf of a driver without pre-payment |
| `GET` | `/api/reservations` | Authenticated | Paginated and filtered reservation list (role-segregated) |
| `GET` | `/api/reservations/{id}` | Authenticated | Retrieve reservation details, QR payload, and linked session/meter photos |
| `GET` | `/api/reservations/availability` | Authenticated | Query available booking slots for a charger and date |
| `PUT` | `/api/reservations/{id}/cancel` | Authenticated | Cancel reservation, releasing slot and executing refund if applicable |
| `POST` | `/api/reservations/{id}/approve` | StationOwner / Admin | Operator approves edge-case booking, capturing deposit and issuing QR |
| `POST` | `/api/reservations/{id}/reject` | StationOwner / Admin | Operator rejects edge-case booking, releasing slot with zero fee |
| `PUT` | `/api/reservations/{id}` | StationOwner / Admin | Modify reservation start/end window with overlap validation |
| `DELETE` | `/api/reservations/{id}` | StationOwner / Admin | Administrative hard deletion with historical record cleanup |
| `POST` | `/api/reservations/staff-checkin` | StationOwner / Staff | Validate scanned driver QR token and set status to `CheckedIn` |
| `GET` | `/api/reservations/{id}/history` | Authenticated | Retrieve complete audit trail of status transitions |
| `POST` | `/api/charging-plan/generate` | Driver | Generate AI-ranked charging itineraries with closing/maintenance buffer checks |

* **Validation:**
  * Prevented past-date or out-of-bounds bookings (enforcing the 7-day booking horizon).
  * Validated that `EndTime > StartTime` and duration adheres to allowable station minimums/maximums.
  * Enforced wallet solvency checks: driver must possess $\ge$ LKR 500.00 for immediate advance confirmation.
  * Strict role-based authorization ensuring drivers cannot approve their own reservations or access unowned records.
* **Business-Specific Operations:**
  * **Pessimistic Row Locking & Slot Exclusions:** Handled concurrent booking attempts using PostgreSQL transactional isolation to eliminate double-booking race conditions between online drivers and on-site walk-ins.
  * **Operational Buffer Detection Integration:** Handled the `RequiresApproval` flag originating from the AI planning coordinator, guaranteeing that high-risk edge cases are held in a deferred state until manual operator review.

---

### 2.3 Database Work
* **Entities / Tables:**
  * `Reservations`: Primary table tracking booking slots (`Id`, `DriverId`, `ChargerId`, `VehicleId`, `StartTime`, `EndTime`, `ReservationQRCode`, `AdvanceDepositAmount`, `ApprovalRequired`, `ApprovalReason`, `Status`, `CreatedAt`, `UpdatedAt`).
  * `ReservationApprovals`: Edge-case tracking table (`Id`, `ReservationId`, `StationOwnerId`, `TriggerReason`, `BufferMinutes`, `Status`, `DecisionNotes`, `RequestedAt`, `DecidedAt`).
  * `ReservationStatusHistory`: Immutable audit log (`Id`, `ReservationId`, `OldStatus`, `NewStatus`, `ChangedByUserId`, `ChangedAt`).
  * `ChargingPlans`: Stores multi-agent planning outputs (`Id`, `WorkflowRunId`, `DriverId`, `Deadline`, `RankedItinerariesJson`, `CreatedAt`).
* **Relationships:**
  * `Users` (1) $\rightarrow$ (N) `Reservations`: Foreign key on `DriverId` (configured as **NULLable** to permit walk-in drivers).
  * `Chargers` (1) $\rightarrow$ (N) `Reservations`: Foreign key on `ChargerId` (Cascade restricted on active reservations).
  * `Reservations` (1) $\rightarrow$ (1) `ReservationApprovals`: Unique foreign key on `ReservationId`.
  * `Reservations` (1) $\rightarrow$ (N) `ReservationStatusHistory`: One-to-many relationship tracking complete state lifecycles.
  * `Reservations` (1) $\rightarrow$ (0..1) `ChargingSessions`: Direct linkage established upon QR check-in or walk-in admission.
* **Constraints:**
  * **GiST Exclusion Anti-Double-Booking Constraint:**
    ```sql
    ALTER TABLE "Reservations" 
    ADD CONSTRAINT "no_overlapping_reservations" 
    EXCLUDE USING gist (
        "ChargerId" WITH =, 
        tsrange("StartTime", "EndTime") WITH &&
    ) WHERE ("Status" NOT IN ('Cancelled', 'Rejected'));
    ```
  * **Check Constraints:** Enforced domain states: `Status IN ('Pending', 'PendingApproval', 'Confirmed', 'CheckedIn', 'Cancelled', 'Completed', 'Rejected')`.
  * **Unique Constraints:** Enforced global uniqueness on `ReservationQRCode`.
* **EF Core Migrations:**
  * Created migrations to introduce `ReservationApprovals` and schema fields (`ApprovalRequired`, `ApprovalReason`).
  * Updated `DriverId` column to be nullable to enable walk-in support.
  * Added indexes on `(ChargerId, StartTime, EndTime)` and `Status` to optimize availability queries.
* **Seed Data:**
  * Seeded initial reservations across test stations and chargers representing diverse states (`Confirmed`, `PendingApproval`, `CheckedIn`, `Completed`) with realistic timestamps to validate slot computation and reporting views.

---

### 2.4 React Work
* **Pages:**
  * `ReservationsPage.jsx`: Comprehensive management view featuring tabbed navigation (`All Reservations`, `Pending Approvals`, `Confirmed`, `Past Sessions`), status badges, search by driver email/plate, and action triggers.
* **Components:**
  * `ReservationDetailsModal.jsx`: Modal displaying complete booking telemetry, vehicle details, driver contact info, status progression timeline, QR code representation, and Cloudinary physical meter photo evidence attached to completed sessions for visual auditing.
  * `AddReservationModal.jsx`: Administrative booking modal allowing station staff to manually reserve a charger slot for a customer, featuring charger selection, date picker, and duration inputs.
  * `PendingApprovalsCard.jsx`: Dedicated dashboard widget alerting station owners to edge-case reservations requiring manual review, providing inline `Approve` and `Reject` buttons with optional justification notes.
* **API Integration:**
  * `useReservations.js`: Custom hook utilizing TanStack Query (`useQuery`, `useMutation`) for fetching reservation lists, invalidating caches upon approval/rejection/cancellation, and polling pending approval counts.
* **Forms & Validation:**
  * Built client-side validation in `AddReservationModal` verifying that selected dates fall within allowable operational windows and start times precede end times.
* **Search / Filter / UI Logic:**
  * Implemented client-side and server-side filtering by station, charger, reservation status, and date range.
  * Designed visual cues (amber warning badges for `PendingApproval` reservations, green for `Confirmed`, blue for `CheckedIn`).

---

### 2.5 Flutter Work
* **Screens:**
  * `create_reservation_screen.dart`: Driver booking interface for direct map reservations, displaying charger specifications, cost calculations, available time slots, and the advance wallet confirmation modal.
  * `ai_planning_screen.dart`: Interactive route planning screen where drivers input destination, arrival deadline, max distance, and price preference; displays ranked itinerary cards generated by the Agentic AI with operational buffer indicators.
  * `reservation_list_screen.dart`: Tabbed view for drivers showing upcoming, pending approval, and past reservations, including visual QR code tokens for easy check-in display.
  * `staff_dashboard_screen.dart` / `walk_in_booking_screen.dart`: Dedicated staff POS interface enabling station attendants to quickly admit walk-in drivers, lock physical chargers, and monitor active bays.
  * `qr_scanner_screen.dart`: High-performance camera scanner for station staff, reading driver QR tokens, verifying authenticity via API, and instantly initiating the charging session.
  * `smart_recommendation_card.dart`: Driver home screen widget providing one-tap access to AI recommendations and displaying the agent's real-time reasoning.
* **API Integration:**
  * Built `PlanningApiClient` handling JSON serialization/deserialization for `PlanningRequest` and `PlanningResponse`.
  * Implemented `ReservationService` in Dart interfacing with the ASP.NET Core endpoints with automatic bearer token injection and error handling.
* **Forms / Workflows:**
  * Structured the multi-step booking flow: Selection $\rightarrow$ Operational Buffer Check (if AI itinerary) $\rightarrow$ Advisory Banner Display $\rightarrow$ Deferred Deposit Confirmation $\rightarrow$ Submission.
* **Device Features:**
  * **Camera Access:** Integrated `mobile_scanner` in `qr_scanner_screen.dart` with auto-pause and debounce controls to prevent scanner loop re-triggers.
  * **Geolocation:** Utilized `geolocator` to capture driver coordinates for distance calculations against candidate charging stations.

---

### 2.6 Agentic AI Work
* **Agent / Responsibility:**
  * Owned the **Charging Recommendation & Planning Coordinator Agent** (`PlanningCoordinatorAgent.py`), responsible for synthesizing driver constraints (deadline, budget, location) and orchestrating sub-agents (`VehicleCompatibilityAgent` and `StationAnalysisAgent`) to generate optimal, executable charging plans.
* **AI Workflow:**
  * **Step 1 (Ingestion & Normalization):** Parses `PlanningRequest`, converts timestamps to Sri Lanka local time (UTC+05:30), and checks urgency (deadline $< 60$ minutes).
  * **Step 2 (Compatibility Screening):** Calls `VehicleCompatibilityAgent` to filter out candidate chargers with incompatible connector pinouts or inadequate power levels.
  * **Step 3 (Congestion & Station Analysis):** Invokes `StationAnalysisAgent` to assess live utilization, historical availability scores, and tariff competitiveness. Highly congested stations are filtered out during urgent requests.
  * **Step 4 (LLM Prompting & Itinerary Synthesis):** Passes the vetted station pool to the LLM (Groq) using structured prompt templates to select and rank the top 2 distinct stations.
  * **Step 5 (Deterministic Post-Processing & Guardrails):** Programmatically overrides LLM duration and cost estimates using exact physics and math:
    $$\text{Actual Rate (kW)} = \min(\text{Charger Power}, \text{Vehicle Max Charge Rate})$$
    $$\text{Duration (mins)} = \text{round}\left(\frac{\text{Battery Capacity (kWh)}}{\text{Actual Rate (kW)}} \times 60\right)$$
    $$\text{Estimated Cost} = \text{round}(\text{Actual Rate} \times \frac{\text{Duration}}{60} \times \text{Tariff}, 2)$$
  * **Step 6 (Operational Buffer & HITL Evaluation):** Compares computed session completion time against station closing time and scheduled charger maintenance windows. If completion falls within 15 minutes of closing or maintenance, the coordinator automatically flags `requires_approval = True` and appends explanatory reasoning.
* **Tools Used:**
  * `evaluate_station`: Compatibility tool checking connector hardware and maximum power rates.
  * `analyze`: Station analysis tool returning real-time congestion scores and pricing competitiveness.
* **Structured Input / Output:**
  * Implemented using Pydantic models (`PlanningRequest`, `PlanningResponse`, `ItineraryStep`, `AgentStationInput`, `AgentChargerInput`).
  * Enforced structured output binding via `llm.with_structured_output(PlanningResponse)`.
* **Validation & Guardrails:**
  * Replaced LLM mathematical hallucinations with deterministic calculations.
  * Standardized timezone parsing to guarantee that ISO-8601 UTC strings from ASP.NET Core match Sri Lankan local operational schedules.
  * Protected against prompt injection by passing station data as structured JSON contexts rather than unescaped natural text.
* **Human Approval (HITL):**
  * When `requires_approval = True`, the plan alerts the driver that the selected slot requires operator review. When submitted to the backend, the reservation enters `PendingApproval`, deferring the advance wallet deposit until the station owner signs off.
* **Workflow State:**
  * Managed state transitions across the coordinator pipeline, recording execution metadata and linking plans to database records via `WorkflowRunId`.

---

### 2.7 Testing Work
To ensure high reliability across critical booking transactions and AI recommendations, I implemented extensive test suites across all layers of the platform:
1. **Backend Tests (ASP.NET Core / xUnit):**
   * `ReservationServiceTests.cs` (**62 Unit Tests**): Thoroughly tested standard booking creation, wallet pre-auth deposit deductions, double-booking prevention, walk-in customer admissions, cancellation refunds, staff QR check-ins, time-slot updates, slot availability calculations excluding maintenance windows, and operator `ApproveAsync`/`RejectAsync` workflows including role-based security assertions.
   * `ReservationTimezoneTests.cs` (**4 Unit Tests**): Tested UTC to local timezone conversions, boundary edge cases, 7-day advance booking horizons, and rejection of past time slots.
   * `ChargingPlansControllerTests.cs` (**2 Unit Tests**): Verified successful itinerary generation dispatch to the AI agent client (200 OK) and graceful fallback handling on agent microservice downtime (503 Service Unavailable).
   * `LateCancellationFeeTests.cs` (**22 Unit Tests**): Verified advance deposit retention, refund percentage calculations within late cancellation cut-offs, and wallet ledger integrity.
   * `ReservationEndpointsTests.cs` (**3 Integration Tests**): Verified unauthenticated request rejection (401 Unauthorized), insufficient wallet deposit validation (400 Bad Request), and role-based walk-in restriction rejecting non-staff drivers (403 Forbidden).
2. **Agentic AI Tests (Python / pytest):**
   * `test_planning_coordinator_agent.py` (**4 Tests**): Verified multi-agent LangGraph workflow execution, operational buffer detection (15-minute closing and maintenance threshold), urgency-based station filtering, and deterministic charge duration calculations.
3. **Web React Tests (Vitest & React Testing Library):**
   * `useReservations.test.jsx` (**9 Tests**): Verified query fetching, pagination, mutation updates, cache invalidation, and pending approval polling.
   * `ReservationDetailsModal.test.jsx` (**6 Tests**): Verified modal rendering, time-slot editing, cancellation dialogs, deletion actions, and Cloudinary physical meter photo rendering.
   * `ReservationsPage.test.jsx` (**6 Tests**): Verified tab switching, status filtering, and the pending approvals banner.
   * `AddReservationModal.test.jsx` (**3 Tests**): Tested form validation, charger dropdown population, and submission handling.
4. **Mobile Flutter Tests (`flutter_test`):**
   * `planning_api_client_test.dart` (**4 Tests**): Verified JSON serialization/deserialization for `PlanningRequest` and `PlanningResponse`, HTTP 200 handling, and error containment.
   * `reservation_models_test.dart` (**4 Tests**): Verified data model mapping for `ReservationDto` and `CreateReservationRequest` with `requiresApproval` attributes.

---

## 3. Key Commit, Pull Request, and Test Evidence

### 3.1 Key Git Commits

| Commit Hash | Description / What Was Implemented | Evidence |
| :--- | :--- | :--- |
| `a82c1b2` | `feat(reservations): expand advance booking horizon to 7 days and update tests & docs` — Extended booking window logic, updated timezone validation boundaries, and synced unit tests. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `96a88f6` | `test(reservations): expand unit tests and fix operating hours timezone boundary` — Resolved UTC/local timezone discrepancies in operating hours evaluation and added comprehensive test coverage. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `9a0b574` | `feat: Integrate AI reservation planning and streamline staff dashboard approval flows` — Implemented operator approval endpoints (`ApproveAsync`/`RejectAsync`), `PendingApprovalsCard`, and connected planning coordinator. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `c2f519e` | `Merge pull request #51 from Naviya2/feature/reservation-enhancements` — Merged end-to-end reservation and planning enhancements into `dev`. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `32b0e90` | `test: added all the missed tests related to reservation component` — Added comprehensive xUnit test coverage for reservation services, controllers, and edge-case workflows. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `4327de3` | `fix: enhances ui s in reservation making and walk-in customer check-in process, fix cost calculation issue, enhances reservation details model in web interfaces` — Refactored React reservation details modal, fixed Flutter check-in loop, and calibrated cost estimation. | `[GitHub Commit Link / Screenshot Placeholder]` |
| `a2e79a4` | `feat/refactor: fully remove waitlist system, implement location-aware AI recommendations, and improve mobile UX` — Streamlined architecture by replacing legacy waitlist with real-time AI planning recommendations. | `[GitHub Commit Link / Screenshot Placeholder]` |

---

### 3.2 Pull Request Evidence
* **PR Number & Title:** **PR #51: Feature – Reservation & AI Charging Planning Enhancements**
* **Purpose:** To complete the core booking and AI planning capabilities of ChargeSync, integrating the operator approval workflow for boundary slots, preventing double-bookings with PostgreSQL GiST constraints, and connecting the mobile and web clients to the Agentic AI coordinator.
* **Main Changes:**
  * Implemented `ApproveAsync` and `RejectAsync` in `ReservationService.cs` with role-based security checks and deferred wallet deposit deduction.
  * Added `ChargingPlansController.cs` in ASP.NET Core with distance calculations, charger availability filtering, and `X-Agent-Service-Key` microservice communication.
  * Implemented `PlanningCoordinatorAgent.py` in Python with LangGraph, including the 15-minute operational buffer detection for closing and maintenance windows.
  * Created `PendingApprovalsCard.jsx`, `ReservationDetailsModal.jsx`, and `ReservationsPage.jsx` in the React portal.
  * Implemented `ai_planning_screen.dart`, `create_reservation_screen.dart`, and `qr_scanner_screen.dart` in Flutter.
  * Added 90 backend unit tests, 3 backend integration tests, 4 Python tests, 24 React tests, and 8 Flutter tests.
* **Review & Approval:** Peer reviewed and approved by team members; verified that all CI/CD pipeline checks passed cleanly across backend, web, and mobile runners.
* **Merge Status:** Merged into `dev` branch via commit `c2f519e`.

`[Insert GitHub Pull Request Screenshot here]`

---

### 3.3 Test Evidence

| Test Name | Purpose / What it Verifies | Result |
| :--- | :--- | :--- |
| `CreateAsync_DeductsWalletBalance_And_SetsConfirmed` | Verifies standard booking deducts LKR 500 deposit and issues QR token | **Pass** |
| `CreateAsync_NearClosingTime_SetsPendingApproval_AndDefersDeposit` | Verifies slot ending $< 15$m from closing sets `PendingApproval` with LKR 0 fee | **Pass** |
| `ApproveAsync_CapturesDeferredDeposit_AndGeneratesQRCode` | Verifies operator approval captures LKR 500 and transitions status to `Confirmed` | **Pass** |
| `RejectAsync_ReleasesSlot_WithZeroPenalty` | Verifies operator rejection releases slot without deducting wallet balance | **Pass** |
| `CreateWalkInAsync_NullDriverId_LocksChargerImmediately` | Verifies on-site walk-in creates booking with `DriverId = null` and `CheckedIn` status | **Pass** |
| `StaffCheckinAsync_ValidQRCode_TransitionsToCheckedIn` | Verifies staff scanning valid QR token confirms driver arrival and starts session | **Pass** |
| `GiST_Exclusion_Rejects_Overlapping_Time_Slots` | Verifies PostgreSQL rejects overlapping bookings on the same charger | **Pass** |
| `ReservationTimezoneTests.Booking_Within_7_Days_Succeeds` | Verifies advance booking horizon correctly validates up to 7 calendar days | **Pass** |
| `ReservationTimezoneTests.Past_Time_Booking_Throws_Exception` | Verifies system rejects reservation requests scheduled in the past | **Pass** |
| `ChargingPlansControllerTests.GenerateChargingPlan_ReturnsOk_WhenAgentSucceeds` | Verifies controller dispatches valid plan payload and returns 200 OK | **Pass** |
| `ChargingPlansControllerTests.GenerateChargingPlan_Returns503_WhenAgentFails` | Verifies controller handles AI service timeouts gracefully with 503 Service Unavailable | **Pass** |
| `ReservationEndpointsTests.CreateReservation_WithoutAuth_ReturnsUnauthorized` | Verifies unauthenticated POST requests are rejected with 401 Unauthorized | **Pass** |
| `ReservationEndpointsTests.CreateReservation_WithInsufficientBalance_ReturnsBadRequest` | Verifies drivers with insufficient wallet balance are rejected with 400 Bad Request | **Pass** |
| `ReservationEndpointsTests.CreateWalkIn_AsDriver_ReturnsForbidden` | Verifies walk-in creation endpoint enforces role-based policy rejecting drivers with 403 Forbidden | **Pass** |
| `pytest: test_planning_coordinator_agent.py` | Verifies multi-agent LangGraph execution and 15-minute buffer conflict detection | **Pass** |
| `Vitest: useReservations.test.jsx` | Verifies TanStack Query hooks, pagination, and pending approval invalidation | **Pass** |
| `Vitest: ReservationDetailsModal.test.jsx` | Verifies modal rendering, time editing, and Cloudinary meter photo display | **Pass** |
| `FlutterTest: planning_api_client_test.dart` | Verifies mobile HTTP client JSON mapping and error handling | **Pass** |

*Screenshots to attach in Word document:*
- [ ] Test execution in IDE / Terminal (`dotnet test`, `pytest`, `npm test`, `flutter test`)
- [ ] Successful test results and summary counts
- [ ] CI/CD GitHub Actions pipeline execution results (`.github/workflows/backend-ci.yml`, `web-ci.yml`, `mobile-ci.yml`)

---

## 4. Challenges and Learning

### 4.1 Challenges & Solutions

| Technical Challenge | How You Solved It |
| :--- | :--- |
| **Concurrency & Double-Booking Prevention**<br>Simultaneous reservation attempts by mobile drivers and on-site walk-ins could lead to double-booked charger bays. | Configured PostgreSQL GiST exclusion constraints (`EXCLUDE USING gist`) combined with pessimistic row-level locking (`SELECT ... FOR UPDATE`) in EF Core transactions, ensuring guaranteed hardware slot exclusivity at the database level. |
| **Timezone Inconsistencies Across Stack**<br>Discrepancies between database `TIMESTAMPTZ` (UTC), station local operating hours (Sri Lanka Standard Time, UTC+05:30), and user mobile devices caused erroneous slot rejections at day boundaries. | Enforced an architectural rule where all database storage and API communication use UTC ISO-8601 timestamps, while local operating hours calculations apply an explicit `TimeSpan.FromHours(5.5)` offset during scheduling window comparisons in both C# and Python. |
| **Operational Buffer & Deferred Deposit Flow in AI Planning**<br>Drivers booking AI-suggested itineraries finishing near station closing or scheduled maintenance risked being locked out or stranded without recourse if charged upfront. | Designed a Human-in-the-Loop (HITL) workflow within the AI coordinator: slots finishing within 15 minutes of closing or maintenance trigger an advisory banner, set `PendingApproval`, defer the LKR 500 deposit to LKR 0.00, and alert the station owner for explicit review. |
| **LLM Hallucinations in Charge Durations & Costs**<br>General-purpose LLMs frequently generated inaccurate charging durations and unrealistic monetary estimates for Sri Lankan tariffs. | Implemented a deterministic post-processing layer in `PlanningCoordinatorAgent.py`. The LLM ranks candidate stations, but charging duration and cost calculations are programmatically overwritten using physical battery capacities and exact tariff rates. |
| **Mobile QR Scanner Loop Re-triggering**<br>The Flutter mobile camera scanner continuously re-read the same QR code multiple times per second, triggering duplicate check-in API calls. | Implemented a scan controller debounce flag and state lock in `qr_scanner_screen.dart`, instantly pausing the camera feed upon successful detection until the API response completes. |

---

### 4.2 Learning
* **ASP.NET Core Web API:** Deepened expertise in enterprise Clean Architecture, custom authorization policy handlers, dependency injection lifetimes, and high-performance asynchronous transaction management.
* **PostgreSQL / EF Core:** Mastered advanced relational database capabilities, including GiST temporal exclusion constraints, database indexing strategies, query execution profiling, and database migration lifecycles.
* **React / Frontend State:** Gained hands-on experience in building scalable enterprise dashboards using TanStack Query for declarative caching, optimistic UI updates, and modular modal architectures.
* **Flutter / Mobile Development:** Enhanced mobile development skills in state management using Riverpod, hardware camera sensor integration, geolocation capturing, and responsive cross-platform layout design.
* **Agentic AI:** Acquired comprehensive understanding of multi-agent orchestration with LangGraph, structured Pydantic output parsing, prompt engineering, and implementing reliable guardrails around generative models.
* **Security (JWT / RBAC):** Implemented strict role-based access control, cryptographic token generation for QR codes, and constant-time HMAC secret validation (`X-Agent-Service-Key`) for inter-service communication.
* **Testing, Git, and CI/CD:** Mastered multi-tier automated testing (xUnit, pytest, Vitest, Flutter test), automated GitHub Actions workflow automation, and feature-branch Git collaboration.

---

## 5. Individual AI Usage Log

*The following log summarizes the selective, human-directed utilization of AI tools during development, focused on syntax references and boilerplate scaffolding:*

| Date | AI Tool / Model | Task | How AI Was Used | Changes / Verification Applied |
| :--- | :--- | :--- | :--- | :--- |
| `2026-09-24` | GitHub Copilot / LLM | PostgreSQL GiST syntax | Consulted for syntax reference on PostgreSQL temporal GiST range exclusion constraints in EF Core. | Reviewed PostgreSQL documentation, manually wrote the migration script, and verified constraint behavior using concurrent unit tests. |
| `2026-09-28` | Claude 3.5 Sonnet | DTO Scaffolding | Generated initial C# record boilerplate for reservation and planning data transfer objects. | Heavily customized fields to match domain models, added validation annotations, and integrated with application interfaces. |
| `2026-10-01` | GPT-4o | LangGraph boilerplate | Referenced syntax for structured Pydantic output binding in LangChain. | Refactored into `PlanningCoordinatorAgent.py`, added custom deterministic duration overrides, and wrote pytest validation suites. |
| `2026-10-03` | Claude 3.5 Sonnet | Controller Security Review | Inquired about best practice patterns for role-based authorization attributes vs anonymous access on ASP.NET Core planning endpoints. | Enforced strict `[Authorize(Policy = "Driver")]` protection, updated the controller logic to securely pass candidate charger statuses, and validated via controller unit tests. |
| `2026-10-04` | ChatGPT | Environment Config Debugging | Consulted regarding environment variable precedence and configuration loading behavior in Python FastAPI / Pydantic BaseSettings. | Identified that the running process was missing local environment key context; configured `.env` file resolution and verified secure key loading into the LLM provider. |
| `2026-10-05` | GitHub Copilot | Flutter UI Card Layout | Looked up responsive layout patterns to display dynamic-length AI reasoning text inside a card widget without layout overflow. | Implemented flexible container wrapping with null-safe text fallbacks and verified rendering across different mobile screen densities. |

---

## 6. Individual AI Reflection

### 6.1 AI Tools and Development Stages
During the development of the ChargeSync platform, AI tools were utilized selectively as developer productivity aids rather than autonomous creators. They were primarily consulted during the early implementation phases for syntax verification, boilerplate DTO drafting, and quick technical documentation lookups. 

All core architectural decisions—such as the hybrid operational model, the design of the Human-in-the-Loop operator approval gate, concurrency control strategies, database normalization, and business workflow logic—were human-engineered. During testing and refactoring, AI suggestions were strictly evaluated against domain requirements, with all final implementations hand-crafted and validated through rigorous automated tests.

### 6.2 What AI Did Well
AI assistance proved beneficial for accelerating repetitive boilerplate generation, such as drafting initial C# DTO records, creating basic Pydantic model schemas, and providing initial syntax patterns for complex framework APIs (e.g., LangGraph state schemas and Npgsql migration configurations). This reduced initial typing time and allowed me to focus on core domain algorithms, concurrency handling, and system integration.

### 6.3 What AI Got Wrong / What You Changed
AI models demonstrated significant limitations when dealing with multi-system business invariants and domain-specific edge cases:
1. **Mathematical & Physics Hallucinations:** When prompted to calculate EV charging durations, the LLM frequently hallucinated values that disregarded the relationship between battery capacity (kWh) and charger power output (kW). I resolved this by discarding LLM-generated durations and implementing deterministic mathematical calculations directly in Python.
2. **Timezone Misunderstandings:** AI suggestions frequently mixed UTC timestamps with local timezones, leading to bugs where operating hours checks failed at midnight boundaries. I replaced these with an explicit timezone offset architecture in both C# and Python.
3. **Flawed Concurrency Assumptions:** AI boilerplate initially suggested simple application-level `if` checks for reservation availability, which are vulnerable to race conditions under concurrent requests. I replaced this approach with database-level GiST exclusion constraints and pessimistic row-level locking.
4. **Security Vulnerabilities:** Suggested API endpoints initially lacked proper role-based authorization barriers, which would have allowed drivers to approve their own edge-case bookings. I implemented strict ASP.NET Core authorization policies (`AuthorizationPolicies.StationOwner`) to enforce separation of concerns.

### 6.4 Verification and Learning
Every piece of code introduced into the repository was subjected to a strict verification protocol:
1. **Manual Architectural Review:** Ensuring that all data flow adhered to the repository's Clean Architecture and separation-of-concerns principles.
2. **Static Analysis & Linting:** Running automated language analyzers to eliminate security flaws, unhandled exceptions, and unused dependencies.
3. **Automated Test Validation:** Writing and executing comprehensive xUnit, pytest, Vitest, and Flutter test suites covering happy paths, edge cases, and boundary conditions.
4. **End-to-End Runtime Debugging:** Verifying end-to-end communication across the mobile client, web dashboard, ASP.NET Core API, and Python agent service in live development environments.

This rigorous verification process deepened my technical mastery across full-stack engineering, concurrency control, and the critical importance of defensive programming when integrating AI components into mission-critical software systems.

---

## 7. Signed Declaration

I hereby certify that the work and evidence presented in this report represent my own individual contributions to the project, created in accordance with university academic integrity standards.

* **Student Name:** [Student Name]
* **Student ID:** [Student ID]
* **Signature:** ___________________________
* **Date:** 05/10/2026
