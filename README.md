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

Full endpoint lists, entities, and business-specific operations for each component are documented in [`docs/group-report/chargesync.md`](docs\group-report\ChargeSync_SRS.pdf).

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
- An AI itinerary requires overriding a waitlisted booking
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
│   └── group-report/chargesync.md  # Full SRS (v2.0 Hybrid Operational Model)
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

| Variable | Used By | Description |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | Backend | PostgreSQL connection string |
| `Jwt__Secret` | Backend | JWT signing key (min. 32 chars) |
| `Jwt__Issuer` | Backend | JWT issuer claim |
| `AgentService__BaseUrl` | Backend | Internal URL of the agentic-ai service |
| `AgentService__ServiceKey` | Backend | Shared secret for agent API auth (`X-Agent-Service-Key`) |
| `Cloudinary__CloudName` | Backend | Cloudinary cloud name (meter photo uploads) |
| `Cloudinary__ApiKey` | Backend | Cloudinary API key |
| `Cloudinary__ApiSecret` | Backend | Cloudinary API secret |
| `GoogleMaps__ApiKey` | Backend | Google Maps API key |
| `Firebase__ServerKey` | Backend | FCM server key for push notifications |
| `LLM_PROVIDER` | agentic-ai | `groq` |
| `GROQ_API_KEY` | agentic-ai | API key for Groq hosted LLM |
| `AGENT_SERVICE_KEY` | agentic-ai | Shared secret validated on every request |
| `CLOUDINARY_API_KEY` | mobile-flutter | Cloudinary API key for meter/station photo uploads |
| `CLOUDINARY_API_SECRET` | mobile-flutter | Cloudinary API secret |
| `CLOUDINARY_CLOUD_NAME` | mobile-flutter | Cloudinary cloud name |
| `VITE_API_BASE_URL` | web-react | Base URL of the deployed/local API |

> **Never commit real `.env` / `appsettings.Development.json` files** — only `.example` templates are tracked in Git.

---

## 10. Testing

| Layer | Framework | Command |
|---|---|---|
| Backend unit tests | xUnit + Moq | `dotnet test` (from `backend/`) |
| Backend integration tests | xUnit + WebApplicationFactory | `dotnet test` (from `backend/`) |
| Agentic AI agents | pytest | `pytest` (from `agentic-ai/`) |
| React web portal | Vitest + React Testing Library | `npm test` (from `web-react/`) |
| Flutter mobile | flutter_test | `flutter test` (from `mobile-flutter/`) |

### Test Coverage Summary

| Component | Suite | Tests |
|---|---|---|
| `ReservationService` | Unit — xUnit | 158 tests (create, cancel, check-in, check-out, waitlist, auto-cancel, payment) |
| `PlanningCoordinatorAgent` | Unit — pytest | 24 tests |
| `CompatibilityAgent` | Unit — pytest | covered in `test_compatibility_agent.py` |
| `SupportAgent` | Integration — pytest | covered in `test_support_workflow.py` |
| `PlanningApiClient` | Unit — flutter_test | 4 tests (HTTP mock injection) |
| `SmartRecommendationCard` | Widget — flutter_test | 2 tests |
| `AiPlanningScreen` | Widget — flutter_test | 1 test |
| `ReservationDetailsModal` | Unit — Vitest | CRUD operation flows |

---

## 11. Key API Endpoints

### Vehicle Management (Admin)
| Method | Path | Role | Description |
|---|---|---|---|
| `GET` | `/api/vehicles` | Driver | List own vehicles |
| `GET` | `/api/vehicles/all` | Admin | List **all** vehicles system-wide |
| `PUT` | `/api/vehicles/admin/{id}` | Admin | Update any vehicle |
| `DELETE` | `/api/vehicles/admin/{id}` | Admin | Delete any vehicle |
| `GET` | `/api/vehicles/user/{userId}` | Admin, StationOwner | Vehicles by owner |

### Reservations & Sessions
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/reservations` | Create advance reservation with wallet pre-auth |
| `POST` | `/api/reservations/walk-in` | Staff-initiated walk-in admission |
| `GET` | `/api/reservations/{id}` | Retrieve reservation details, QR token, and linked session with meter photo |
| `POST` | `/api/reservations/staff-checkin` | Staff QR scan check-in |
| `PUT` | `/api/reservations/{id}/cancel` | Cancel + trigger waitlist promotion |
| `POST` | `/api/sessions/start` | Initiate charging session |
| `PUT` | `/api/sessions/{id}/stop` | Stop session + submit meter reading + Cloudinary photo |

### AI Charging Planner & Support Agent
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/charging-plan/generate` | Generate AI-ranked charging plan |
| `GET` | `/api/vehicles/{id}/compatible-stations` | Nearby compatible stations with scores |
| `POST` | `/api/support/analyze` | Support Agent ticket triage, categorization & refund review |
| `POST` | `/api/workflows/support` | Coordinator Agent multi-step support triage workflow |

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
