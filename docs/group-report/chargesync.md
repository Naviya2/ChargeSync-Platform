# ChargeSync
**Intelligent EV Charging Reservation and Recommendation Platform**  
**Software Requirements Specification**  
*SE3090 - Software Engineering Frameworks | Assignment 1*  
*BSc (Hons) in Information Technology, SLIIT - Year 3, Semester 1, 2026*  
*Document Version 2.0 (Hybrid Operational Model)*  

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) defines the functional and non-functional requirements for ChargeSync, an integrated full-stack and Agentic AI application developed for the SE3090 - Software Engineering Frameworks Assignment 1[cite: 1]. This version incorporates adaptations for markets characterized by varied smartphone digital literacy, lack of direct vehicle-to-charger IoT telemetry, and high prevalence of cash transactions through a hybrid driver/staff point-of-sale workflow.

### 1.2 Document Scope
This document covers the four core business components (Functions 1–4), their CRUD operations, complete relational database schema, external interface requirements, cross-component data flow, non-functional requirements, and the Agentic AI subsystem[cite: 1].

### 1.3 Definitions, Acronyms and Abbreviations
*   **SRS**: Software Requirements Specification[cite: 1]
*   **CRUD**: Create, Read, Update, Delete[cite: 1]
*   **API**: Application Programming Interface[cite: 1]
*   **REST**: Representational State Transfer[cite: 1]
*   **JWT**: JSON Web Token[cite: 1]
*   **FCM**: Firebase Cloud Messaging[cite: 1]
*   **ORM**: Object-Relational Mapping[cite: 1]
*   **ADR**: Architecture Decision Record[cite: 1]
*   **LLM**: Large Language Model[cite: 1]
*   **POS**: Point of Sale (Staff mobile and web operational workflow)
*   **UUID**: Universally Unique Identifier[cite: 1]
*   **3NF**: Third Normal Form[cite: 1]

### 1.4 Document Overview
Section 2 provides the overall product description and revised user roles[cite: 1]. Section 3 outlines detailed functional requirements and endpoints across all 4 functions[cite: 1]. Section 4 specifies the complete revised database schema[cite: 1]. Section 5 details interface requirements[cite: 1]. Section 6 defines system architecture and operational cross-function flows[cite: 1]. Section 7 presents non-functional requirements[cite: 1]. Section 8 details the Agentic AI subsystem[cite: 1]. Section 9 provides the revised Architecture Decision Records[cite: 1].

---

## 2. Overall Description

### 2.1 Product Perspective
ChargeSync is a self-contained system comprising a shared ASP.NET Core Web API and PostgreSQL database, a React web portal for station owners, platform administrators, and support staff, a Flutter mobile application serving both EV drivers and on-site station staff, and an internal Python/FastAPI/LangGraph Agentic AI service[cite: 1]. The Agentic AI service is reachable only via the ASP.NET Core backend[cite: 1].

### 2.2 Product Functions
*   Vehicle registration and AI-driven vehicle-charger compatibility calculation[cite: 1].
*   Station, charger, operating-hours, and maintenance-window administration[cite: 1].
*   Conflict-free reservation booking secured by advance virtual wallet payment, unique reservation QR token generation, staff-operated QR check-in, manual walk-in allocation, and AI charging planning[cite: 1].
*   Staff-monitored charging session lifecycle tracking, hybrid baseline energy calculation with staff physical meter override, automated invoice generation supporting cash and wallet settlement, membership subscriptions, loyalty tracking, and support ticket triage[cite: 1].
*   A four-agent Agentic AI subsystem with human-in-the-loop review triggers[cite: 1].

### 2.3 User Classes and Characteristics
*   **EV Driver**: Mobile app user[cite: 1]. Registers vehicles, requests AI charging plans, books slots via advance wallet payment, displays reservation QR codes, tracks charging history, and accesses loyalty rewards[cite: 1].
*   **Station Staff / Station Owner**: Operates the React portal for administrative station setup, pricing, and analytics[cite: 1]. Operates the Flutter mobile app on-site to scan driver booking QR codes, admit unregistered walk-in drivers, inspect physical charger meters, enter energy overrides, stop sessions, and log cash payments.
*   **Platform Administrator**: Full administrative access[cite: 1]. Approves stations, audits discrepancies between mathematical energy calculations and staff manual overrides, reviews AI-flagged actions, and manages user accounts[cite: 1].
*   **Customer Support Manager**: Manages support tickets, refund requests, and billing disputes[cite: 1].

### 2.4 Operating Environment
*   **Backend**: ASP.NET Core Web API (C#)[cite: 1].
*   **Database**: PostgreSQL with `btree_gist` extension for exclusion constraints[cite: 1].
*   **Web Client**: React Single Page Application (SPA)[cite: 1].
*   **Mobile Client**: Flutter application targeting Android (APK), providing dual role-based dashboards (Driver and Station Staff)[cite: 1].
*   **Agentic AI Service**: Python + FastAPI + LangGraph[cite: 1].

### 2.5 Design and Implementation Constraints
*   All client communications must route exclusively through the ASP.NET Core API[cite: 1].
*   The Agentic AI service must remain an internal service invoked solely by ASP.NET Core[cite: 1].
*   No external payment gateway integration; payments are managed via an internal wallet ledger and staff cash logs[cite: 1].
*   No IoT/hardware telemetry; session energy is derived via automated mathematical calculation and reconciled against manual staff meter input[cite: 1].

---

## 3. System Features

### 3.1 Function 1 - Vehicle & AI Compatibility Discovery (Student 1)
Allows drivers to register vehicles and obtain compatibility calculations prior to travel[cite: 1].

#### CRUD Operations
*   **Create**: Register vehicle (make, model, connector type, battery capacity, max charge rate)[cite: 1].
*   **Read**: View registered vehicles, search stations, view compatibility scores[cite: 1].
*   **Update**: Edit vehicle specifications[cite: 1].
*   **Delete**: Remove vehicle[cite: 1].

#### Functional Requirements
*   **FR-1.1**: Driver shall register a vehicle specifying make, model, connector type, battery capacity, and max charge rate[cite: 1].
*   **FR-1.2**: Driver shall view, update, and delete their own vehicles only[cite: 1].
*   **FR-1.3**: System shall compute a compatibility score and estimated charging time for a vehicle/charger pair[cite: 1].
*   **FR-1.4**: System shall suggest alternative stations if incompatibility is detected[cite: 1].
*   **FR-1.5**: Driver shall search nearby stations filtered by connector type and radius[cite: 1].

#### API Endpoints
*   `POST /api/vehicles` - Register vehicle[cite: 1]
*   `GET /api/vehicles` - List current driver's vehicles[cite: 1]
*   `GET /api/vehicles/{id}` - Retrieve vehicle details[cite: 1]
*   `PUT /api/vehicles/{id}` - Update vehicle[cite: 1]
*   `DELETE /api/vehicles/{id}` - Delete vehicle[cite: 1]
*   `GET /api/stations/nearby` - Search nearby stations[cite: 1]
*   `GET /api/stations/{id}/compatibility` - Get compatibility score[cite: 1]

---

### 3.2 Function 2 - Station, Charger & Operating-Hours Management (Student 2)
Allows station owners to manage physical infrastructure and monitor utilization[cite: 1].

#### CRUD Operations
*   **Create**: Register station, add charger, configure maintenance windows[cite: 1].
*   **Read**: View owned stations, charger statuses, operating hours, real-time availability, analytics[cite: 1].
*   **Update**: Update station info, charger rates, operating hours, operational state[cite: 1].
*   **Delete**: Remove charger or station (subject to no active bookings)[cite: 1].

#### Functional Requirements
*   **FR-2.1**: Station owner shall register a station with location and address[cite: 1].
*   **FR-2.2**: Station owner shall add, update, and remove chargers under their stations[cite: 1].
*   **FR-2.3**: Station owner shall configure weekly operating hours per day[cite: 1].
*   **FR-2.4**: Station owner shall schedule charger maintenance windows[cite: 1].
*   **FR-2.5**: System shall compute real-time availability by reconciling operating hours, maintenance windows, active reservations, and walk-in locks[cite: 1].
*   **FR-2.6**: System shall provide utilization and revenue analytics per station[cite: 1].

#### API Endpoints
*   `POST /api/stations` - Register station[cite: 1]
*   `GET /api/stations` - List and filter stations[cite: 1]
*   `GET /api/stations/{id}` - Retrieve station details[cite: 1]
*   `PUT /api/stations/{id}` - Update station[cite: 1]
*   `DELETE /api/stations/{id}` - Remove station[cite: 1]
*   `POST /api/stations/{id}/chargers` - Add charger[cite: 1]
*   `PUT /api/chargers/{id}` - Update charger specifications[cite: 1]
*   `PUT /api/chargers/{id}/status` - Update operational status[cite: 1]
*   `GET /api/stations/{id}/utilization` - Retrieve utilization analytics[cite: 1]

---

### 3.3 Function 3 - Reservation & AI Charging Planning (Student 3)
Coordinates AI-driven route and schedule recommendations, prevents double-booking, manages waitlists, generates advance reservation QR tokens, and provides staff-assisted check-ins and walk-in slot allocations[cite: 1].

#### CRUD Operations
*   **Create**: Create a reservation with advance payment; generate AI plan; admit walk-in customer; join waitlist[cite: 1].
*   **Read**: View reservations, generated QR code, waitlist position, status history[cite: 1].
*   **Update**: Modify reservation time window (subject to slot availability)[cite: 1].
*   **Delete**: Cancel reservation (triggers wallet refund policy and automated waitlist promotion)[cite: 1].

#### Functional Requirements
*   **FR-3.1**: Driver shall create a reservation for an available charger slot by submitting an advance deposit via their virtual wallet.
*   **FR-3.2**: System shall generate a cryptographically signed, unique `ReservationQRCode` token upon successful advance payment deduction.
*   **FR-3.3**: System shall prevent overlapping bookings using PostgreSQL GiST exclusion constraints and pessimistic row locking[cite: 1].
*   **FR-3.4**: Station Staff shall scan the driver's presented QR code via the Flutter mobile app to validate identity and execute check-in.
*   **FR-3.5**: Station Staff shall admit unregistered walk-in drivers by creating an on-demand reservation record with a null `DriverId`, locking the charger for immediate use.
*   **FR-3.6**: System shall maintain a waitlist per charger and automatically promote the next queue entry upon reservation cancellation[cite: 1].
*   **FR-3.7**: System shall generate an AI-ranked charging plan given driver constraints (deadline, distance, price preference)[cite: 1].
*   **FR-3.8**: System shall record a full status history for every reservation transition[cite: 1].

#### API Endpoints
*   `POST /api/reservations` - Create advance reservation with wallet pre-authorization[cite: 1]
*   `POST /api/reservations/walk-in` - Staff-initiated reservation and immediate lock for walk-ins
*   `GET /api/reservations` - List, filter, and paginate reservations[cite: 1]
*   `GET /api/reservations/{id}` - Retrieve reservation details and QR payload[cite: 1]
*   `PUT /api/reservations/{id}/cancel` - Cancel reservation[cite: 1]
*   `POST /api/reservations/staff-checkin` - Staff-scanned QR check-in endpoint
*   `POST /api/charging-plan/generate` - Generate AI charging plan[cite: 1]
*   `GET /api/reservations/{id}/history` - Retrieve reservation audit trail[cite: 1]

---

### 3.4 Function 4 - Session, Payment, Loyalty & Support Management (Student 4)
Handles session monitoring, hybrid mathematical-to-meter energy reconciliation, point-of-sale invoicing, cash/wallet tracking, loyalty programs, and support ticketing[cite: 1].

#### CRUD Operations
*   **Create**: Initiate charging session; issue invoice; create subscription; submit ticket; log points redemption[cite: 1].
*   **Read**: View active session status, historical invoices, staff override logs, loyalty balances, support tickets[cite: 1].
*   **Update**: Conclude charging session with physical meter input; change subscription plan; update ticket status[cite: 1].
*   **Delete**: Cancel subscription; withdraw pending support ticket[cite: 1].

#### Functional Requirements
*   **FR-4.1**: System shall record session start upon staff QR verification or walk-in admission[cite: 1].
*   **FR-4.2**: Station Staff shall conclude a charging session via mobile app when charging finishes or when the customer unplugs early.
*   **FR-4.3**: System shall calculate a baseline `AutoCalculatedKwh` using the formula: Charger Output (kW) × Duration (Hours)[cite: 1].
*   **FR-4.4**: Station Staff shall have the capability to input `StaffOverriddenKwh` read directly from the physical charger display to reflect non-linear charging tapers accurately.
*   **FR-4.5**: System shall compute the final invoice based on `StaffOverriddenKwh` (if present) or `AutoCalculatedKwh`, deducting pre-paid reservation deposits.
*   **FR-4.6**: System shall record settlement method as either "Wallet" or "Cash" (collected on-site by staff).
*   **FR-4.7**: System shall flag discrepancies exceeding 15% between auto-calculated and staff-overridden kWh for Platform Administrator fraud review.
*   **FR-4.8**: System shall track loyalty points for registered users and compute tier status[cite: 1].
*   **FR-4.9**: Driver shall redeem points for rewards subject to validation rules[cite: 1].
*   **FR-4.10**: System shall triage support tickets and mandate human-in-the-loop review on refund requests exceeding $15.00 or loyalty redemptions exceeding 5,000 points[cite: 1].

#### API Endpoints
*   `POST /api/sessions/start` - Record session initiation[cite: 1]
*   `PUT /api/sessions/{id}/stop` - Stop session and submit physical meter reading[cite: 1]
*   `GET /api/payments/invoices/{userId}` - Retrieve customer invoice ledger[cite: 1]
*   `POST /api/payments/invoices/{id}/settle` - Settle invoice via cash logging or wallet charge
*   `POST /api/subscriptions` - Enroll in membership tier[cite: 1]
*   `PUT /api/subscriptions/{id}/change` - Update membership tier[cite: 1]
*   `GET /api/loyalty/{userId}` - Fetch loyalty balance and tier[cite: 1]
*   `POST /api/loyalty/redeem` - Redeem loyalty points[cite: 1]
*   `POST /api/support-tickets` - Submit support ticket[cite: 1]
*   `PUT /api/support-tickets/{id}/status` - Update support ticket state[cite: 1]

---

## 4. Data Requirements (Database Design)

### 4.1 Entity Relationship Overview
The PostgreSQL database is organized in Third Normal Form (3NF)[cite: 1]. 
*   `Users` (1) to (N) `Vehicles`, `Stations` (as Owner), `Reservations`, `Subscriptions`, `SupportTickets`[cite: 1].
*   `Vehicles` (N) to (1) `ConnectorTypes`; `Vehicles` (1) to (1) `VehicleChargingProfiles`[cite: 1].
*   `Stations` (1) to (N) `Chargers`, `OperatingHours`[cite: 1].
*   `Chargers` (1) to (N) `MaintenanceWindows`, `Reservations`, `WaitlistEntries`[cite: 1].
*   `Reservations` (1) to (N) `ReservationStatusHistory`; `Reservations` (1) to (1) `ChargingSessions`[cite: 1].
*   `Reservations.DriverId` is nullable to facilitate unregistered walk-ins.
*   `ChargingSessions` (1) to (1) `PaymentInvoices`[cite: 1].
*   `Users` (1) to (1) `LoyaltyAccounts`; `LoyaltyAccounts` (1) to (N) `RewardRedemptions`[cite: 1].
*   `AgentWorkflowRuns` tracks multi-agent planning state and links to `ChargingPlans`[cite: 1].

---

### 4.2 Data Dictionary

#### Users (shared)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK, DEFAULT `gen_random_uuid()` | Unique user identifier[cite: 1] |
| `FullName` | VARCHAR(150) | NOT NULL | User's full name[cite: 1] |
| `Email` | VARCHAR(150) | NOT NULL, UNIQUE | User login email[cite: 1] |
| `PasswordHash` | VARCHAR(255) | NOT NULL | Bcrypt password hash[cite: 1] |
| `Role` | VARCHAR(30) | NOT NULL, CHECK IN ('Driver', 'StationOwner', 'StationStaff', 'Admin', 'SupportManager') | System role authorization |
| `PhoneNumber` | VARCHAR(20) | NULL | Contact phone number[cite: 1] |
| `WalletBalance` | DECIMAL(10,2)| NOT NULL, DEFAULT 0.00 | Internal prepaid wallet balance |
| `IsActive` | BOOLEAN | NOT NULL, DEFAULT TRUE | Status flag[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Record creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Record modification timestamp[cite: 1] |

#### ConnectorTypes (Function 1)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Connector standard identifier[cite: 1] |
| `Name` | VARCHAR(50) | NOT NULL, UNIQUE | Standard name (e.g., CCS2, Type 2)[cite: 1] |
| `Description` | TEXT | NULL | Standard technical specifications[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### Vehicles (Function 1)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique vehicle identifier[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Owning registered driver[cite: 1] |
| `Make` | VARCHAR(50) | NOT NULL | Vehicle manufacturer[cite: 1] |
| `Model` | VARCHAR(50) | NOT NULL | Vehicle model name[cite: 1] |
| `Year` | SMALLINT | NULL | Manufacturing year[cite: 1] |
| `ConnectorTypeId` | UUID | NOT NULL, FK -> ConnectorTypes(Id)| Hardware socket standard[cite: 1] |
| `BatteryCapacityKwh`| DECIMAL(6,2)| NOT NULL | Total battery storage[cite: 1] |
| `MaxChargeRateKw` | DECIMAL(6,2)| NOT NULL | Peak DC/AC charging intake[cite: 1] |
| `LicensePlate` | VARCHAR(20) | NULL | Registration license plate[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### VehicleChargingProfiles (Function 1)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Profile record identifier[cite: 1] |
| `VehicleId` | UUID | NOT NULL, UNIQUE, FK -> Vehicles(Id) | Linked vehicle record[cite: 1] |
| `OptimalChargeRateKw`| DECIMAL(6,2)| NULL | Recommended steady-state charge rate[cite: 1] |
| `PreferredConnectorTypeId` | UUID | NULL, FK -> ConnectorTypes(Id) | Preferred adapter standard[cite: 1] |
| `NotesJson` | JSONB | NULL | Manufacturer charging curve profiles[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### Stations (Function 2)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique station identifier[cite: 1] |
| `OwnerId` | UUID | NOT NULL, FK -> Users(Id) | Owning station operator[cite: 1] |
| `Name` | VARCHAR(150)| NOT NULL | Station commercial name[cite: 1] |
| `AddressLine` | VARCHAR(255)| NOT NULL | Physical road address[cite: 1] |
| `Latitude` | DECIMAL(9,6)| NOT NULL | Geospatial latitude[cite: 1] |
| `Longitude` | DECIMAL(9,6)| NOT NULL | Geospatial longitude[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Pending', CHECK IN ('Pending', 'Active', 'Suspended') | Operational status[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### Chargers (Function 2)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique charger unit identifier[cite: 1] |
| `StationId` | UUID | NOT NULL, FK -> Stations(Id) | Parent station facility[cite: 1] |
| `ConnectorTypeId` | UUID | NOT NULL, FK -> ConnectorTypes(Id)| Physical plug configuration[cite: 1] |
| `MaxOutputKw` | DECIMAL(6,2)| NOT NULL | Rated power capacity[cite: 1] |
| `PricePerKwh` | DECIMAL(6,2)| NOT NULL | Unit electricity price[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Available', CHECK IN ('Available', 'Occupied', 'Maintenance') | Operational state |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### OperatingHours (Function 2)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Schedule entry identifier[cite: 1] |
| `StationId` | UUID | NOT NULL, FK -> Stations(Id) | Station reference[cite: 1] |
| `DayOfWeek` | SMALLINT | NOT NULL, CHECK (DayOfWeek BETWEEN 0 AND 6) | Day index: 0 = Sunday, 6 = Saturday[cite: 1] |
| `OpenTime` | TIME | NOT NULL | Opening operational time[cite: 1] |
| `CloseTime` | TIME | NOT NULL | Closing operational time[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### MaintenanceWindows (Function 2)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Maintenance record identifier[cite: 1] |
| `ChargerId` | UUID | NOT NULL, FK -> Chargers(Id) | Targeted charger[cite: 1] |
| `StartTime` | TIMESTAMPTZ | NOT NULL | Scheduled start timestamp[cite: 1] |
| `EndTime` | TIMESTAMPTZ | NOT NULL | Scheduled conclusion timestamp[cite: 1] |
| `Reason` | TEXT | NULL | Maintenance explanation[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### Reservations (Function 3)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique reservation identifier[cite: 1] |
| `DriverId` | UUID | **NULL**, FK -> Users(Id) | Registered driver; **NULL indicates an on-site walk-in customer** |
| `ChargerId` | UUID | NOT NULL, FK -> Chargers(Id) | Targeted physical charger unit[cite: 1] |
| `VehicleId` | UUID | NULL, FK -> Vehicles(Id) | Registered vehicle profile (optional for walk-ins)[cite: 1] |
| `StartTime` | TIMESTAMPTZ | NOT NULL | Scheduled slot start[cite: 1] |
| `EndTime` | TIMESTAMPTZ | NOT NULL | Scheduled slot end[cite: 1] |
| `ReservationQRCode`| VARCHAR(255)| NULL, UNIQUE | Signed QR token for driver presentation and staff scanning |
| `AdvanceDepositAmount`| DECIMAL(8,2)| NOT NULL, DEFAULT 0.00 | Deposit deducted from wallet on booking |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Pending', CHECK IN ('Pending', 'Confirmed', 'CheckedIn', 'Cancelled', 'Completed') | Current lifecycle status |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

*Constraint*: Protected against double-booking via PostgreSQL exclusion constraint:  
`EXCLUDE USING gist (ChargerId WITH =, tsrange(StartTime, EndTime) WITH &&)`[cite: 1].

#### ReservationStatusHistory (Function 3)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | History record identifier[cite: 1] |
| `ReservationId` | UUID | NOT NULL, FK -> Reservations(Id) | Parent reservation[cite: 1] |
| `OldStatus` | VARCHAR(20) | NULL | Prior status[cite: 1] |
| `NewStatus` | VARCHAR(20) | NOT NULL | Transitioned status[cite: 1] |
| `ChangedByUserId`| UUID | NULL, FK -> Users(Id) | User or staff identity initiating transition[cite: 1] |
| `ChangedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Transition timestamp[cite: 1] |

#### WaitlistEntries (Function 3)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Waitlist entry identifier[cite: 1] |
| `ChargerId` | UUID | NOT NULL, FK -> Chargers(Id) | Desired charger unit[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Queued driver[cite: 1] |
| `RequestedStartTime` | TIMESTAMPTZ | NOT NULL | Requested start time[cite: 1] |
| `Priority` | INT | NOT NULL, DEFAULT 0 | Priority ranking[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Waiting', CHECK IN ('Waiting', 'Promoted', 'Expired') | Waitlist state[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### ChargingPlans (Function 3)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique plan identifier[cite: 1] |
| `WorkflowRunId` | UUID | NULL, FK -> AgentWorkflowRuns(WorkflowRunId) | Linked agent run[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Requesting driver[cite: 1] |
| `Deadline` | TIMESTAMPTZ | NOT NULL | Arrival deadline[cite: 1] |
| `MaxDistanceKm` | DECIMAL(6,2)| NULL | Maximum search radius[cite: 1] |
| `PricePreference` | VARCHAR(20) | NULL | Budget/speed sensitivity[cite: 1] |
| `PlanJson` | JSONB | NOT NULL | Ranked itinerary payload[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### ChargingSessions (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique session identifier[cite: 1] |
| `ReservationId` | UUID | NOT NULL, UNIQUE, FK -> Reservations(Id) | Originating reservation[cite: 1] |
| `StartTime` | TIMESTAMPTZ | NOT NULL | Physical session start (Staff QR check-in)[cite: 1] |
| `EndTime` | TIMESTAMPTZ | NULL | Physical session termination[cite: 1] |
| `AutoCalculatedKwh` | DECIMAL(8,2)| NULL | System calculated: Charger Output × Duration |
| `StaffOverriddenKwh`| DECIMAL(8,2)| NULL | Manual staff reading from physical charger screen |
| `FinalEnergyDeliveredKwh` | DECIMAL(8,2)| NULL | Billed energy value used for invoice settlement |
| `StaffUserId` | UUID | NULL, FK -> Users(Id) | Staff member supervising and closing session |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'InProgress', CHECK IN ('InProgress', 'Completed', 'DiscrepancyFlagged') | Session status |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### PaymentInvoices (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Unique invoice identifier[cite: 1] |
| `SessionId` | UUID | NOT NULL, UNIQUE, FK -> ChargingSessions(Id) | Originating session[cite: 1] |
| `DriverId` | UUID | **NULL**, FK -> Users(Id) | Billed driver (NULL for cash-paying walk-ins)[cite: 1] |
| `GrossAmount` | DECIMAL(10,2)| NOT NULL | Total cost based on energy consumption |
| `AdvanceDeducted` | DECIMAL(10,2)| NOT NULL, DEFAULT 0.00 | Deposit credited from booking |
| `NetAmountDue` | DECIMAL(10,2)| NOT NULL | Outstanding settlement balance |
| `PaymentMethod` | VARCHAR(20) | NOT NULL, CHECK IN ('Wallet', 'Cash') | Final payment method |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Pending', CHECK IN ('Pending', 'Paid', 'Refunded') | Invoice settlement status[cite: 1] |
| `IssuedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Issuance timestamp[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### MembershipPlans (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Plan tier identifier[cite: 1] |
| `Name` | VARCHAR(50) | NOT NULL | Plan name[cite: 1] |
| `Description` | TEXT | NULL | Plan privileges[cite: 1] |
| `MonthlyFee` | DECIMAL(8,2)| NOT NULL | Subscription price[cite: 1] |
| `DiscountPercentage`| DECIMAL(5,2)| NOT NULL, DEFAULT 0 | Per-session discount percentage[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### Subscriptions (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Subscription identifier[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Subscribed user[cite: 1] |
| `PlanId` | UUID | NOT NULL, FK -> MembershipPlans(Id) | Subscribed tier[cite: 1] |
| `StartDate` | DATE | NOT NULL | Enrollment start[cite: 1] |
| `EndDate` | DATE | NULL | Termination date[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Active', CHECK IN ('Active', 'Cancelled', 'Expired') | Subscription status[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### LoyaltyAccounts (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Loyalty account identifier[cite: 1] |
| `DriverId` | UUID | NOT NULL, UNIQUE, FK -> Users(Id) | Associated driver[cite: 1] |
| `PointsBalance` | INT | NOT NULL, DEFAULT 0 | Earned point balance[cite: 1] |
| `Tier` | VARCHAR(20) | NOT NULL, DEFAULT 'Bronze', CHECK IN ('Bronze', 'Silver', 'Gold') | Driver loyalty tier[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### RewardRedemptions (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Redemption record identifier[cite: 1] |
| `LoyaltyAccountId`| UUID | NOT NULL, FK -> LoyaltyAccounts(Id)| Redeeming account[cite: 1] |
| `PointsRedeemed` | INT | NOT NULL | Points debited[cite: 1] |
| `RewardDescription`| VARCHAR(255)| NOT NULL | Reward item summary[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Pending', CHECK IN ('Pending', 'Approved', 'Rejected') | Approval state[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### SupportTickets (Function 4)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `Id` | UUID | PK | Ticket identifier[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Submitting user[cite: 1] |
| `Category` | VARCHAR(50) | NOT NULL | Inquiry classification[cite: 1] |
| `Priority` | VARCHAR(20) | NOT NULL, DEFAULT 'Medium', CHECK IN ('Low', 'Medium', 'High', 'Urgent') | AI-triaged priority[cite: 1] |
| `Description` | TEXT | NOT NULL | Driver inquiry text[cite: 1] |
| `Status` | VARCHAR(20) | NOT NULL, DEFAULT 'Open', CHECK IN ('Open', 'InProgress', 'Resolved', 'Closed') | Operational status[cite: 1] |
| `AssignedToUserId`| UUID | NULL, FK -> Users(Id) | Assigned staff identifier[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Modification timestamp[cite: 1] |

#### AgentWorkflowRuns (shared, Agentic AI)[cite: 1]
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `WorkflowRunId` | UUID | PK, DEFAULT `gen_random_uuid()` | Execution workflow run identifier[cite: 1] |
| `DriverId` | UUID | NOT NULL, FK -> Users(Id) | Requesting driver[cite: 1] |
| `Objective` | TEXT | NOT NULL | Driver input prompt[cite: 1] |
| `Status` | VARCHAR(32) | NOT NULL | State: Running, PendingApproval, Completed, Failed[cite: 1] |
| `PlanJson` | JSONB | NULL | Generated structured itinerary[cite: 1] |
| `AgentOutputsJson`| JSONB | NULL | Diagnostic step outputs[cite: 1] |
| `ValidationResultJson` | JSONB | NULL | Validation agent report[cite: 1] |
| `RequiresApproval`| BOOLEAN | NOT NULL, DEFAULT FALSE | Human-in-the-loop gate trigger[cite: 1] |
| `ApprovalDecision`| VARCHAR(16) | NULL | Approved, Rejected, Revised[cite: 1] |
| `ApprovedByUserId`| UUID | NULL, FK -> Users(Id) | Reviewing staff/administrator[cite: 1] |
| `ApprovalNotes` | TEXT | NULL | Staff audit notes[cite: 1] |
| `FailureReason` | TEXT | NULL | Failure exception detail[cite: 1] |
| `RetryCount` | INT | NOT NULL, DEFAULT 0 | Recovery retry counter[cite: 1] |
| `CreatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT `clock_timestamp()` | Execution start timestamp[cite: 1] |
| `UpdatedAt` | TIMESTAMPTZ | NOT NULL, DEFAULT `clock_timestamp()` | Modification timestamp[cite: 1] |

---

## 5. External Interface Requirements

### 5.1 User Interfaces
*   **React Web Portal**: Role-based access for Station Owners, Platform Administrators, and Support Staff[cite: 1]. Provides station management, charger provisioning, real-time availability tracking, utilization analytics, manual staff override dispute monitoring, and AI approval queues[cite: 1].
*   **Flutter Mobile Application**:
    *   *Driver Mode*: Vehicle profiles, AI route planner, map discovery, advance wallet booking, reservation QR screen, session summaries, wallet reloads, and support tickets[cite: 1].
    *   *Staff Mode (POS)*: QR camera scanner for verifying reservations, one-tap walk-in charger lock, active session dashboard, stop-session trigger with physical meter kWh input, and cash collection logging.

### 5.2 API Interfaces
RESTful JSON over HTTPS secured via JWT bearer authentication[cite: 1]. Endpoints support role-based authorization ensuring drivers access only their data, staff access station-specific check-ins, and administrators access system-wide audit queues[cite: 1]. Swagger UI is enabled at `/swagger`[cite: 1].

### 5.3 Software Interfaces
*   **PostgreSQL**: Connected through Entity Framework Core with the Npgsql data provider[cite: 1].
*   **Agentic AI Service**: Internal Python/FastAPI service called exclusively by the ASP.NET Core `AgentClient`[cite: 1].

### 5.4 Third-Party Interfaces
*   **Google Maps API**: Distance calculation and station discovery[cite: 1].
*   **Firebase Cloud Messaging (FCM)**: Push notifications to mobile users regarding booking confirmations, slot reminders, and waitlist promotions[cite: 1].

---

## 6. System Architecture and Component Interconnections

### 6.1 High-Level Architecture
The system employs a client-server architecture[cite: 1]. Flutter (Driver/Staff) and React (Owner/Admin) communicate strictly with the ASP.NET Core Web API[cite: 1]. The API orchestrates business transactions with PostgreSQL and delegates AI workflows to the internal Python/LangGraph container[cite: 1].

### 6.2 Operational Workflows

#### Advance Reservation Flow
1.  **Driver**: Submits charging objective (time, vehicle, charger)[cite: 1].
2.  **ASP.NET Core**: Verifies slot availability, deducts advance deposit from driver's `WalletBalance`, inserts `Reservations` record with exclusion constraints, and generates signed `ReservationQRCode`[cite: 1].
3.  **On-Site Arrival**: Driver presents the QR code via mobile app.
4.  **Station Staff**: Scans QR code via Flutter app; system validates reservation, starts `ChargingSessions` record, and updates status to `CheckedIn`[cite: 1].

#### Unregistered Walk-In Flow
1.  **Driver**: Arrives on-site without an account or reservation.
2.  **Station Staff**: Checks physical availability. In the Flutter app, staff taps "Admit Walk-In" for that charger.
3.  **ASP.NET Core**: Inserts a `Reservations` record with `DriverId = NULL` to prevent online double-bookings[cite: 1], then immediately initiates a `ChargingSessions` record.

#### Session Termination & Settlement Flow
1.  **Vehicle Disconnect**: Driver requests check-out (e.g., stopping at 75% or 80% battery).
2.  **Station Staff**: Taps "Stop Session" in the app.
3.  **System**: Logs `EndTime` and calculates baseline `AutoCalculatedKwh` based on duration × output rate[cite: 1].
4.  **Staff Override**: Staff inputs `StaffOverriddenKwh` as displayed on the physical charger meter.
5.  **Billing**: System generates `PaymentInvoices` applying credit for any advance deposit[cite: 1].
6.  **Settlement**: Customer settles the net balance via virtual wallet or pays cash to staff; staff marks invoice as "Paid"[cite: 1]. Discrepancies > 15% between calculated and overridden kWh are logged for audit[cite: 1].

---

## 7. Non-Functional Requirements

### 7.1 Performance
*   Standard CRUD API endpoints shall respond within 500ms at the 95th percentile[cite: 1].
*   Agentic AI route planning executions shall complete within 10 seconds under standard conditions[cite: 1].

### 7.2 Security & Fraud Prevention
*   JWT bearer authentication across all mobile and web API requests[cite: 1].
*   Entity Framework Core parameterized queries to prevent SQL injection[cite: 1].
*   Passwords hashed using bcrypt[cite: 1].
*   **Staff Audit Trail**: Any manual override of energy consumption (`StaffOverriddenKwh`) must permanently record the `StaffUserId` alongside the `AutoCalculatedKwh` to trace cash fraud patterns.

### 7.3 Reliability and Availability
*   ACID transactions across all multi-step booking, session termination, and invoice settlement operations[cite: 1].
*   Third-party service degradations (Maps, FCM) must fail gracefully without blocking on-site physical charging[cite: 1].

---

## 8. Agentic AI Subsystem Requirements

### 8.1 Agent Overview
*   **Vehicle Compatibility Agent**: Assesses charger-to-vehicle hardware compatibility and calculates charging time[cite: 1].
*   **Station Analysis Agent**: Evaluates real-time charger status, historical pricing, and utilization scores[cite: 1].
*   **Charging Recommendation & Planning Agent (Coordinator)**: Synthesizes driver objectives, coordinates Compatibility and Station agents, and generates ranked itineraries[cite: 1]. Must handle records with null `DriverId` without failing availability models.
*   **Validation & Support Agent**: Inspects session records, checks business constraints, flags overrides, and handles support triage[cite: 1].

### 8.2 Human-in-the-Loop Approval Triggers
The following conditions halt agentic execution into a `PendingApproval` state requiring manual review in the React portal[cite: 1]:
*   **Refunds**: Any automated support triage recommending a wallet refund > $15.00[cite: 1].
*   **High-Value Loyalty Redemptions**: Point redemptions exceeding 5,000 points or $50.00 value[cite: 1].
*   **Waitlist Overrides**: AI planning itineraries attempting to prioritize a driver over an existing waitlisted booking[cite: 1].
*   **Meter Discrepancy Audits**: Physical staff overrides departing from calculated values by more than 15%.

---

## 9. Appendices

### 9.1 Summary of Architecture Decision Records
*   **ADR-01: State Management Frameworks**: Riverpod for Flutter and TanStack Query for React[cite: 1].
*   **ADR-02: Agentic AI Orchestration**: LangGraph selected for multi-agent graph state execution[cite: 1].
*   **ADR-03: Concurrency Control for Slot Allocation**: PostgreSQL GiST exclusion constraints combined with pessimistic row-level locking (`SELECT ... FOR UPDATE`) to guarantee zero double-bookings across online reservations and on-site walk-ins[cite: 1].
*   **ADR-04 (Revised): Hybrid Session Telemetry**: Replaces pure mathematical calculation with a dual-layer strategy. Baseline energy is mathematically computed from charger output and duration[cite: 1]; staff provides manual overrides from physical charger screens to reflect battery tapering without requiring live IoT telemetry.
*   **ADR-05 (Revised): Internal Ledger & POS Cash Management**: Eliminates external payment gateway dependencies[cite: 1]. Advance bookings utilize an internal virtual wallet ledger, while on-site walk-ins and post-charge balances support physical cash collection recorded directly by staff.