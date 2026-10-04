# ChargeSync
### Intelligent EV Charging Reservation and Recommendation Platform

> **SE3090 – Software Engineering Frameworks** · BSc (Hons) in Software Engineering · SLIIT · Year 3, Semester 1, 2026

---

## 1. Project Overview

**ChargeSync** connects EV drivers, charging station owners, platform administrators, and customer support into one integrated system. Instead of drivers hunting for an available, compatible charger and hoping for the best, ChargeSync uses an **Agentic AI subsystem** to check vehicle-charger compatibility, analyse station data, and generate a ranked, multi-step charging plan tailored to the driver's objective (deadline, distance, price preference) — with a human approval gate on any action that overrides normal booking rules.

The platform is built as one coherent full-stack application: a shared **ASP.NET Core Web API** and **PostgreSQL** database serve both a **React** admin/owner/support dashboard and a **Flutter** driver-facing mobile app, with a **Python + LangGraph** agent service handled entirely behind the API (never called directly by either client).

The system incorporates a **hybrid operational model** designed for markets with varied smartphone digital literacy, no direct vehicle-to-charger IoT telemetry, and high prevalence of on-site cash transactions — supported by a staff point-of-sale (POS) workflow built into the Flutter app.

---

## 2. Problem Statement

As EV adoption grows, drivers struggle to find a station that is actually compatible with their vehicle, available at the right time, and worth the price — often arriving to find a charger occupied, incompatible, or under maintenance. Independent station owners lack a simple platform to list stations, manage chargers, and understand utilisation. ChargeSync solves both sides with a shared platform and an AI layer that plans the best charging option for a driver's specific request.

---

## 3. User Roles

| Role | Responsibilities |
|---|---|
| **EV Driver** | Registers vehicles, searches/gets AI-recommended stations, reserves slots via advance wallet payment, checks in via QR, manages membership/loyalty/wallet, submits support tickets |
| **Station Staff / Station Owner** | Registers and manages stations/chargers/pricing/hours via React portal (support tickets restricted to Admin/Support); operates Flutter POS on-site to scan QR codes, admit walk-in customers, capture meter photo evidence, log physical meter readings, stop sessions, and collect cash |
| **Platform Administrator** | Full administrative control: manages all registered vehicles across all drivers (system-wide CRUD), approves station registrations, manages users, reviews support tickets and meter photo verification records, approves high-impact AI actions, audits meter discrepancies |
| **Customer Support Manager** | Handles support tickets, investigates reservation/session/billing issues, reviews refund proposals exceeding $15 |

---

## 4. Core Business Components

| # | Component | Summary |
|---|---|---|
| 1 | **Vehicle & AI Compatibility Discovery** | Vehicle registration (make, model, connector, battery, charge rate), driver and platform administrator vehicle management across all drivers, compatibility scoring, nearby station search |
| 2 | **Station, Charger & Operating-Hours Management** | Station/charger CRUD, operating hours, maintenance windows, automatic real-time availability, utilisation analytics |
| 3 | **Reservation & AI Charging Planning** | Conflict-free advance reservations with wallet pre-auth, QR token generation, staff QR check-in, walk-in admission, AI-ranked charging plans, reservation details with physical meter photo display |
| 4 | **Session, Payment, Loyalty & Support Management** | Hybrid energy calculation (auto-calculated vs. staff physical meter override with Cloudinary photographic proof), invoice generation, cash/wallet settlement, 15% discrepancy fraud flag, membership subscriptions, loyalty tiers & redemptions, support ticket triage (Admin/Support portal) |

Full endpoint lists, entities, and business-specific operations for each component are documented in [`docs/group-report/ChargeSync_SRS`](docs\group-report\ChargeSync_SRS.pdf).

---

## 5. Agentic AI Subsystem

Four distinct agents, orchestrated with **LangGraph**, share one underlying LLM but are differentiated by system prompt, allow-listed tools, and a defined input/output contract:

| Agent | Responsibility |
|---|---|
| **Vehicle Compatibility Agent** | Determines whether a vehicle can safely/efficiently use a given charger; suggests alternatives if not |
| **Station Analysis Agent** | Evaluates a station's real-time availability, pricing, and utilisation; answers candidacy queries from the planner |
| **Charging Recommendation & Planning Agent** (coordinator) | Receives a driver's objective, builds a structured multi-step plan, delegates to the other agents, ranks final options |
| **Validation & Support Agent** | Inspects session records, checks business constraints, flags meter overrides, triages support tickets, validates reward redemptions |

**Human-in-the-loop approval triggers** — execution pauses in `PendingApproval` state requiring manual review in the React portal when:
- A refund recommendation exceeds **$15.00**
- A loyalty redemption exceeds **5,000 points** or **$50.00** value
- An AI charging plan recommendation requires station owner/staff approval before confirmation
- A staff meter override departs from the auto-calculated value by **> 15%**

**Internal Service Security & Endpoints**:
The Agentic AI service is reachable only via the ASP.NET Core backend and is secured with an internal service key header (`X-Agent-Service-Key`) using constant-time comparison (`secrets.compare_digest`). Exposed endpoints include:
- `POST /api/compatibility/evaluate` & `/api/compatibility/batch-evaluate` — Hardware compatibility assessment
- `POST /api/station-analysis/evaluate` — Station utilization and scoring
- `POST /api/charging-plan/generate` — Multi-agent coordinator charging plan generation
- `POST /api/support/analyze` & `POST /api/workflows/support` — Automated support ticket triage & workflow execution

---

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Backend API | ASP.NET Core Web API (C# 12, .NET 8) |
| Database | PostgreSQL 15 + Entity Framework Core (Npgsql) |
| Web Portal | React 18 (Vite, TanStack Query, React Router v6, Zustand) |
| Mobile App | Flutter 3 (Dart) — dual Driver / Station Staff dashboards |
| Agentic AI | Python 3.11 + LangGraph + FastAPI (internal service) |
| LLM Provider | Ollama (local/dev) → Groq API (deployed) |
| Auth | JWT bearer tokens + role-based authorization |
| Media Storage | Cloudinary (meter photo uploads from session checkout) |
| Third-Party Services | Google Maps API (station discovery), Firebase Cloud Messaging (push notifications) |
| CI/CD | GitHub Actions (triggers on `main` and `dev` branches) |

---

## 7. Repository Structure

```
ChargeSync/
├── backend/               # ASP.NET Core Web API (C#)
│   ├── src/Api/           # Controllers, middleware, program setup
│   ├── src/Application/   # Services, interfaces, DTOs
│   ├── src/Domain/        # Entities, enums, domain logic
│   ├── src/Infrastructure/# EF Core DbContext, migrations, configurations
│   └── tests/             # Unit + integration tests (xUnit, Moq)
├── agentic-ai/            # Python + LangGraph agent service (internal only)
│   ├── agents/            # Individual agent implementations
│   └── tests/             # pytest test suites per agent
├── web-react/             # React admin/owner/support dashboard (Vite)
│   ├── src/features/      # Feature modules (vehicles, users, stations, etc.)
│   ├── src/api/           # Axios client + typed endpoint modules
│   ├── src/store/         # Zustand global state
│   └── tests/             # Vitest + React Testing Library
├── mobile-flutter/        # Flutter driver + station staff app
│   ├── lib/features/      # Feature screens and widgets
│   ├── lib/core/api/      # HTTP clients and models
│   └── test/              # flutter_test unit + widget tests
├── database/              # ER diagram, schema notes, seed data
├── docs/                  # SRS, ADRs, group & individual reports
│   └── group-report/chargesync.md  # Full SRS (v2.0)
└── .github/workflows/     # CI pipelines (backend, web, mobile)
```

---

## 8. Getting Started

### Prerequisites
- .NET SDK 8+
- Node.js 22+
- Flutter SDK 3.x
- Python 3.11+
- PostgreSQL 15+
- Ollama (for local agent development) — https://ollama.ai

### Startup Order
1. PostgreSQL (running and migrated)
2. Agentic AI service
3. ASP.NET Core backend (depends on DB + agent service)
4. React and/or Flutter clients

---

### 8.1 Backend (ASP.NET Core)
```bash
cd backend
cp appsettings.Example.json appsettings.Development.json   # fill in your local DB connection string
dotnet restore
dotnet ef database update      # applies migrations
dotnet run --project src/Api
```
API runs at `https://localhost:5001` · Swagger UI at `https://localhost:5001/swagger`

---

### 8.2 Agentic AI Service (Python + LangGraph)
```bash
cd agentic-ai
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # set LLM_PROVIDER=ollama (default) or groq + API key
uvicorn main:app --reload --port 8000
```
Ensure Ollama is running locally (`ollama serve`) before starting if `LLM_PROVIDER=ollama`.

---

### 8.3 React Web Portal
```bash
cd web-react
cp .env.example .env         # set VITE_API_BASE_URL
npm install
npm run dev
```

---

### 8.4 Flutter Mobile App
```bash
cd mobile-flutter
cp .env.example .env         # set API base URL
flutter pub get
flutter run                  # or build APK: flutter build apk --release
```

---

## 9. Environment Variables

### 9.1 Backend (ASP.NET Core Web API)
Configured via `appsettings.json`, `appsettings.Development.json`, environment variables, or .NET user-secrets:

| Variable / Key | Type | Default / Example | Description |
|---|---|---|---|
| `ConnectionStrings:Postgres` | String | `Host=localhost;Port=5432;Database=chargesync;Username=postgres;Password=...` | PostgreSQL relational database connection string |
| `Jwt:Key` | String | *Min. 32-character secret* | HMAC-SHA256 signing secret key used to sign and validate JWT tokens |
| `Jwt:Issuer` | String | `ChargeSync` | JWT issuer claim (`iss`) |
| `Jwt:Audience` | String | `ChargeSync` | JWT audience claim (`aud`) |
| `Jwt:AccessTokenMinutes` | Integer | `60` | Lifetime of issued JWT access tokens before refresh is required |
| `Jwt:RefreshTokenDays` | Integer | `30` | Rotation lifetime of refresh tokens stored in database |
| `Groq:ApiKey` | String | `gsk_...` | Groq Cloud API key for fast LLM inference |
| `Groq:Model` | String | `openai/gpt-oss-120b` | Model identifier used by backend agent clients |
| `AGENT_SERVICE_BASE_URL` | String | `http://localhost:8000` | Internal URL where the Python LangGraph microservice runs |
| `AGENT_SERVICE_API_KEY` | String | *Shared secret* | Shared authentication secret sent via `X-Agent-Service-Key` header |
| `OpenRouteService:ApiKey` | String | *ORS Token* | API key for OpenRouteService distance matrix and turn-by-turn routing |
| `PayHere:Enabled` | Boolean | `false` | Feature toggle to enable or bypass real PayHere gateway integration |
| `PayHere:Sandbox` | Boolean | `true` | Toggles between PayHere Sandbox and Live payment gateway |
| `PayHere:MerchantId` | String | `1234567` | PayHere registered merchant identifier |
| `PayHere:MerchantSecret` | String | *Secret* | Merchant secret used to generate MD5 payment verification signatures |
| `PayHere:PublicBaseUrl` | String | `https://api.chargesync.example` | Publicly reachable origin for PayHere checkout and IPN webhooks |
| `Seed:AdminFullName` | String | `Platform Administrator` | Seeded platform administrator display name |
| `Seed:AdminEmail` | String | `admin@chargesync.com` | Seeded platform administrator email address |
| `Seed:AdminPassword` | String | `Password123!` | Seeded platform administrator initial password |
| `SupportWorkflow:RefundApprovalThresholdLkr` | Decimal | `4500.00` | Max automatic refund amount (~$15 USD) before triggering human approval |

### 9.2 Agentic AI Subsystem (Python + LangGraph + FastAPI)
Configured via `agentic-ai/.env`:

| Variable | Type | Default / Example | Description |
|---|---|---|---|
| `LLM_PROVIDER` | String | `groq` (or `ollama`) | Active LLM backend provider |
| `GROQ_API_KEY` | String | `gsk_...` | API key for Groq Cloud API |
| `GROQ_MODEL` | String | `openai/gpt-oss-20b` | Default Groq model identifier |
| `AGENT_SERVICE_API_KEY` | String | *Shared secret* | Shared secret verified against `X-Agent-Service-Key` on internal calls |
| `OLLAMA_BASE_URL` | String | `http://localhost:11434` | Base URL for local Ollama service (used when `LLM_PROVIDER=ollama`) |
| `OLLAMA_MODEL` | String | `llama3.2:latest` | Local Ollama model tag |

### 9.3 Web Portal (React + Vite)
Configured via `web-react/.env` / `web-react/.env.local`:

| Variable | Type | Default / Example | Description |
|---|---|---|---|
| `VITE_API_BASE_URL` | String | `/api` | Base API URL (proxied through Vite dev server to backend port `5035`) |
| `VITE_CLOUDINARY_CLOUD_NAME` | String | `your-cloud-name` | Cloudinary cloud identifier for direct asset and photo uploads |
| `VITE_CLOUDINARY_API_KEY` | String | `123456789012345` | Cloudinary public API key |
| `VITE_CLOUDINARY_API_SECRET` | String | *Secret* | Cloudinary API secret |

### 9.4 Mobile App (Flutter)
Configured via `mobile-flutter/.env`:

| Variable | Type | Default / Example | Description |
|---|---|---|---|
| `API_URL` | String | `http://10.0.2.2:5035` | Backend API base URL (`10.0.2.2` for Android emulator; `localhost:5035` for web) |
| `CLOUDINARY_CLOUD_NAME` | String | `your-cloud-name` | Cloudinary cloud identifier for meter photo uploads |
| `CLOUDINARY_API_KEY` | String | `123456789012345` | Cloudinary public API key |
| `CLOUDINARY_API_SECRET` | String | *Secret* | Cloudinary API secret |

> **Security Note:** Never commit production `.env` or `appsettings.*.json` credential files to source control. Track only sanitized `.example` templates.

---

## 10. Testing

### 10.1 Test Execution Commands

| Module | Framework | Test Runner Command | Target Directory |
|---|---|---|---|
| **Backend Unit Tests** | xUnit + Moq + EF Core | `dotnet test tests/UnitTests/UnitTests.csproj` | `backend/` |
| **Backend Integration Tests** | xUnit + WebApplicationFactory | `dotnet test tests/IntegrationTests/IntegrationTests.csproj` | `backend/` |
| **Agentic AI Subsystem** | pytest + anyio | `python -m pytest -v` | `agentic-ai/` |
| **Web React Portal** | Vitest + React Testing Library | `npm test -- --run` | `web-react/` |
| **Mobile Flutter App** | flutter_test | `flutter test` | `mobile-flutter/` |

---

### 10.2 Comprehensive Test Breakdown by Module

#### A. ASP.NET Core Backend (179 Automated Tests)

##### Unit Test Suites (135 Tests)
| Test Suite File | Domain / Module | Focus & Scenarios Tested | Tests |
|---|---|---|---|
| `ReservationServiceTests.cs` | Reservations & Planning | Advance booking creation, concurrent slot locking, wallet pre-auth, walk-in admission, cancellation with penalty, waitlist auto-promotion, QR staff check-in, status lifecycle | 60+ |
| `ReservationTimezoneTests.cs` | Reservations | UTC and local timezone handling, ISO-8601 formatting, duration calculation | 5 |
| `ChargingPlansControllerTests.cs` | AI Charging Coordinator | Driver preference constraints, station filtering, distance checks, AI client dispatch, fallback handling | 8 |
| `StationServiceTests.cs` | Stations & Chargers | Station CRUD, charger configuration, tariff updates, weekly operating hours schedules, maintenance window overlaps, spatial proximity filtering | 16 |
| `ChargingSessionTests.cs` | Charging Sessions | Session initiation, energy meter readings, baseline vs override calculations, 15% discrepancy fraud flag, Cloudinary photo verification, stop session | 12 |
| `PaymentInvoiceTests.cs` | Payments & Invoices | Automatic invoice generation, energy charge computation, tariff application, wallet vs cash settlement | 8 |
| `WalletServiceTests.cs` | Wallets & Ledger | Virtual balance credit/debit, ledger transaction auditing, short-lived capability tickets, PayHere notification parsing, concurrency conflict retries | 10 |
| `MemberServiceTests.cs` | Memberships & Loyalty | Tier subscriptions, monthly fee deduction, loyalty points accrual, discount tiering, reward catalog redemption, admin review gate | 9 |
| `SupportServiceTests.cs` | Support Tickets | Ticket creation, message thread appending, status transitions, staff assignment, customer withdrawal | 7 |
| `SupportAnalysisTests.cs` | Support AI Analysis | Automated ticket sentiment categorization, root cause extraction, policy violation checks, refund proposal generation | 5 |
| `SupportWorkflowTests.cs` | Support HITL Workflows | Human-in-the-loop review execution, approval/rejection gates, refund threshold escalation (> $15 / 4500 LKR) | 6 |
| `SupportAgentClientTests.cs` | Agent Client | HTTP payload marshalling, `X-Agent-Service-Key` header authentication, graceful degradation on service timeout | 4 |
| `AuthServiceTests.cs` | Authentication | Driver and Station Owner registration, password validation, role assignment, login authentication, token refresh rotation, logout revocation | 8 |
| `BcryptPasswordHasherTests.cs` | Authentication | Cryptographic salt generation, BCrypt hash verification, tampering rejection | 3 |
| `JwtTokenGeneratorTests.cs` | Authentication | JWT claims embedding (`sub`, `name`, `email`, `role`), lifetime expiration verification | 3 |
| `UserServiceTests.cs` | User Management | Admin user creation, profile update, role changes, user deletion | 5 |
| `ResourceGuardTests.cs` | Authorization | Role-based authorization policies (`Admin`, `StationOwner`, `SupportManager`, `Driver`), multi-tenant access restrictions | 4 |
| `DbSeederTests.cs` | Persistence | Idempotent database initialization, default admin account creation, initial pricing tiers | 2 |

##### Integration Test Suites (44 Tests)
| Test Suite File | Endpoints Covered | Focus & Scenarios Tested | Tests |
|---|---|---|---|
| `AuthEndpointsTests.cs` | `/api/auth/*` | Complete HTTP registration, login, token refresh rotation, `/me` profile retrieval, logout | 6 |
| `UsersEndpointsTests.cs` | `/api/users/*` | Administrative user CRUD, role-based security barriers | 4 |
| `VehicleEndpointsTests.cs` | `/api/vehicles/*` | Driver vehicle listing, admin cross-tenant vehicle CRUD, compatible station queries | 5 |
| `StationEndpointsTests.cs` | `/api/stations/*` | Public search/nearby endpoints, station registration, charger CRUD, operating hours | 5 |
| `ReservationEndpointsTests.cs` | `/api/reservations/*` | Advance reservation booking, availability slot checks, QR token check-in, cancellation | 5 |
| `SessionEndpointsTests.cs` | `/api/sessions/*` | Session start, meter reading submission, photo verification upload, stop and invoicing | 4 |
| `WalletEndpointsTests.cs` | `/api/wallet/*` | Driver wallet overview, top-up initiation, ticket protection, PayHere IPN notification flow | 4 |
| `MembershipEndpointsTests.cs` | `/api/membership-plans`, `/api/subscriptions`, `/api/loyalty/*` | Membership subscription purchase, loyalty balance, reward catalog, redemption review | 5 |
| `SupportEndpointsTests.cs` | `/api/support-tickets/*` | Ticket creation, message thread exchanges, status updates, invoice validation | 4 |
| `WorkflowEndpointsTests.cs` | `/api/agent-workflows/*` | LangGraph workflow trigger, approval and rejection actions | 4 |
| `CurrentUserTests.cs` | Middleware | Token claims extraction, identity mapping, anonymous request rejection | 2 |
| `Student4HttpWorkflowTests.cs` | Multi-module E2E | End-to-end multi-step flow connecting session completion, meter override, invoice generation, ticket triage, and manager refund review | 2 |

---

#### B. Agentic AI Subsystem (25 Automated Tests)
Executed via `pytest` across all agent modules and LangGraph graphs:

| Test Suite File | Agent / Component | Focus & Scenarios Tested | Tests |
|---|---|---|---|
| `test_compatibility_agent.py` | Vehicle Compatibility Agent | Connector pinout matching (Type 2, CCS2, CHAdeMO, NACS, GB/T), charge rate capping, power bottleneck warning, batch station evaluation, FastAPI `/evaluate` and `/health` endpoints | 6 |
| `test_model_factory.py` | Model Factory & LLM Provider | Groq structured output binding, Ollama fallback, API key enforcement, unknown provider rejection | 4 |
| `test_planning_coordinator_agent.py` | Planning Coordinator Agent | Multi-agent LangGraph workflow execution, urgency-based human approval trigger, buffer conflict detection, budget vs speed ranking | 4 |
| `test_station_analysis_agent.py` | Station Analysis Agent | Real-time availability scoring, pricing tariffs, constraint flag generation, full station evaluation pipeline | 4 |
| `test_support_agent.py` | Validation & Support Agent | Prompt injection resilience, untrusted input containment, malformed output rejection, graceful provider failure | 3 |
| `test_support_workflow.py` | Multi-Agent Support Coordinator | Coordinator graph execution, bounded read-only tool delegation, multi-customer data isolation, structured failure responses | 4 |

---

#### C. Web React Portal (46 Automated Tests across 13 Suites)
Executed via `Vitest` and `React Testing Library`:

| Test Suite File | Feature / Component | Focus & Scenarios Tested | Tests |
|---|---|---|---|
| `useReservations.test.jsx` | Reservations Hook | Queries, mutations, cache invalidation, pending approval count queries | 9 |
| `ReservationDetailsModal.test.jsx` | Reservations Component | Modal display, reservation time slot editing, cancellation flow, deletion flow, meter photo display | 6 |
| `ReservationsPage.test.jsx` | Reservations Page | Tab navigation, filter controls, pending approvals banner, error state rendering | 6 |
| `StationsPage.test.jsx` | Stations Page | Station listing, filter controls, map view toggle, empty state presentation | 3 |
| `MyStationsPage.test.jsx` | Stations Page | Owner station list, status badges, quick actions (add charger, edit hours) | 3 |
| `PendingStationPage.test.jsx` | Admin Stations Page | Pending approval station queue, approval action, rejection dialog with mandatory reason | 3 |
| `StationComponents.test.jsx` | Stations Component | Header actions, summary metrics cards, search input interactions | 3 |
| `AddReservationModal.test.jsx` | Reservations Component | Time slot picker, charger selection, form validation, error message handling | 3 |
| `StationDetailPage.test.jsx` | Stations Page | Station information layout, charger listing tabs, operating hours overview | 2 |
| `StationCard.test.jsx` | Stations Component | Station card rendering, available charger chips, address display, navigation click | 2 |
| `RegisterStationPage.test.jsx` | Stations Page | Station creation form validation, coordinate inputs, submit action | 2 |
| `useStations.test.jsx` | Stations Hook | Stations query hook, single station query, cache invalidation | 2 |
| `ChargersTab.integration.test.jsx` | Stations Integration | Charger addition modal submission, dynamic charger list update | 2 |

---

#### D. Mobile Flutter App (23 Automated Tests across 7 Suites)
Executed via `flutter_test`:

| Test Suite File | Feature / Layer | Focus & Scenarios Tested | Tests |
|---|---|---|---|
| `support_workflow_test.dart` | Support & Invoices | Ticket creation, invoice validation retry, error containment, draft message preservation, offline retry | 8 |
| `planning_api_client_test.dart` | AI Planning Client | `PlanningRequest` JSON serialization, `PlanningResponse` deserialization, HTTP 200 parsing, HTTP 500 error propagation | 4 |
| `reservation_models_test.dart` | Reservation Models | `ReservationDto`, `CreateReservationRequest`, `WaitlistEntryDto` JSON parsing | 4 |
| `charger_test.dart` | Station Management | Charger model serialization, power rating presentation, status badges | 2 |
| `station_test.dart` | Station Management | Station model serialization, tariff display, distance format calculation | 2 |
| `widget_test.dart` | App Shell | App bootstrapping, role-based navigation bar rendering, home screen initialisation | 2 |
| `vehicle_registration_test.dart` | Vehicles Screen | Vehicle registration form validation, connector dropdown options, submission | 1 |

---

### 10.3 Test Suite Summary

| Subsystem | Framework | Test Suites | Total Tests | Status |
|---|---|---|---|---|
| **Backend API** | xUnit, Moq, WebApplicationFactory | 30 suites (18 unit + 12 integration) | **179** | Passing (1 skipped) |
| **Agentic AI** | pytest, anyio | 6 suites | **25** | Passing |
| **Web Portal** | Vitest, React Testing Library | 13 suites | **46** | Passing |
| **Mobile App** | flutter_test | 7 suites | **23** | Passing |
| **Entire Platform** | **Full-Stack Automated Test Suite** | **56 Suites** | **273 Tests** | **Automated CI Verified** |

---

## 11. Key API Endpoints

The ChargeSync platform exposes a unified, RESTful API surface across 15 controllers in the ASP.NET Core backend and an internal FastAPI AI agent service:

### 11.1 Authentication (`/api/auth`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | Anonymous | Register a new Driver or StationOwner account and return JWT session |
| `POST` | `/api/auth/login` | Anonymous | Authenticate with email & password, returning JWT access token and refresh token |
| `POST` | `/api/auth/google` | Anonymous | Authenticate with Google ID Token |
| `POST` | `/api/auth/refresh` | Anonymous | Exchange expired access token using refresh token (with automatic token rotation) |
| `POST` | `/api/auth/logout` | Authenticated | Revoke refresh token and invalidate current session |
| `GET` | `/api/auth/me` | Authenticated | Return the claims, roles, and profile carried by current bearer token |

### 11.2 User Administration (`/api/users`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/users` | Admin, StationOwner | List all registered user accounts with role filtering |
| `GET` | `/api/users/{id}` | Admin | Fetch user account details by ID |
| `POST` | `/api/users` | Admin | Create a new user account with any assigned role |
| `PUT` | `/api/users/{id}` | Admin | Update user details, email, or role |
| `DELETE` | `/api/users/{id}` | Admin | Delete a user account and associated credentials |

### 11.3 Vehicle Management (`/api/vehicles`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/vehicles` | Driver | List all vehicles owned by the currently authenticated driver |
| `GET` | `/api/vehicles/all` | Admin | System-wide view: list **all** registered vehicles across all drivers |
| `GET` | `/api/vehicles/user/{userId}` | Admin, StationOwner | Retrieve all vehicles owned by a specific user |
| `GET` | `/api/vehicles/{id}` | Driver (owner), Admin | Retrieve single vehicle details by ID |
| `POST` | `/api/vehicles` | Driver, Admin | Register a new EV (make, model, connector, battery capacity, charge rate) |
| `PUT` | `/api/vehicles/{id}` | Driver (owner), Admin | Update details of a vehicle owned by the driver |
| `PUT` | `/api/vehicles/admin/{id}` | Admin | Administrative override: update any vehicle regardless of owner |
| `DELETE` | `/api/vehicles/{id}` | Driver (owner), Admin | Delete own vehicle |
| `DELETE` | `/api/vehicles/admin/{id}` | Admin | Administrative override: delete any vehicle regardless of owner |
| `GET` | `/api/vehicles/{id}/compatible-stations` | Authenticated | Find nearby stations scored for hardware compatibility with this vehicle |

### 11.4 Station, Charger & Hours Management (`/api/stations`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/stations` | StationOwner, Admin | List stations owned by the authenticated owner |
| `GET` | `/api/stations/all` | Anonymous / All | Public listing of all approved, active charging stations |
| `GET` | `/api/stations/search` | Anonymous / All | Spatial and text search by GPS coordinates, radius km, connector type, and name query |
| `GET` | `/api/stations/nearby` | Anonymous / All | Proximity-based station discovery (alias for `/search`) |
| `GET` | `/api/stations/{id}` | StationOwner, Admin | Retrieve complete station details, chargers, and operating hours |
| `POST` | `/api/stations` | StationOwner, Admin | Register a new charging station (queued in `Pending` state for admin review) |
| `PUT` | `/api/stations/{id}` | StationOwner, Admin | Update station details, address, coordinates, and amenities |
| `POST` | `/api/stations/{id}/chargers` | StationOwner, Admin | Add a new EV charger to a station (connector, power rating, tariff, bay) |
| `PUT` | `/api/stations/{id}/chargers/{chargerId}` | StationOwner, Admin | Update charger technical specifications or tariff |
| `DELETE` | `/api/stations/{id}/chargers/{chargerId}` | StationOwner, Admin | Remove a charger from a station |
| `PUT` | `/api/stations/{id}/operating-hours` | StationOwner, Admin | Update weekly operating schedule (7-day open/close windows) |
| `POST` | `/api/stations/chargers/{chargerId}/maintenance` | StationOwner, Admin | Schedule a future charger maintenance downtime window |
| `PUT` | `/api/stations/maintenance/{maintenanceId}` | StationOwner, Admin | Update an existing scheduled maintenance window |
| `DELETE` | `/api/stations/maintenance/{maintenanceId}` | StationOwner, Admin | Delete a scheduled maintenance window |

### 11.5 Station Moderation (`/api/admin/stations`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/admin/stations/pending` | Admin | List all station registration requests awaiting verification |
| `GET` | `/api/admin/stations/{id}` | Admin | Review pending station details, documentation, and uploaded photos |
| `PUT` | `/api/admin/stations/{id}/approve` | Admin | Approve pending station registration and activate its chargers |
| `PUT` | `/api/admin/stations/{id}/reject` | Admin | Reject station registration with mandatory audit reason |

### 11.6 Reservations & Planning (`/api/reservations`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `POST` | `/api/reservations` | Driver | Create advance reservation with wallet balance pre-authorization |
| `POST` | `/api/reservations/admin` | StationOwner, Admin | Create advance reservation on behalf of a customer |
| `POST` | `/api/reservations/walk-in` | StationOwner, Admin | Admit an on-site walk-in driver without prior booking |
| `GET` | `/api/reservations` | Authenticated | List reservations with status, date, and charger filters (paged) |
| `GET` | `/api/reservations/availability` | Authenticated | Query real-time available time slots for a specific charger and date |
| `GET` | `/api/reservations/{id}` | Authenticated | Retrieve reservation details, QR token, and linked charging session with meter photo |
| `PUT` | `/api/reservations/{id}` | StationOwner, Admin | Update reservation details, slot times, or vehicle assignment |
| `PUT` | `/api/reservations/{id}/cancel` | Authenticated | Cancel reservation, release pre-auth, and promote next driver from waitlist |
| `POST` | `/api/reservations/{id}/approve` | StationOwner, Admin | Approve an AI-suggested or pending reservation request |
| `POST` | `/api/reservations/{id}/reject` | StationOwner, Admin | Reject a pending reservation request |
| `DELETE` | `/api/reservations/{id}` | StationOwner, Admin | Delete a cancelled or rejected reservation |
| `POST` | `/api/reservations/staff-checkin` | StationOwner, Admin | Staff check-in via scanning driver's dynamic QR token |
| `GET` | `/api/reservations/{id}/history` | Authenticated | Audit history trail of status changes for a reservation |

### 11.7 Charging Sessions (`/api/sessions`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `POST` | `/api/sessions/start` | StationOwner, Admin | Start charging session from an active, checked-in reservation |
| `GET` | `/api/sessions` | Authenticated | List charging sessions with filtering by status and station |
| `GET` | `/api/sessions/{id}` | Authenticated | Get session details, energy delivered, telemetry, and linked meter photo |
| `PUT` | `/api/sessions/{id}/stop` | StationOwner, Admin | Stop session, record energy delivered, submit physical meter reading override and Cloudinary photo evidence |

### 11.8 Invoicing & Billing (`/api/payments/invoices`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/payments/invoices` | Authenticated | Query invoices with status and date filters (Driver sees own; Admin sees all) |
| `GET` | `/api/payments/invoices/{userId}` | Authenticated | List all invoices for a specific driver |
| `POST` | `/api/payments/invoices/{id}/settle` | Authenticated | Settle invoice via wallet balance or on-site POS cash collection |

### 11.9 Virtual Wallet & PayHere Gateway (`/api/wallet`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/wallet` | Driver | Driver wallet overview: available balance, locked pre-auth credits, ledger history |
| `POST` | `/api/wallet/top-ups` | Driver | Initiate wallet top-up and generate short-lived encrypted checkout capability ticket |
| `GET` | `/api/wallet/payhere/checkout` | Anonymous (Ticket) | PayHere hosted checkout page rendered via single-use encrypted capability ticket |
| `POST` | `/api/wallet/payhere/notify` | Anonymous (PayHere) | Asynchronous Instant Payment Notification (IPN) webhook handler with signature validation |
| `GET` | `/api/wallet/payhere/return` | Anonymous | User return redirect landing page after PayHere checkout completion |
| `GET` | `/api/wallet/payhere/cancel` | Anonymous | User cancellation redirect landing page when checkout is abandoned |

### 11.10 Memberships & Subscriptions (`/api/membership-plans`, `/api/subscriptions`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/membership-plans` | Driver | List available membership tiers, monthly pricing, and charging discounts |
| `GET` | `/api/subscriptions` | Driver | List driver's current and past membership subscriptions |
| `POST` | `/api/subscriptions` | Driver | Subscribe to a membership tier with advance wallet payment |
| `PUT` | `/api/subscriptions/{id}/change` | Driver | Upgrade or switch active membership subscription plan |
| `DELETE` | `/api/subscriptions/{id}` | Driver | Cancel active recurring membership subscription |

### 11.11 Loyalty & Rewards Program (`/api/loyalty`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/loyalty/me` | Driver | Current driver loyalty points balance, tier status, and lifetime points earned |
| `GET` | `/api/loyalty/{userId}` | Admin, Driver (self) | View loyalty points balance for any driver |
| `GET` | `/api/loyalty/history` | Driver | Audit ledger of all loyalty points earned and redeemed |
| `GET` | `/api/loyalty/rewards` | Authenticated | Catalogue of redeemable rewards, coupons, and required points |
| `POST` | `/api/loyalty/redeem` | Driver | Redeem points for charging discount vouchers or benefits |
| `GET` | `/api/loyalty/redemptions` | Driver, Admin | List redemption requests (Drivers see own; Admin sees all) |
| `POST` | `/api/loyalty/redemptions/{id}/review` | Admin | Review and approve/reject high-value reward redemptions (> 5,000 pts / $50) |

### 11.12 Customer Support Tickets (`/api/support-tickets`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/support-tickets` | Driver, Support, Admin | List support tickets (Drivers see own; Staff see assigned or all) |
| `GET` | `/api/support-tickets/{id}` | Driver, Support, Admin | Get ticket details, conversation message thread, and linked invoice |
| `POST` | `/api/support-tickets` | Driver | Create a new customer support ticket |
| `POST` | `/api/support-tickets/{id}/messages` | Driver, Support, Admin | Post reply message to an existing ticket conversation thread |
| `PUT` | `/api/support-tickets/{id}/status` | SupportManager, Admin | Update ticket lifecycle status (`Open`, `InReview`, `Resolved`, `Closed`) |
| `PUT` | `/api/support-tickets/{id}/assignee` | SupportManager, Admin | Assign ticket to a customer support representative |
| `POST` | `/api/support-tickets/{id}/refund-review` | SupportManager, Admin | Review, approve, or reject proposed wallet refund |
| `DELETE` | `/api/support-tickets/{id}` | Driver | Withdraw / close ticket initiated by the driver |
| `POST` | `/api/support-tickets/{id}/analysis` | SupportManager, Admin | Trigger AI Support Agent sentiment analysis, root cause, and policy review |
| `GET` | `/api/support-tickets/invoices/{id}/validation` | SupportManager, Admin | Validate meter discrepancy and invoice charges for potential refund |

### 11.13 AI Charging Planner (`/api/charging-plan`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `POST` | `/api/charging-plan/generate` | Driver | Generate multi-agent ranked charging itinerary based on vehicle, arrival deadline, pricing, and distance |

### 11.14 Geographic Routing & Distance Matrix (`/api/routing`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `POST` | `/api/routing/matrix` | Driver | Compute multi-destination driving duration and distance matrix via OpenRouteService |
| `POST` | `/api/routing/directions` | Driver | Retrieve turn-by-turn route geometry and directions for in-app navigation |

### 11.15 Agent Workflows & Human-in-the-Loop Gating (`/api/agent-workflows`)
| Method | Path | Auth / Role | Description |
|---|---|---|---|
| `GET` | `/api/agent-workflows/{id}` | Authenticated | Retrieve workflow execution state, step progress, and human approval status |
| `GET` | `/api/agent-workflows/support-ticket/{ticketId}` | Authenticated | Retrieve workflow state associated with a specific support ticket |
| `POST` | `/api/agent-workflows/support-ticket/{ticketId}` | SupportManager, Admin | Launch autonomous LangGraph support workflow for a ticket |
| `POST` | `/api/agent-workflows/{id}/approve` | SupportManager, Admin | Human-in-the-loop: approve agent-proposed action/refund exceeding threshold |
| `POST` | `/api/agent-workflows/{id}/reject` | SupportManager, Admin | Human-in-the-loop: reject agent-proposed action |
| `POST` | `/api/agent-workflows/{id}/revise` | SupportManager, Admin | Human-in-the-loop: revise agent-proposed refund amount or notes before executing |

### 11.16 Internal Agentic AI Microservice (FastAPI — Port 8000)
Reachable internally by the ASP.NET Core backend; secured via constant-time `X-Agent-Service-Key` header verification:

| Method | Path | Target Agent | Description |
|---|---|---|---|
| `GET` | `/health` | Health Check | Service liveness, version, and loaded agents health check |
| `POST` | `/api/compatibility/evaluate` | Compatibility Agent | Single vehicle-charger hardware compatibility evaluation |
| `POST` | `/api/compatibility/batch-evaluate` | Compatibility Agent | Batch evaluation of multiple chargers against vehicle specs |
| `POST` | `/api/station-analysis/evaluate` | Station Analysis Agent | Real-time availability scoring, pricing tariffs, and constraint flags |
| `POST` | `/api/charging-plan/generate` | Planning Coordinator Agent | Multi-agent LangGraph coordinator generating ranked charging itineraries |
| `POST` | `/api/support/analyze` | Validation & Support Agent | Ticket classification, sentiment analysis, and refund recommendation |
| `POST` | `/api/workflows/support` | Multi-Agent Coordinator | End-to-end multi-agent autonomous support triage and resolution graph |

---

## 12. Deployment

| Component | Deployment |
|---|---|
| ASP.NET Core API | [live health URL] · [Swagger URL] |
| PostgreSQL | Hosted (migrations applied on deploy) |
| React Portal | [live URL] |
| Flutter App | Android APK — see `mobile-flutter/build/` or the release in the submission |
| Agentic AI service | Hosted internally, reachable only by the backend |

---

## 13. Architecture Decision Records

Key technical decisions are recorded individually in [`docs/ADR/`](docs/ADR/):

| ADR | Decision |
|---|---|
| ADR-01 | State management — Riverpod (Flutter) + TanStack Query (React) |
| ADR-02 | Agentic AI orchestration — LangGraph for multi-agent graph state |
| ADR-03 | Concurrency control — PostgreSQL GiST exclusion constraints + `SELECT ... FOR UPDATE` for zero double-bookings |
| ADR-04 | Hybrid session telemetry — dual-layer: auto-calculated baseline + staff physical meter override |
| ADR-05 | Internal ledger & POS cash management — no external payment gateway; virtual wallet + on-site cash collection |
| ADR-06 | Meter photo evidence storage — Cloudinary CDN for physical meter display photos, decoupling binary assets from PostgreSQL |

---

## 14. Team & Individual Contributions

| Student | Primary Component | Agent Owned |
|---|---|---|
| IT24103826 – Ranaweera K.R | Vehicle & AI Compatibility Discovery | Vehicle Compatibility Agent |
| IT24102953 – Yasara R.P.M | Station, Charger & Operating-Hours Management | Station Analysis Agent |
| IT24103921 – Samarawickrama N.A.N.D | Reservation & AI Charging Planning | Charging Recommendation & Planning Agent |
| IT24102295 - Sandaru P.H.B | Session, Payment, Loyalty & Support Management | Validation & Support Agent |

Individual contribution statements, Git/PR evidence, AI usage logs, and reflections are in [`docs/individual-reports/`](docs/individual-reports/).

---

## 15. License

Academic project developed for SE3090 – Software Engineering Frameworks, SLIIT. Not licensed for external commercial use.
