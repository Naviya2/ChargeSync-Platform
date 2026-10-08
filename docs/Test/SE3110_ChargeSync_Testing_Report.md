**Sri Lanka Institute of Information Technology**

![SLIIT logo](media/logo.png)

**SE3110 – Quality Management in Software Engineering**

Year 3, Semester 1 – 2026

**Assignment**

**Software Testing and Quality Evaluation of the SE3090 Integrated System**

Project: ChargeSync – EV Charging Reservation and Recommendation Platform

**Group: SE_034**

|                |                           |
|----------------|---------------------------|
| **Student ID** | **Student Name**          |
| IT24102295     | Sandaru P.H.B.            |
| IT24103921     | Samarawickrama N. A. N. D |
| IT24102953     | Yasara R.P.M              |
| IT24103826     | Ranaweera K.R.            |

**Submission Date: 08.10.2026**

## Table of Contents

*(See the Word version for the auto-generated table of contents.)*

---

# 1. Introduction

## 1.1 Purpose of the Report

ChargeSync is an intelligent electric vehicle (EV) charging reservation and recommendation platform developed as an integrated full-stack and Agentic AI application for the SE3090 module. This report presents the comprehensive testing and quality evaluation carried out on the implemented ChargeSync system as part of the SE3110 Quality Management in Software Engineering module.

The primary objective of this quality evaluation is to verify the correctness, reliability, component integration, non-functional performance, high availability, cross-browser compatibility, and application security across all system tiers using industry-standard testing tools and frameworks. Testing spans the ASP.NET Core backend APIs, local PostgreSQL relational database, React web portal, Flutter mobile application, and Python FastAPI / LangGraph Agentic AI services.

## 1.2 Report Structure

Sections 2 to 8 establish the system architecture, testing objectives, functional scope, test strategy, team responsibilities, execution environment, and master test schedule. Sections 9 to 17 present the concrete test executions and results across Functional, Unit, Database, Web, Mobile, Integration, AI, Performance, Security, Compatibility, and Availability testing, substantiated with tool-generated evidence. Sections 18 to 21 summarize execution metrics, defect logging, retesting verifications, and overall quality maturity. Sections 22 to 24 document engineering challenges, conclusions, and technical references. Finally, Section 25 provides supporting appendices, terminal re-run commands, and the CLEAR AI usage declaration.

## 1.3 Abbreviations

| **Term**       | **Meaning**                                                              |
|----------------|--------------------------------------------------------------------------|
| **API**        | Application Programming Interface                                        |
| **DAST**       | Dynamic Application Security Testing                                     |
| **E2E**        | End-to-End                                                               |
| **EV**         | Electric Vehicle                                                         |
| **GiST**       | Generalized Search Tree (PostgreSQL Indexing / Exclusion Constraint)      |
| **HA**         | High Availability                                                        |
| **JWT**        | JSON Web Token                                                           |
| **LKR**        | Sri Lankan Rupee                                                         |
| **MTBF**       | Mean Time Between Failures                                               |
| **MTTR**       | Mean Time To Recovery                                                    |
| **NFR**        | Non-Functional Requirement                                               |
| **p(95)**      | 95th Percentile Response Time                                            |
| **QR**         | Quick Response Code                                                      |
| **RPS**        | Requests Per Second (Throughput)                                         |
| **SLA**        | Service Level Agreement                                                  |
| **SRS**        | Software Requirements Specification                                      |
| **ZAP**        | OWASP Zed Attack Proxy                                                   |

---

# 2. System Overview

## 2.1 Project Description

ChargeSync is an end-to-end intelligent EV charging management platform designed to eliminate range anxiety, charging port incompatibilities, and queue congestion in Sri Lanka. The platform allows EV drivers to register vehicles, locate hardware-compatible charging stations, reserve dedicated charging slots with automated advance deposits, receive multi-agent AI charging itineraries, check in on-site using tamper-evident signed QR codes, complete physical charging sessions, settle invoices via digital wallets, and earn loyalty rewards. Station operators and administrators utilize an administrative console to oversee station infrastructure, charger bays, operating schedules, dispute resolutions, and analytics.

## 2.2 System Components

| **Component** | **Technology Stack**         | **Architectural Purpose**                                               |
|---------------|------------------------------|-------------------------------------------------------------------------|
| **Backend**   | ASP.NET Core (.NET 8/9)      | RESTful Web API, domain business logic, JWT auth, and EF Core ORM      |
| **Database**  | PostgreSQL (Local Test DB)   | Persistent ACID storage, relational constraints, and exclusion indexing |
| **Web**       | React 18 + Vite + Tailwind   | Operator & administrator management portal                             |
| **Mobile**    | Flutter 3.x (Dart)           | Driver mobile app and on-site station staff QR check-in terminal        |
| **AI**        | Python 3.11 + FastAPI + LangGraph | Agentic AI multi-agent recommendation, routing, and support triage |
| **Media**     | Cloudinary REST API          | Cloud storage for meter photos and staff audit evidence                 |
| **CI/CD**     | GitHub Actions               | Automated build, linting, and multi-tier testing workflows             |

## 2.3 Project Functions

| **Function**   | **Functional Domain**                          | **Subsystem Responsibilities**                                          |
|----------------|------------------------------------------------|-------------------------------------------------------------------------|
| **Function 1** | Vehicle & AI Compatibility Discovery           | Vehicle registry, connector matching, and compatibility scoring       |
| **Function 2** | Station, Charger & Operating-Hours Management  | Station onboarding, bay topology, operating hours, and maintenance      |
| **Function 3** | Reservation & AI Charging Planning             | Slot scheduling, buffer enforcement, GiST locking, and AI routing       |
| **Function 4** | Session, Payment, Loyalty & Support Management | Charging sessions, wallet top-ups, invoicing, rewards, and support      |

## 2.4 High-Level Architecture

The ChargeSync architecture implements a distributed microservice and client-server topology. Flutter mobile clients and the React web portal communicate with the ASP.NET Core Web API over HTTPS. All persistent application state is committed to a local PostgreSQL database (`ChargeSync-Test`) utilizing Entity Framework Core. AI-assisted operations are dispatched via secure HTTP requests (`X-Agent-Service-Key`) to the Python FastAPI microservice powered by LangGraph.

![Architecture diagram](media/architecture.png)

*Figure 1: ChargeSync high-level system architecture*

## 2.5 Key Workflows and Quality Risks

| **Key Workflow / Feature**                                  | **Identified Quality Risk**                                       | **Risk Level** | **Mitigated In**        |
|-------------------------------------------------------------|-------------------------------------------------------------------|----------------|-------------------------|
| Authentication & Role-Based Access (Driver, Owner, Admin)   | Privilege escalation, token forgery, unauthorized API invocation  | High           | Sections 10, 17.2       |
| Reservation Slot Booking & Time Window Slicing              | Double-booking race conditions, buffer breaches, maintenance clash | High           | Sections 9.3, 11, 17.7  |
| Charging Session Settlement & Wallet Invoicing              | Financial discrepancies, negative balances, duplicate debits       | High           | Sections 9.4, 11, 14    |
| Agentic AI Route Planning & Support Triage                  | Hallucinated itineraries, prompt injections, unauthorized refunds | High           | Sections 15, 17.2       |
| Station & Charger Bay Infrastructure Management             | Orphaned bays, inconsistent operating hours, foreign key drift    | Medium         | Sections 9.2, 11        |
| Cross-Browser & Multi-Viewport Client Reflow                | UI clipping, horizontal scrollbars, unclickable mobile drawers    | Medium         | Section 17.6            |
| High Availability & Network Fault Recovery                  | System lockup under burst traffic, unhandled client white-screens | Medium         | Section 17.7            |

---

# 3. Testing Objectives

The primary quality assurance objectives for the ChargeSync evaluation were:

1. **Verify Functional Compliance:** Ensure all functional requirements across Functions 1 through 4 conform strictly to the SRS specifications.
2. **Validate Backend API Integrity:** Validate request validation, business logic, authorization filters, and HTTP status codes using automated unit and integration tests.
3. **Ensure Database Consistency:** Verify relational schemas, unique constraints, foreign keys, and PostgreSQL exclusion indexes using automated SQL suites.
4. **Evaluate Cross-Platform Frontends:** Verify React component lifecycles and Flutter widget workflows with dedicated UI testing harnesses.
5. **Demonstrate End-to-End Integration:** Validate complete multi-tier transactions spanning mobile, API, AI, web, and local database services.
6. **Benchmark Performance & Scalability:** Establish response-time baselines, throughput, and latency percentiles under simulated concurrent user traffic.
7. **Verify Application Security:** Identify and mitigate OWASP Top 10 vulnerabilities, enforce input sanitization, and confirm role-based boundaries.
8. **Demonstrate Cross-Browser Compatibility:** Validate UI rendering and responsive layout integrity across Chromium, Gecko, and WebKit on desktop, tablet, and mobile viewports.
9. **Validate High Availability & Slot Calculations:** Verify 99.9% uptime, sub-second MTTR, database connection pool resilience, and slot availability algorithm correctness.
10. **Track Defects & Confirm Fixes:** Formally log all discovered anomalies and prove remediation through regression testing.

---

# 4. Testing Scope

## 4.1 In Scope

| **Testing Area**            | **Evaluated System Scope**                                                     | **Applied Frameworks & Tools**                   |
|-----------------------------|--------------------------------------------------------------------------------|---------------------------------------------------|
| **Backend API & Unit**      | Controllers, services, domain models, role filters, JWT validation             | xUnit, Moq, WebApplicationFactory, Postman        |
| **Database Testing**        | Schemas, relational keys, unique constraints, wallet rules, exclusion indices | PostgreSQL 16/18, Automated SQL Harness (psql)     |
| **Web Portal Testing**      | Component rendering, form validation, route guards, dark mode, responsive grid | Vitest, React Testing Library, MSW                |
| **Mobile App Testing**      | Models, screen widgets, QR display, validation logic, API clients              | flutter_test, mocktail                            |
| **System Integration (E2E)**| Full lifecycle from driver registration to charging, payment, and rewards      | Flutter, ASP.NET Core, Python AI, React, Postman  |
| **Agentic AI Evaluation**   | Tool invocation, schema validation, prompt injection immunity, policy checks   | pytest, FastAPI test client                       |
| **Performance Testing**     | API response times, latency distribution, concurrency throughput               | k6, HTTP load harnesses                           |
| **Security & DAST Testing** | Token tampering, IDOR, SQL injection, XSS, OWASP Top 10 header inspection      | OWASP ZAP, Custom Security Probe, xUnit           |
| **Compatibility Testing**   | Multi-engine (Chromium, Firefox, WebKit) x Multi-viewport (Desktop/Tablet/Mob) | Playwright Multi-Engine Automation Harness        |
| **Availability Testing**    | 99.9% uptime, MTTR, connection pool burst, slot availability algorithm        | Synthetic Uptime Probes, Playwright Interception  |

## 4.2 Out of Scope / Known Limitations

- **Physical Hardware Interfacing:** Real OCPP hardware plugs, physical RFID readers, and high-voltage electrical chargers were simulated via software controllers.
- **Production Payment Gateways:** Live monetary transactions through the PayHere gateway were conducted in sandbox/mock mode; live banking integration was excluded.
- **Enterprise-Scale Multi-Region Stress:** Stress testing exceeding thousands of distributed virtual users was not performed due to local hardware testing boundaries.

---

# 5. Test Strategy and Approach

## 5.1 Test Levels and Techniques

| **Test Level**       | **Execution Strategy**                                                    | **Applied Testing Techniques**                        |
|----------------------|---------------------------------------------------------------------------|-------------------------------------------------------|
| **Unit Testing**     | Isolated logic verification with mocked dependencies                      | Equivalence partitioning, boundary value analysis     |
| **Integration**      | Multi-component API and database transaction evaluation                   | Positive, negative, and edge-case execution           |
| **System / E2E**     | End-to-end user journeys executed across frontend, API, AI, and database  | Real-world scenario simulation                        |
| **Non-Functional**   | Performance, Security, Compatibility, and Availability evaluation         | Threshold assertions, DAST scans, multi-browser tests |
| **Agentic AI**       | Deterministic assertion of LLM outputs against strict schemas and rules   | Schema validation, prompt injection penetration       |

## 5.2 Test Data Management

All automated testing was conducted against an isolated local PostgreSQL database (`ChargeSync-Test`) on `localhost:5432`. No traffic or persistent data was directed to the remote cloud Supabase environment during testing. Database seed scripts established clean baseline records prior to execution, guaranteeing test isolation, determinism, and reproducibility.

## 5.3 Entry and Exit Criteria

| **Entry Criteria**                                                | **Exit Criteria**                                               |
|-------------------------------------------------------------------|-----------------------------------------------------------------|
| All source modules build without compilation or packaging errors  | 100% of planned test scenarios executed and formally logged     |
| Local PostgreSQL `ChargeSync-Test` database initialized & healthy | Zero open Critical or High severity defects                     |
| ASP.NET Core backend and React/Vite development servers active    | All identified defects retested and verified as passed          |
| Multi-browser testing engines (Chrome, Firefox, WebKit) installed | Full visual and automated evidence generated and archived       |

## 5.4 Defect Severity Classification

| **Severity** | **Definition**                                                    | **Operational Example**                                |
|--------------|-------------------------------------------------------------------|--------------------------------------------------------|
| **Critical** | System crash, fatal data loss, or total privilege bypass          | Unauthenticated access to payment records              |
| **High**     | Core business workflow failure with no available workaround       | Double-booking of charger slot under concurrent load   |
| **Medium**   | Functional defect or rendering issue with an available workaround | Missing validation message or styling overflow         |
| **Low**      | Minor cosmetic defect, alignment anomaly, or phrasing typo        | Misaligned button padding on narrow viewport           |

---

# 6. Team Testing Responsibilities

| **Member**    | **Student ID / Name**                   | **Project Subsystem**              | **Primary Quality Responsibilities**                 |
|---------------|-----------------------------------------|------------------------------------|-------------------------------------------------------|
| **Student 1** | IT24102295 – Sandaru P.H.B.            | Vehicle & AI Compatibility         | Vehicle APIs, AI Compatibility tests, DAST Security   |
| **Student 2** | IT24103921 – Samarawickrama N. A. N. D | Station & Charger Management       | Station APIs, SQL Database suites, React Web testing  |
| **Student 3** | IT24102953 – Yasara R.P.M              | Reservation & AI Planning          | Reservation APIs, Compatibility & Availability suites |
| **Student 4** | IT24103826 – Ranaweera K.R.            | Session, Payment, Loyalty & Support| Payment APIs, k6 Performance, Flutter Mobile tests    |

---

# 7. Test Environment

| **Environmental Factor** | **Specification / Configuration**                                                |
|--------------------------|----------------------------------------------------------------------------------|
| **Operating System**     | Windows 11 Enterprise x64                                                       |
| **Backend Runtime**      | ASP.NET Core (.NET 8.0 / .NET 9.0 SDK)                                           |
| **Database Server**      | PostgreSQL 18 Local Server (`localhost:5432 / ChargeSync-Test`)                  |
| **Web Portal**           | React 18, Vite 8.2, Node.js v24.14.0                                             |
| **Mobile Framework**     | Flutter 3.24.x, Dart 3.5.x                                                       |
| **AI Subsystem**         | Python 3.11 / 3.12, FastAPI, LangGraph                                           |
| **Browser Engines**      | Google Chrome 154 (Chromium), Mozilla Firefox 157 (Gecko), Apple Safari 27 (WebKit)|
| **API & Load Tools**     | Postman, k6 v0.49+, Custom Asynchronous Performance Harness                      |
| **Security & DAST**      | OWASP ZAP 2.15+, Automated OWASP-Aligned Security Suite                          |
| **Compatibility Tool**   | Playwright v1.49.0 Multi-Engine Automation Harness                               |
| **Availability Tool**    | Synthetic High-Availability & Slot Calculation Probe Harness                     |
| **Source Control**       | GitHub: `https://github.com/Naviya2/ChargeSync-Platform` (Branch: `testing/nfr-testing`) |

---

# 8. Master Test Plan

## 8.1 Planned Testing Matrix

| **Test Area**        | **Evaluated Feature**          | **Type**        | **Framework / Tool**          | **Owner**     | **Target Outcome**          |
|----------------------|--------------------------------|-----------------|-------------------------------|---------------|-----------------------------|
| Backend API          | Vehicle CRUD & Compatibility   | Functional/Unit | xUnit, Moq, Postman           | Student 1     | 200 OK, valid DTOs          |
| Database             | Relational Schemas & Integrity | Integration     | PostgreSQL, SQL Test Runner   | Student 2     | Constraints enforce ACID    |
| Reservation          | Slot Booking & GiST Exclusion  | Integration     | Postman, xUnit, WebAppFactory | Student 3     | Conflict-free booking       |
| Payment & Sessions   | Invoicing & Wallet Settlement  | Functional/API  | Postman, xUnit                | Student 4     | Accurate ledger debits      |
| Performance          | API Response Latency & Load    | Non-Functional  | k6, Async Load Harness        | Student 4     | p(95) < 800ms, 0% errors    |
| Security             | Auth, IDOR, SQLi, XSS, Headers | Security/DAST   | OWASP ZAP, Security Suite     | Student 1 & 2 | Zero High/Medium exploits   |
| Web Portal           | Console Components & Routes    | Component/E2E   | Vitest, React Testing Library | Student 2     | Clean render & navigation   |
| Mobile Application   | Driver Screens & QR Flow       | Unit/Widget     | flutter_test, mocktail        | Student 4     | 100% widget test pass       |
| Agentic AI           | Itinerary & Support Workflows  | AI Evaluation   | pytest, LangGraph             | Student 1 & 3 | Compliant structured JSON   |
| E2E Integration      | Full Driver-to-Reward Workflow | System E2E      | Full Stack Cross-Service      | All Members   | Complete lifecycle success  |
| Compatibility        | Cross-Browser & Multi-Viewport | Non-Functional  | Playwright (Chrome/FF/WebKit) | Student 2 & 3 | 100% pass across 9 matrices |
| Availability         | 99.9% Uptime & Slot Algorithm  | Non-Functional  | Synthetic Probe Suite         | Student 3 & 4 | Uptime >= 99.9%, MTTR < 1s  |

## 8.2 Test Schedule

| **Phase** | **Activity Description**                                     | **Timeframe**         |
|-----------|--------------------------------------------------------------|-----------------------|
| Phase 1   | Analyze SRS specifications, map quality risks, design plan   | 19 Sep – 22 Sep 2026  |
| Phase 2   | Author test cases, prepare database test fixtures and mocks  | 23 Sep – 26 Sep 2026  |
| Phase 3   | Execute unit, backend API, database, and frontend UI suites  | 27 Sep – 01 Oct 2026  |
| Phase 4   | Execute E2E workflows, AI evaluations, performance, security | 02 Oct – 05 Oct 2026  |
| Phase 5   | Execute Compatibility & Availability suites, defect logging  | 05 Oct – 07 Oct 2026  |
| Phase 6   | Verify defect retesting, finalize documentation & submission | 08 Oct 2026           |

---

# 9. Functional Testing

## 9.1 Function 1 – Vehicle & AI Compatibility Discovery

| **Test ID** | **Scenario Description**                                       | **Type**          | **Expected Result**                                | **Actual Result**                                   | **Status** |
|-------------|----------------------------------------------------------------|-------------------|----------------------------------------------------|-----------------------------------------------------|:----------:|
| F1-01       | Register electric vehicle with valid specifications            | Normal            | Vehicle record stored; HTTP 201 Created returned   | Vehicle created with UUID; HTTP 201 returned        | ✅ Pass    |
| F1-02       | Register vehicle with missing required parameters (e.g. Model) | Invalid           | Request rejected with HTTP 400 validation errors   | HTTP 400 ProblemDetails returned listing violations | ✅ Pass    |
| F1-03       | Update battery capacity and vehicle license plate              | Normal            | Changes persisted to PostgreSQL; HTTP 200 returned | Record updated with new capacity; HTTP 200 returned | ✅ Pass    |
| F1-04       | Delete vehicle associated with active charging reservations    | Normal/Boundary   | Deletion blocked due to relational integrity (FK)  | HTTP 409 Conflict returned; record preserved        | ✅ Pass    |
| F1-05       | Evaluate connector compatibility (CCS2 vs CHAdeMO)             | Normal / Negative | Matching returns 100%; mismatch returns 0% match   | Precise compatibility score and hardware tags output| ✅ Pass    |

## 9.2 Function 2 – Station, Charger & Operating-Hours Management

| **Test ID** | **Scenario Description**                        | **Type**      | **Expected Result**                               | **Actual Result**                                 | **Status** |
|-------------|-------------------------------------------------|---------------|---------------------------------------------------|---------------------------------------------------|:----------:|
| F2-01       | Create charging station with valid coordinates  | Normal        | Station persisted with Active status (HTTP 201)   | Station stored with location coordinates          | ✅ Pass    |
| F2-02       | Associate charger bay with non-existent station | Failure       | Foreign key constraint violation rejects insert   | HTTP 400/404 returned; database integrity intact  | ✅ Pass    |
| F2-03       | Set operating hours with CloseTime < OpenTime   | Boundary      | Validation rejects illogical schedule boundaries  | HTTP 400 returned with schedule error message     | ✅ Pass    |
| F2-04       | Transition charger bay into Maintenance status  | Normal        | Charger status updated; excluded from future slots| Status set to Maintenance; booking slots disabled | ✅ Pass    |
| F2-05       | Driver role attempts to create charging station | Authorization | Request denied with HTTP 403 Forbidden            | HTTP 403 returned; role restriction enforced      | ✅ Pass    |

## 9.3 Function 3 – Reservation & AI Charging Planning

| **Test ID** | **Scenario Description**                           | **Type** | **Expected Result**                               | **Actual Result**                                 | **Status** |
|-------------|----------------------------------------------------|----------|---------------------------------------------------|---------------------------------------------------|:----------:|
| F3-01       | Reserve available charging slot with advance debit | Normal   | Booking created; advance fee debited from wallet  | HTTP 201 returned; QR code token generated        | ✅ Pass    |
| F3-02       | Concurrent booking of an already reserved slot     | Failure  | GiST exclusion constraint blocks double booking   | HTTP 400/409 Conflict returned; no duplicate slot | ✅ Pass    |
| F3-03       | Station staff validates valid signed QR code       | Normal   | Check-in accepted; status changed to CheckedIn    | QR signature verified; session authorized         | ✅ Pass    |
| F3-04       | Station staff scans expired or forged QR code      | Invalid  | Check-in rejected with authentication error       | HTTP 400 Bad Request; check-in denied             | ✅ Pass    |
| F3-05       | Driver requests booking during station closed hours| Edge     | Slot calculation returns zero available slots     | Empty slot array returned; booking disallowed     | ✅ Pass    |
| F3-06       | Multi-agent AI generates optimal charging plan     | Normal   | Valid ranked itinerary returned with SoC estimates| Structured JSON itinerary successfully created    | ✅ Pass    |

## 9.4 Function 4 – Session, Payment, Loyalty & Support Management

| **Test ID** | **Scenario Description**                           | **Type** | **Expected Result**                               | **Actual Result**                                 | **Status** |
|-------------|----------------------------------------------------|----------|---------------------------------------------------|---------------------------------------------------|:----------:|
| F4-01       | Initiate and complete active charging session      | Normal   | Energy meter recorded; invoice generated (HTTP 200)| Session finalized; kWh tariff computed accurately | ✅ Pass    |
| F4-02       | Settle completed invoice balance via wallet debit  | Normal   | Invoice marked Settled; wallet balance deducted   | Wallet balance decremented; invoice paid          | ✅ Pass    |
| F4-03       | Execute wallet top-up below minimum LKR 100 bound  | Boundary | Transaction rejected by validation rule           | HTTP 400 returned; balance unchanged              | ✅ Pass    |
| F4-04       | Submit duplicate payment request token (idempotency)| Failure  | Secondary request rejected; single debit executed | HTTP 409 returned; duplicate debit prevented      | ✅ Pass    |
| F4-05       | Credit loyalty rewards points upon invoice payment | Normal   | Driver loyalty account credited proportionally    | Points balance incremented by calculated tier     | ✅ Pass    |
| F4-06       | Dispatch customer support inquiry ticket           | Normal   | Ticket logged; AI support triage evaluates issue  | Ticket assigned ID; categorization output         | ✅ Pass    |

---

# 10. Backend API and Unit Testing

Backend automated testing was executed using **xUnit**, **Moq**, and **WebApplicationFactory**. The suite comprises **209 Unit Tests** (`backend/tests/UnitTests`) and **46 API Integration Tests** (`backend/tests/IntegrationTests`), achieving a 100% pass rate (255 passed out of 256 assertions, with 1 live cloud AI skip).

### 10.1 Backend Test Breakdown by Subsystem

| **Testing Dimension / Subsystem**   | **Target Modules & Features**                      | **Applied Framework**        | **Result Metric**    |
|-------------------------------------|----------------------------------------------------|------------------------------|:--------------------:|
| **Reservation Planning (Function 3)**| ReservationService, SlotCalculation, BufferRules | xUnit, Moq                   | 38 Passed / 0 Failed |
| **Station Management (Function 2)** | StationService, ChargerBays, OperatingHours        | xUnit, Moq                   | 35 Passed / 0 Failed |
| **Vehicle Compatibility (Function 1)**| VehicleService, ConnectorMatching, Scoring       | xUnit, Moq                   | 24 Passed / 0 Failed |
| **Payments & Wallets (Function 4)** | WalletService, InvoiceLedger, DepositRules         | xUnit, Moq                   | 42 Passed / 0 Failed |
| **Charging Sessions (Function 4)**  | SessionLifecycle, MeterReadings, QR Verification   | xUnit, Moq                   | 22 Passed / 0 Failed |
| **Memberships & Support Triage**    | LoyaltyTiers, SupportTickets, EscalationRules      | xUnit, Moq                   | 28 Passed / 0 Failed |
| **Auth, Users & Infrastructure**    | JwtTokenService, PasswordHasher, DbContext         | xUnit                        | 20 Passed / 0 Failed |
| **Backend Unit Tests Total**        | **UnitTests.csproj (14 Module Suites)**            | **xUnit Engine**             | **209 / 209 Passed** |
| **Backend Integration Tests Total** | **IntegrationTests.csproj (14 Endpoint Suites)**   | **WebApplicationFactory**    | **46 / 46 Passed**   |
| **Total Backend Automated Tests**   | **Complete ASP.NET Core Test Harness**             | **dotnet test**              | **255 / 255 Passed** |

*Figure 2: Backend unit and API integration test output (dotnet test)*

---

# 11. Database Testing

Automated database testing was executed against the local PostgreSQL test database (`ChargeSync-Test`) across six dedicated SQL test suites utilizing `psql`.

![Database test results](media/database_tests.jpg)

*Figure 3: PostgreSQL test suite execution (6 SQL suites passed)*

1. **Suite 01 – Schema & Test Data:** Validated clean table re-creation, foreign key definitions, and verified initial seed counts across all 22 application tables.
2. **Suite 02 – Unique Constraints:** Verified that duplicate user emails, duplicated charger bay identifiers, and redundant payment IDs were rejected by unique index constraints.
3. **Suite 03 – Foreign Key Constraints:** Confirmed cascade and restrict behaviors; charger bays cannot reference non-existent stations, and drivers with active reservations cannot be deleted.
4. **Suite 04 – Workflow Integrity:** Verified that negative invoice amounts and invalid session enum statuses were rejected, confirming the `Reservation → ChargingSession → PaymentInvoice` relational integrity.
5. **Suite 05 – Wallet & Invoicing Rules:** Verified rejection of wallet top-ups below LKR 100, non-LKR currencies, and duplicate payment transaction IDs.
6. **Suite 06 – Indexes & Performance:** Verified that 12 required B-tree and composite indexes exist. Query plans confirmed index scans on high-traffic lookup paths (e.g., `(ChargerId, StartTime, EndTime)`).

---

# 12. React Web Application Testing

The React operator portal was tested using **Vitest** and **React Testing Library**. A total of **19 test files** comprising **70 automated component and integration tests** passed with zero failures in 9.19s, along with successful production bundle compilation (`vite build`).

### 12.1 Vitest Suite Execution Breakdown

| **Test Category / Layer**         | **Verified Test Files & Component Scope**                              | **Applied Tool** | **Result Metric**   |
|-----------------------------------|------------------------------------------------------------------------|------------------|:-------------------:|
| **Reservation Modal Components**  | `ReservationDetailsModal.test.jsx`, `AddReservationModal.test.jsx`     | Vitest, RTL      | 13 Passed / 0 Failed|
| **Station Components & Tabs**     | `StationCard.test.jsx`, `StationComponents.test.jsx`, `OperatingHours` | Vitest, RTL      | 8 Passed / 0 Failed |
| **Workspace & Dashboard Pages**   | `ReservationsPage.test.jsx`, `StationsPage.test.jsx`, `StationDetail`  | Vitest, RTL      | 14 Passed / 0 Failed|
| **Support & Operator Pages**      | `SupportInboxPage.test.jsx`, `SupportManagerDashboardPage.test.jsx`    | Vitest, RTL      | 8 Passed / 0 Failed |
| **Station Registration Pages**    | `PendingStationPage.test.jsx`, `MyStationsPage`, `RegisterStationPage` | Vitest, RTL      | 9 Passed / 0 Failed |
| **Integration & Motion Tests**    | `landing-motion.test.jsx`, `brand-loading`, `Chargers`, `Stations`     | Vitest, RTL, GSAP| 12 Passed / 0 Failed|
| **Custom React Data Hooks**       | `useReservations.test.jsx`, `useStations.test.jsx`                     | Vitest, Query    | 6 Passed / 0 Failed |
| **Total Web Portal Execution**    | **19 Test Files Across Components, Hooks & Pages**                     | **Vitest Run**   | **70 / 70 Passed**  |

*Figure 4: React test and build output (Vitest)*

---

# 13. Flutter Mobile Application Testing

The Flutter driver and station staff mobile application was evaluated using `flutter_test` and `mocktail`. Across unit and widget test suites, **68 automated tests** passed with zero failures in 11s (`flutter test`).

### 13.1 Flutter Test Suite Execution Breakdown

| **Test Category / Screen Scope**  | **Verified Test Suites & Features**                                    | **Applied Tool**       | **Result Metric**   |
|-----------------------------------|------------------------------------------------------------------------|------------------------|:-------------------:|
| **Charging Sessions & Checkout**  | `session_checkout_test.dart` (Meter readings, photo audits, S01–S07)   | flutter_test, mocktail | 10 Passed / 0 Failed|
| **Payments & Invoicing (P01–P03)**| Wallet debit settlement, insufficient fund alerts, cash receipts       | flutter_test           | 8 Passed / 0 Failed |
| **Customer Support Workflows**    | `support_workflow_test.dart` (Ticket submission, dispute retry, inbox) | flutter_test           | 12 Passed / 0 Failed|
| **Vehicle Registration & Forms**  | `vehicle_registration_test.dart` (Plate masks, battery capacity bounds)| flutter_test           | 8 Passed / 0 Failed |
| **Station Infrastructure & Maps** | `add_edit_station_screen_test.dart` (Form validation, coordinates)     | flutter_test           | 10 Passed / 0 Failed|
| **Reservation & Advance Charges** | `reservation_charge_dialog_test.dart` (Fee breakdown, slot booking)    | flutter_test           | 15 Passed / 0 Failed|
| **Mobile App Shell & Scaffolding**| `widget_test.dart` (App launch, Scaffold rendering, bottom nav)        | flutter_test           | 5 Passed / 0 Failed |
| **Total Mobile App Execution**    | **Complete Flutter Mobile Test Suite**                                 | **flutter test**       | **68 / 68 Passed**  |

*Figure 5: Flutter mobile test output (flutter test)*

---

# 14. Integration / End-to-End Testing

A complete business workflow was executed across the Flutter mobile app, ASP.NET Core API, Python AI microservice, React operator portal, and local PostgreSQL database.

| **Step** | **Workflow Action**                      | **Subsystems Involved**       | **Expected Result**             | **Status** |
|:--------:|------------------------------------------|-------------------------------|---------------------------------|:----------:|
| 1        | Driver registers and signs in            | Flutter Mobile, ASP.NET API   | Account created; JWT issued     | ✅ Pass    |
| 2        | Driver registers electric vehicle        | Flutter Mobile, API, Database | Vehicle persisted to PostgreSQL | ✅ Pass    |
| 3        | Driver searches compatible stations      | Flutter, API, Python AI       | Compatible stations returned    | ✅ Pass    |
| 4        | Driver reserves charging slot            | Flutter, API, Database        | Slot locked; advance fee deducted| ✅ Pass   |
| 5        | Driver checks in via signed QR code      | Flutter (Staff), API          | Signature validated; CheckedIn  | ✅ Pass    |
| 6        | Charging session initiates and completes | Staff App, API, Database      | Meter recorded; invoice produced| ✅ Pass    |
| 7        | Invoice settled via digital wallet debit | ASP.NET API, Database         | Wallet debited; invoice Settled | ✅ Pass    |
| 8        | Loyalty reward points credited to driver | ASP.NET API, Database         | Loyalty balance incremented     | ✅ Pass    |
| 9        | Station operator audits record on Web    | React Web Portal, API         | Real-time record displayed      | ✅ Pass    |

*Figure 6: End-to-end integration workflow execution evidence*

---

# 15. Agentic AI Testing and Evaluation

The Python FastAPI and LangGraph multi-agent subsystem was evaluated using **pytest** across **30 deterministic automated test scenarios** (`agentic-ai/tests/`), achieving a 100% pass rate in 3.05s.

### 15.1 Multi-Agent AI Test Execution Breakdown

| **Test Module File**                  | **Agent Subsystem & Evaluated Capabilities**                          | **Applied Framework** | **Result Metric**   |
|---------------------------------------|------------------------------------------------------------------------|-----------------------|:-------------------:|
| `test_compatibility_agent.py`         | Connector matching (CCS2, Type 2, CHAdeMO), hardware compatibility score| pytest, FastAPI Client| 6 Passed / 0 Failed |
| `test_planning_coordinator_agent.py`  | Multi-agent itinerary coordination, urgent approval, buffer conflicts  | pytest, LangGraph     | 6 Passed / 0 Failed |
| `test_model_factory.py`               | LLM provider factory, prompt injection guards, system prompts          | pytest                | 5 Passed / 0 Failed |
| `test_station_analysis_agent.py`      | Station queue pressure, bay congestion modeling, tariff adjustments    | pytest, LangGraph     | 4 Passed / 0 Failed |
| `test_support_agent.py`               | Customer sentiment analysis, refund policy boundary (LKR 5,000 threshold)| pytest             | 4 Passed / 0 Failed |
| `test_support_workflow.py`            | Graph state routing, human-in-the-loop review, escalation transitions  | pytest, LangGraph     | 4 Passed / 0 Failed |
| `test_config.py`                      | Pydantic Settings configuration, environment overrides, service keys   | pytest                | 1 Passed / 0 Failed |
| **Total Agentic AI Execution**        | **Complete Multi-Agent AI Subsystem Harness**                          | **pytest Runner**     | **30 / 30 Passed**  |

*Figure 7: Agentic AI evaluation output (pytest)*

---

# 16. Performance Testing

Performance testing evaluated API response times and latency distributions under concurrent load using **k6** and custom asynchronous probing against the local PostgreSQL backed API.

![k6 performance results](media/k6_performance.jpg)

*Figure 8: Performance testing baseline metrics*

| **Evaluated Endpoint**                | **Virtual Users (VUs)** | **Requests Completed** | **Avg Latency** | **p(95) Latency** | **Error Rate** |
|---------------------------------------|:-----------------------:|:----------------------:|:---------------:|:-----------------:|:--------------:|
| `GET /api/stations/all`               | 10 VUs                  | 250 requests           | 8.42 ms         | 18.20 ms          | 0.00%          |
| `GET /api/reservations/availability`  | 10 VUs                  | 250 requests           | 14.15 ms        | 29.50 ms          | 0.00%          |
| `POST /api/auth/login`                | 5 VUs                   | 100 requests           | 45.20 ms        | 82.10 ms          | 0.00%          |
| `GET /health`                         | 20 VUs                  | 500 requests           | 2.10 ms         | 4.80 ms           | 0.00%          |

---

# 17. Security, Compatibility & Availability Testing

## 17.1 Security Testing Objectives & DAST Tools

Security testing evaluated authentication barriers, authorization enforcement, injection vulnerability resistance, and OWASP Top 10 compliance using **OWASP ZAP** and an automated security probe harness.

## 17.2 Security Test Cases

| **Test ID** | **Security Scenario**                            | **Vulnerability Class**| **Expected Result**             | **Status** |
|-------------|--------------------------------------------------|------------------------|---------------------------------|:----------:|
| S-01        | Invocation of protected endpoint without JWT     | Broken Authentication  | HTTP 401 Unauthorized           | ✅ Pass    |
| S-02        | Invocation with tampered signature / expired JWT | Broken Authentication  | HTTP 401 Unauthorized           | ✅ Pass    |
| S-03        | Driver role attempts operator endpoint call      | Broken Access Control  | HTTP 403 Forbidden              | ✅ Pass    |
| S-04        | Driver reads another user's wallet / booking     | IDOR                   | Access denied; 403/404 returned | ✅ Pass    |
| S-05        | SQL injection payload in search & login inputs   | Injection (SQLi)       | Parameterized queries block SQLi| ✅ Pass    |
| S-06        | Cross-Site Scripting (XSS) payload in name field | Injection (XSS)        | Sanitized / HTML encoded        | ✅ Pass    |
| S-07        | LLM Prompt Injection via chat message payload    | AI Prompt Injection    | System instructions enforced    | ✅ Pass    |

## 17.3 OWASP ZAP Vulnerability Scan Summary

| **Vulnerability Risk Level** | **Alerts Identified** | **Remediated & Verified** | **Residual Risk** |
|------------------------------|:---------------------:|:-------------------------:|:-----------------:|
| **High**                     | 0                     | 0                         | 0                 |
| **Medium**                   | 2                     | 2 (Anti-CSRF & Rate Limit)| 0                 |
| **Low**                      | 3                     | 3 (Security Headers Added)| 0                 |
| **Informational**            | 4                     | 4 (Server Banner Cloaking)| 0                 |

## 17.4 Dependency Vulnerability Audits

- **Backend (.NET):** Executed `dotnet list package --vulnerable --include-transitive`. Result: 0 vulnerable packages identified.
- **Web Portal (React):** Executed `npm audit`. Identified dependencies remediated; zero high-severity vulnerabilities remaining.

## 17.5 Security Hardening and Defensive Remediation

To eliminate residual security vulnerabilities identified during DAST and static dependency reviews, the following defensive mitigations were integrated directly into the ASP.NET Core middleware and EF Core persistence layers:

1. **HTTP Security Header Enforcement:** Configured custom middleware to attach `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection: 1; mode=block`, and `Referrer-Policy: strict-origin-when-cross-origin` to every outbound HTTP response.
2. **Parameterized Data Access:** Guaranteed that 100% of database interactions leverage Entity Framework Core parameterized query generation, eliminating raw SQL concatenation and nullifying SQL injection attack vectors.
3. **Role-Based API Guard Filters:** Enforced strict `[Authorize(Roles = "...")]` policy guards across all controller routes to guarantee role boundary isolation between Drivers, Station Operators, and System Administrators.
4. **Tamper-Evident QR Token Cryptography:** Implemented HMAC-SHA256 digital signature validation on QR check-in tokens, rendering forged or expired check-in tokens immediately unparseable and unauthorized.
5. **Rate Limiting Protection:** Configured fixed-window rate-limiting on sensitive endpoints (`/api/auth/login`, `/api/auth/register`) to mitigate credential stuffing and denial-of-service brute-force attempts.

---

## 17.6 Cross-Browser & Multi-Viewport Compatibility Testing (Playwright)

Compatibility testing was executed using an automated **Playwright Multi-Engine Harness (`v1.49.0`)** evaluating three distinct browser engines across three responsive viewport form factors:

- **Browser Engines:** **Chromium** (Google Chrome 154), **Gecko** (Mozilla Firefox 157), **WebKit** (Apple Safari 27.2).
- **Viewports Tested:** **Desktop HD** (`1920x1080`), **Tablet** (iPad `768x1024`, Touch Emulation), **Mobile** (iPhone 14 `375x812`, Touch Emulation).
- **Views Tested:** Public Landing Page, Authentication Portal, Operator Dashboard, Stations Discovery, **Reservation Planning Workspace**, and Mobile Navigation Drawer.

### Compatibility Test Execution Matrix (51 Scenarios)

| Scenario ID Range | Browser Engine | Viewport Form Factor | Evaluated Views & Features | Pass Rate | Visual Artifacts |
|---|---|---|---|:---:|---|
| `COMP-*-CHROME-DESKTOP` | Chromium (Chrome) | Desktop HD (1920x1080) | Landing, Login, Dashboard, Stations, Reservations | 5 / 5 (100%) | `chrome_desktop_*.png` |
| `COMP-*-CHROME-TABLET`  | Chromium (Chrome) | Tablet iPad (768x1024) | Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `chrome_tablet_*.png` |
| `COMP-*-CHROME-MOBILE`  | Chromium (Chrome) | Mobile iPhone (375x812)| Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `chrome_mobile_*.png` |
| `COMP-*-FIREFOX-DESKTOP`| Mozilla Firefox   | Desktop HD (1920x1080) | Landing, Login, Dashboard, Stations, Reservations | 5 / 5 (100%) | `firefox_desktop_*.png`|
| `COMP-*-FIREFOX-TABLET` | Mozilla Firefox   | Tablet iPad (768x1024) | Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `firefox_tablet_*.png` |
| `COMP-*-FIREFOX-MOBILE` | Mozilla Firefox   | Mobile iPhone (375x812)| Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `firefox_mobile_*.png` |
| `COMP-*-WEBKIT-DESKTOP` | Apple Safari      | Desktop HD (1920x1080) | Landing, Login, Dashboard, Stations, Reservations | 5 / 5 (100%) | `webkit_desktop_*.png` |
| `COMP-*-WEBKIT-TABLET`  | Apple Safari      | Tablet iPad (768x1024) | Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `webkit_tablet_*.png`  |
| `COMP-*-WEBKIT-MOBILE`  | Apple Safari      | Mobile iPhone (375x812)| Landing, Login, Dashboard, Stations, Reservations, Drawer | 6 / 6 (100%) | `webkit_mobile_*.png`  |
| **Total Compatibility** | **All 3 Engines** | **All 3 Viewports**   | **Full Platform Coverage** | **51 / 51 (100%)** | **51 Screenshots Saved**|

### Key Compatibility Findings
1. **Zero Viewport Bleed:** Verified that `scrollWidth <= innerWidth + 2` held true across all viewports; no unintended horizontal scrollbars were induced.
2. **Component Reflow:** The **Reservation Planning Workspace** (`/reservations`) gracefully reflowed from a multi-column data table on desktop to stacked touch cards on iPhone 14.
3. **Mobile Drawer Navigation:** The off-canvas sidebar drawer toggled and retracted smoothly upon touch gestures across all engines.

*Figure 9: Cross-browser and multi-viewport rendering test matrix (Playwright)*

---

## 17.7 High Availability (HA) & Slot Availability Testing

High Availability and slot availability were evaluated through a multi-tier resilience harness verifying system uptime, latency percentiles, database connection pool limits, fault tolerance, and the **Reservation & Charging Planning** slot computation algorithm.

### Availability & SLA Metrics

| Performance & Availability Dimension | Measured Metric | Benchmark / SLA Target | Compliance Status |
|---|---|---|:---:|
| **Overall Service Availability (Uptime)** | **100.00%** | $\ge 99.9\%$ (Three Nines SLA) | ✅ **Compliant** |
| **Synthetic Probe Volume** | **120 Requests** | $\ge 100$ End-to-End Probes | ✅ **Compliant** |
| **Sustained Request Throughput** | **298.4 req/sec** | $\ge 30$ req/sec (Local Host) | ✅ **Compliant** |
| **Database Pool Concurrency** | **40 / 40 (100%)** | 0 Pool Exhaustion under Burst | ✅ **Compliant** |
| **Mean Time To Recovery (MTTR)** | **0.88 ms** | $\le 1000$ ms (Instant Recovery) | ✅ **Compliant** |
| **Median Latency (p50)** | **2.40 ms** | $\le 20$ ms | ✅ **Compliant** |
| **95th Percentile Latency (p95)** | **7.39 ms** | $\le 50$ ms | ✅ **Compliant** |
| **99th Tail Latency (p99)** | **8.54 ms** | $\le 100$ ms | ✅ **Compliant** |

### Domain Slot Availability Algorithm Validation
- **Operating Hours Reconciliation:** Evaluated Bay 1 (06:00 to 23:00); produced **65 valid 60-min slots** in 15-min increments with zero schedule boundary bleed.
- **Maintenance Window Exclusion:** Evaluated Bay 2 with an active scheduled maintenance window between 10:00 and 14:00; excluded 19 overlapping slots, returning **46 available slots with 0% maintenance overlap**.
- **Dynamic Duration Scaling:** Validated inverse scaling: 15m (68 slots) > 30m (67 slots) > 60m (65 slots) > 120m (61 slots).
- **Client-Side Graceful Degradation:** Simulated route failure on `/api/reservations`; React UI caught the error and rendered an interactive *"Failed to load reservations. Try again"* recovery card rather than crashing.

*Figure 10: High Availability and slot calculation resilience evaluation*

---

# 18. Test Execution Summary

| **Testing Area**                  | **Executed Test Volume** | **Passed** | **Failed** | **Pass Rate** |
|-----------------------------------|:------------------------:|:----------:|:----------:|:-------------:|
| **Backend Unit Tests**            | 209 Tests                | 209        | 0          | 100.0%        |
| **Backend Integration Tests**     | 46 Tests                 | 46         | 0          | 100.0%        |
| **Database SQL Test Suites**      | 6 Suites (28 Assertions) | 6          | 0          | 100.0%        |
| **React Web Portal Tests**        | 70 Vitest Tests (19 Files)| 70         | 0          | 100.0%        |
| **Flutter Mobile Tests**          | 68 Tests                 | 68         | 0          | 100.0%        |
| **Agentic AI Evaluations**        | 30 pytest Tests          | 30         | 0          | 100.0%        |
| **End-to-End Workflow Steps**     | 9 Integrated Steps       | 9          | 0          | 100.0%        |
| **Security & DAST Tests**         | 16 Automated Checks      | 16         | 0          | 100.0%        |
| **Compatibility Testing**         | 51 Engine/Viewport Matrix| 51         | 0          | 100.0%        |
| **High Availability Testing**     | 8 Multi-Tier Scenarios   | 8          | 0          | 100.0%        |
| **Total Test Assertions**         | **514+ Formal Checks**   | **514+**   | **0**      | **100.0%**    |

---

# 19. Defect Summary

| **Defect ID** | **Defect Description**                                         | **Component** | **Severity** | **Status** | **Retest** | **Fix Verification**                |
|:-------------:|----------------------------------------------------------------|:-------------:|:------------:|:----------:|:----------:|-------------------------------------|
| **DEF-001**   | Double-booking race condition under concurrent booking requests| API / Database| High         | Fixed      | ✅ Pass    | GiST exclusion constraint & row lock|
| **DEF-002**   | Missing `gsap` dependency causing landing page Vite crash      | Web Frontend  | Medium       | Fixed      | ✅ Pass    | Installed `gsap`; updated bundle cfg|
| **DEF-003**   | Station Status mismatch (`Approved` vs `Active`) in DB seed    | Database / API| Medium       | Fixed      | ✅ Pass    | Corrected enum seed in PostgreSQL   |
| **DEF-004**   | Missing security headers on ASP.NET Core response pipeline     | API Middleware| Low          | Fixed      | ✅ Pass    | Security header middleware appended |

### Defect Distribution by Severity

| **Severity** | **Identified** | **Resolved** | **Remaining Open** |
|--------------|:--------------:|:------------:|:------------------:|
| **Critical** | 0              | 0            | 0                  |
| **High**     | 1              | 1            | 0                  |
| **Medium**   | 2              | 2            | 0                  |
| **Low**      | 1              | 1            | 0                  |
| **Total**    | **4**          | **4**        | **0**              |

---

# 20. Defect Fixing and Retesting

| **Defect ID** | **Root Cause**                                                    | **Remediation Applied**                                          | **Retest ID**  | **Retest Result** |
|:-------------:|-------------------------------------------------------------------|------------------------------------------------------------------|:--------------:|:-----------------:|
| **DEF-001**   | Application-level `if` checks failed under concurrent requests    | Added PostgreSQL GiST exclusion constraint on charger time ranges| F3-02 / S-04   | ✅ Verified Pass  |
| **DEF-002**   | Animation library referenced in `useLandingAnimations.js` unbuilt | Installed `gsap` package and added `optimizeDeps` in Vite config | COMP-LAND-*    | ✅ Verified Pass  |
| **DEF-003**   | `StationStatus` enum lacked `Approved` value, aborting EF queries | Updated database seed script to assign valid `Active` status enum| AVAIL-ALGO-01  | ✅ Verified Pass  |
| **DEF-004**   | ASP.NET Core omitted `X-Content-Type-Options` and frame options   | Registered security header middleware in request pipeline        | S-06 / DAST    | ✅ Verified Pass  |

---

# 21. Overall Quality Evaluation

## 21.1 Strengths
- **Exhaustive Automated Test Coverage:** Over 514 verified assertions spanning unit, database, mobile, web, integration, performance, security, compatibility, and availability domains.
- **Robust Database Integrity:** PostgreSQL relational foreign keys, unique indexes, and GiST exclusion constraints eliminate race conditions and financial ledger discrepancies.
- **Cross-Browser & Responsive Excellence:** 100% compatibility across Chromium, Firefox, and WebKit on desktop, tablet, and mobile viewports with zero layout overflow.
- **High Availability & Instant Recovery:** Sustained 100% uptime under synthetic probing, 298.4 req/s throughput, and sub-millisecond MTTR (0.88 ms).

## 21.2 Limitations
- Physical charger hardware communication was validated via software emulation rather than production OCPP hardware.
- Payment transactions were evaluated against simulated sandbox environments rather than live banking clearinghouses.

## 21.3 Recommendations
- Integrate automated Playwright and OWASP ZAP test suites into the continuous integration (CI) pull request gate.
- Perform extended soak testing over a 24-hour continuous window prior to production launch.

---

# 22. Engineering Challenges

1. **Multi-Service Microservice Orchestration:** Coordinating state across Flutter, ASP.NET Core, Python LangGraph, and PostgreSQL required synchronized database fixtures and deterministic mock gateways.
2. **Concurrency Control in Slot Reservations:** Standard application-level locking proved vulnerable to race conditions under concurrent load; resolving this required PostgreSQL GiST exclusion constraints and transaction isolation.
3. **Multi-Engine Headless Browser Automation:** Configuring Playwright on Windows to control native Chrome, Firefox, and WebKit required managing engine installation paths, touch emulation flags, and asset compilation caches.
4. **Database Isolation Under Testing:** Ensuring that no test data polluted the remote Supabase environment required redirecting all connection strings and migration scripts strictly to the local `ChargeSync-Test` database.

---

# 23. Conclusion

The ChargeSync EV Charging Reservation and Recommendation Platform was thoroughly evaluated using functional, integration, performance, security, compatibility, and availability testing methodologies. All 514+ automated test checks passed, confirming that the system satisfies both functional specifications and non-functional quality standards. The platform demonstrates high availability (100% uptime), strong security (zero high-severity vulnerabilities), seamless cross-browser rendering (100% pass across Chrome, Firefox, and Safari), and resilient database transactional integrity.

---

# 24. References

1. xUnit.net, "xUnit.net Documentation," https://xunit.net/
2. Microsoft, "Integration Tests in ASP.NET Core," https://learn.microsoft.com/aspnet/core/test/integration-tests
3. Playwright, "Fast and Reliable End-to-End Testing," https://playwright.dev/
4. OWASP, "OWASP Top Ten Web Application Security Risks," https://owasp.org/www-project-top-ten/
5. OWASP ZAP, "Zed Attack Proxy Documentation," https://www.zaproxy.org/docs/
6. Grafana Labs, "k6 Load Testing Documentation," https://grafana.com/docs/k6/
7. Vitest, "Next Generation Testing Framework," https://vitest.dev/
8. Flutter, "Testing Flutter Applications," https://docs.flutter.dev/testing
9. PostgreSQL Global Development Group, "PostgreSQL Documentation," https://www.postgresql.org/docs/
10. ISTQB, "Standard Glossary of Terms used in Software Testing," https://glossary.istqb.org/

---

# 25. Appendices

## Appendix A – GitHub Repository and Source Locations

| **Item**                       | **Repository Details**                                                     |
|--------------------------------|----------------------------------------------------------------------------|
| **Repository URL**             | `https://github.com/Naviya2/ChargeSync-Platform` (Branch: `testing/nfr-testing`) |
| **Backend Tests Location**      | `backend/tests/UnitTests/`                                                 |
| **Database Tests Location**     | `database/tests/`                                                          |
| **Web Portal Tests Location**   | `web-react/tests/`                                                         |
| **Mobile Tests Location**       | `mobile-flutter/test/`                                                     |
| **AI Subsystem Tests Location** | `agentic-ai/tests/`                                                        |
| **Security Tests Location**     | `nfr-tests/security/`                                                      |
| **Compatibility Tests Location**| `nfr-tests/compatibility/`                                                 |
| **Availability Tests Location** | `nfr-tests/availability/`                                                  |

## Appendix B – Tool-Generated Evidence Artifacts

| **Testing Area**            | **Generated Report Artifact**                                       |
|-----------------------------|---------------------------------------------------------------------|
| **Compatibility Testing**   | `nfr-tests/compatibility/reports/compatibility_test_report.html`     |
|                             | `nfr-tests/compatibility/reports/compatibility_test_report.md`       |
|                             | `nfr-tests/compatibility/screenshots/` (51 Multi-Engine Captures)    |
| **Availability Testing**    | `nfr-tests/availability/reports/availability_test_report.html`        |
|                             | `nfr-tests/availability/reports/availability_test_report.md`         |
|                             | `nfr-tests/availability/screenshots/` (Resilience & Normal Captures)|
| **Security & DAST Testing** | `nfr-tests/security/reports/owasp_zap_security_report.html`          |
|                             | `nfr-tests/security/reports/owasp_zap_security_report.md`            |
| **Database SQL Testing**    | `database/tests/` (6 Passing SQL Test Suites)                       |

## Appendix C – Commands to Re-run All Automated Test Suites

```powershell
# 1. Run Backend Unit & Integration Tests (.NET)
dotnet test backend/tests/UnitTests/UnitTests.csproj

# 2. Run Database Integrity Test Suites (Local PostgreSQL)
python database/tests/run_database_tests.py

# 3. Run Web Portal Component Tests (Vitest)
cd web-react; npm run test; cd ..

# 4. Run Mobile App Tests (Flutter)
cd mobile-flutter; flutter test; cd ..

# 5. Run Python Agentic AI Evaluations (pytest)
pytest agentic-ai/tests/

# 6. Run Security & DAST Testing Suite
python nfr-tests/security/run_security_tests.py

# 7. Run Cross-Browser Compatibility Testing Suite (Playwright)
cd nfr-tests/compatibility; node run_compatibility_tests.mjs; cd ../..

# 8. Run High Availability & Slot Availability Testing Suite
cd nfr-tests/availability; node run_availability_tests.mjs; cd ../..
```

## Appendix D – Test Case Document and Defect / Bug Report Reference

The completed individual and group test case specifications, along with the detailed bug logs and before/after verification logs, are archived in `docs/Test/` and individual submission records.

## Appendix E – Individual Contribution Reports

Individual contribution reports for each of the four team members (Student 1, Student 2, Student 3, and Student 4) detailing personal test implementations and component ownership are submitted as separate individual contribution attachments.

## Appendix F – AI Usage Declaration (CLEAR Framework)

| **CLEAR Element**                                     | **Declaration**                                                                                                            |
|-------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| **Concept – What AI was used for**                    | Assisted in drafting test case matrices, designing synthetic availability probes, and authoring Playwright test scripts.   |
| **Logic – Prompts and tools applied**                 | Applied Google DeepMind Antigravity IDE agent to generate multi-engine Playwright harnesses and parse DAST security rules. |
| **Evidence – System verification**                    | Every generated test was executed against the live backend (`localhost:5035`) and local PostgreSQL database (`5432`).       |
| **Adaptation – Refinements made**                     | Fixed incorrect enum types, resolved `gsap` Vite import paths, customized operating hours, and calibrated latency limits. |
| **Reflection – Learning & insights**                  | Automated multi-browser and synthetic probe testing significantly accelerates verification of non-functional SLAs.        |
