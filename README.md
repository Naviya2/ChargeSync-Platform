# ChargeSync
### Intelligent EV Charging Reservation and Recommendation Platform

---

## 1. Project Overview

**ChargeSync** connects EV drivers, charging station owners, platform administrators and customer support into one integrated system. Instead of drivers hunting for an available, compatible charger and hoping for the best, ChargeSync uses an **Agentic AI subsystem** to check vehicle-charger compatibility, analyze station data, and generate a ranked, multi-step charging plan tailored to the driver's objective (deadline, distance, price preference) — with a human approval gate on any action that overrides normal booking rules.

The system is built as one coherent full-stack application: a shared **ASP.NET Core Web API** and **PostgreSQL** database serve both a **React** admin/owner/support dashboard and a **Flutter** driver-facing mobile app, with a **Python + LangGraph** agent service handled entirely behind the API (never called directly by either client).

---

## 2. Problem Statement

As EV adoption grows, drivers struggle to find a station that is actually compatible with their vehicle, available at the right time, and worth the price — often arriving to find a charger occupied, incompatible, or under maintenance. Independent station owners lack a simple platform to list stations, manage chargers, and understand utilization. ChargeSync solves both sides with a shared platform and an AI layer that plans the best charging option for a driver's specific request.

---

## 3. User Roles

| Role | Responsibilities |
|---|---|
| **EV Driver** | Registers vehicles, searches/gets AI-recommended stations, reserves slots, checks in via QR, manages membership/loyalty/wallet, submits support tickets |
| **Station Owner** | Registers and manages their own stations/chargers, sets pricing and operating hours, monitors reservations and utilization |
| **Platform Administrator** | Approves station registrations, manages users/roles, approves high-impact AI-proposed actions, views platform-wide analytics and audit logs |
| **Customer Support Manager** | Handles support tickets, investigates reservation/session issues, coordinates with station owners |

---

## 4. Core Business Components

| # | Component | Owner | Summary |
|---|---|---|---|
| 1 | **Vehicle & AI Compatibility Discovery** | Student 1 | Vehicle registration, compatibility scoring, nearby station search |
| 2 | **Station, Charger & Operating-Hours Management** | Student 2 | Station/charger CRUD, automatic availability computation, utilization analytics |
| 3 | **Reservation & AI Charging Planning** | Student 3 | Conflict-free reservations, waitlist handling, QR check-in, AI-generated charging plans |
| 4 | **Membership, Loyalty & Support Management** | Student 4 | Subscription plans, loyalty points/tiers, reward redemption, support ticket triage |

Full endpoint lists, entities, and business-specific operations for each component are documented in [`docs/group-report/architecture.md`](docs/group-report/architecture.md).

---

## 5. Agentic AI Subsystem

Four distinct agents, orchestrated with **LangGraph**, share one underlying LLM but are differentiated by system prompt, allow-listed tools, and a defined input/output contract:

| Agent | Responsibility |
|---|---|
| **Vehicle Compatibility Agent** | Determines whether a vehicle can safely/efficiently use a given charger; suggests alternatives if not |
| **Station Analysis Agent** | Evaluates a station's availability, pricing and utilization; answers candidacy queries from the planner |
| **Charging Recommendation & Planning Agent** (coordinator) | Receives a driver's objective, builds a structured multi-step plan, delegates to the other agents, ranks final options |
| **Membership & Support Agent** | Recommends optimal membership plans, calculates loyalty tiers, triages support tickets, validates reward redemptions |

**High-impact action requiring human approval:** a plan that requires bumping another driver's reservation via the waitlist, a reward redemption above a configured threshold, or a plan change implying a refund — all pause in a `PendingApproval` state until a Station Owner or Platform Administrator approves, rejects, or requests revision via the React dashboard.

Full agent contracts, tool lists, and the minimum acceptance workflow are documented in [`docs/group-report/architecture.md`](docs/group-report/architecture.md).

---

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Backend | ASP.NET Core Web API (C#) |
| Database | PostgreSQL + Entity Framework Core |
| Web App | React (functional components, hooks, React Router) |
| Mobile App | Flutter (Dart) |
| Agentic AI | Python + LangGraph, served via FastAPI (internal service only) |
| LLM Provider | Ollama (local, development) → Groq / Gemini free-tier API (deployed) |
| Auth | JWT + role-based authorization |
| Third-Party Services | Google Maps API (station discovery), Firebase Cloud Messaging (push notifications) |
| CI/CD | GitHub Actions |

---

## 7. Repository Structure

```
ChargeSync/
├── backend/            # ASP.NET Core Web API
├── agentic-ai/         # Python + LangGraph agent service (internal only)
├── web-react/          # React admin/owner/support dashboard
├── mobile-flutter/      # Flutter driver-facing app
├── database/           # ER diagram, schema notes, seed data
├── docs/                # README, ADRs, group & individual reports
└── .github/workflows/   # CI pipeline
```

See [`docs/group-report/architecture.md`](docs/group-report/architecture.md) for the full folder breakdown per layer.

---

## 8. Getting Started

### Prerequisites
- .NET SDK 8+
- Node.js 18+
- Flutter SDK 3.x
- Python 3.11+
- PostgreSQL 15+
- Ollama (for local agent development) — https://ollama.ai

### 8.1 Backend (ASP.NET Core)
```bash
cd backend
cp appsettings.Example.json appsettings.Development.json   # fill in your local DB connection string
dotnet restore
dotnet ef database update      # applies migrations
dotnet run --project src/Api
```
API runs at `https://localhost:5001` — Swagger UI at `https://localhost:5001/swagger`.

### 8.2 Agentic AI Service (Python + LangGraph)
```bash
cd agentic-ai
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # set LLM_PROVIDER=ollama (default) or groq / gemini + API key
uvicorn api.main:app --reload --port 8000
```
Ensure Ollama is running locally (`ollama serve`) before starting the service if `LLM_PROVIDER=ollama`.

### 8.3 React Web App
```bash
cd web-react
cp .env.example .env         # set VITE_API_BASE_URL
npm install
npm run dev
```

### 8.4 Flutter Mobile App
```bash
cd mobile-flutter
flutter pub get
flutter run                   # or build an APK: flutter build apk --release
```
Update the API base URL in `lib/services/api_client.dart` (or via `--dart-define`) to point to your backend.

### Startup Order
1. PostgreSQL running and migrated
2. Agentic AI service (`agentic-ai`)
3. ASP.NET Core backend (`backend`) — depends on both the database and the agent service being reachable
4. React and/or Flutter clients

---

## 9. Environment Variables

| Variable | Used By | Description |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | Backend | PostgreSQL connection string |
| `Jwt__Secret` | Backend | JWT signing key |
| `AgentService__BaseUrl` | Backend | Internal URL of the agentic-ai service |
| `GoogleMaps__ApiKey` | Backend | Google Maps API key |
| `Firebase__ServerKey` | Backend | FCM server key for push notifications |
| `LLM_PROVIDER` | agentic-ai | `ollama` \| `groq` \| `gemini` |
| `GROQ_API_KEY` / `GEMINI_API_KEY` | agentic-ai | API key for the selected hosted provider |
| `VITE_API_BASE_URL` | web-react | Base URL of the deployed/local API |

Never commit real `.env` / `appsettings.Development.json` files — only the `.example` templates are tracked in Git.

---

## 10. Testing

| Layer | Command |
|---|---|
| Backend unit/integration | `dotnet test` (from `backend/`) |
| Agentic AI | `pytest` (from `agentic-ai/`) |
| React | `npm test` (from `web-react/`) |
| Flutter | `flutter test` (from `mobile-flutter/`) |

The end-to-end minimum acceptance workflow (objective → plan → validation → approval → status update) is covered by a golden-case test in `agentic-ai/tests/golden_cases/`. See `docs/group-report/testing-report.md` and `docs/group-report/agent-evaluation-report.md` for full evidence.

---

## 11. Deployment

| Component | Deployment |
|---|---|
| ASP.NET Core API | [live health URL] · [Swagger URL] |
| PostgreSQL | Hosted (migrations applied on deploy) |
| React | [live URL] |
| Flutter | Android APK — see `mobile-flutter/build/` or the release attached in the submission |
| Agentic AI service | Hosted internally, reachable only by the backend |

Full deployment steps and evidence are documented in `docs/group-report/deployment-report.md`.

---

## 12. Architecture Decision Records

Key technical decisions (state management, agent framework choice, workflow-state schema, deployment platform, third-party services, wallet/ledger design) are recorded individually in [`docs/ADR/`](docs/ADR/).

---

## 13. Team & Individual Contributions

| Student | Primary Component | Agent Owned |
|---|---|---|
| Student 1 | Vehicle & AI Compatibility Discovery | Vehicle Compatibility Agent |
| Student 2 | Station, Charger & Operating-Hours Management | Station Analysis Agent |
| Student 3 | Reservation & AI Charging Planning | Charging Recommendation & Planning Agent |
| Student 4 | Membership, Loyalty & Support Management | Membership & Support Agent |

Individual contribution statements, Git/PR evidence, AI usage logs and reflections are in [`docs/individual-reports/`](docs/individual-reports/).

---

## 14. AI Usage Declaration

This project was developed under **AI Use Level 4 (Full AI)** per the assignment specification — AI tools were used during development with full disclosure. See the consolidated group AI usage declaration in `docs/group-report/` and each student's individual AI usage log in `docs/individual-reports/`. No external AI assistance was used during the final demonstration or viva.

---

## 15. License

Academic project developed for SE3090 – Software Engineering Frameworks, SLIIT. Not licensed for external commercial use.
