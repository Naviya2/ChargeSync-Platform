-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 01: Environment Cleanup & Core Entity Seeding
-- Target Database: ChargeSync-Test
-- ============================================================================

-- Clean existing data
TRUNCATE TABLE 
  "RewardRedemptions", "LoyaltyEntries", "LoyaltyAccounts", "Rewards",
  "Subscriptions", "MembershipPlans", "WalletTopUps",
  "AgentWorkflowRuns", "SupportMessages", "SupportTickets",
  "PaymentInvoices", "ChargingSessions", "ReservationStatusHistory", "Reservations",
  "Vehicles", "MaintenanceWindows", "OperatingHours", "Chargers", "Stations",
  "RefreshTokens", "Users" 
CASCADE;

-- 1. Insert Base Test Users (Admin, Station Owner, Driver)
INSERT INTO "Users" ("Id", "Email", "FullName", "PasswordHash", "Role", "IsActive", "CreatedAt", "UpdatedAt", "WalletBalance")
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'admin@chargesync.test', 'System Administrator', '$2a$11$DummyHashAdmin123456789012345678901234567890123456', 'Admin', true, NOW(), NOW(), 0.00),
  ('22222222-2222-2222-2222-222222222222', 'owner.colombo@chargesync.test', 'Colombo Hub Owner', '$2a$11$DummyHashOwner123456789012345678901234567890123456', 'StationOwner', true, NOW(), NOW(), 0.00),
  ('33333333-3333-3333-3333-333333333333', 'driver.nimal@chargesync.test', 'Nimal Perera (EV Driver)', '$2a$11$DummyHashDriver12345678901234567890123456789012345', 'Driver', true, NOW(), NOW(), 7500.00);

-- 2. Insert Test Station
INSERT INTO "Stations" ("Id", "OwnerId", "Name", "Address", "Latitude", "Longitude", "Status", "CreatedAt", "UpdatedAt")
VALUES 
  ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'Colombo City Center Supercharger', 'Sir James Pieris Mawatha, Colombo 02', 6.9186, 79.8561, 'Approved', NOW(), NOW());

-- 3. Insert Chargers (DC Fast Charger and AC Type 2)
INSERT INTO "Chargers" ("Id", "StationId", "Identifier", "BayLabel", "Connector", "PowerKw", "Tariff", "Status", "CreatedAt", "UpdatedAt")
VALUES 
  ('55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444444', 'BAY-01-DC60', 'Bay 1', 'CCS2', 60.00, 75.00, 'Available', NOW(), NOW()),
  ('55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444444', 'BAY-02-AC22', 'Bay 2', 'Type2', 22.00, 45.00, 'Available', NOW(), NOW());

-- 4. Insert Test Vehicle for Driver
INSERT INTO "Vehicles" ("Id", "OwnerId", "Make", "Model", "BatteryCapacityKwh", "LicensePlate", "Connector", "MaxChargeRateKw", "CreatedAt", "UpdatedAt")
VALUES 
  ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', 'Nissan', 'Leaf e+', 62.00, 'WP-CAA-1234', 'CCS2', 50.00, NOW(), NOW());

-- 5. Validation Check
DO $$
DECLARE
  v_users int;
  v_stations int;
  v_chargers int;
  v_vehicles int;
BEGIN
  SELECT COUNT(*) INTO v_users FROM "Users";
  SELECT COUNT(*) INTO v_stations FROM "Stations";
  SELECT COUNT(*) INTO v_chargers FROM "Chargers";
  SELECT COUNT(*) INTO v_vehicles FROM "Vehicles";

  IF v_users = 3 AND v_stations = 1 AND v_chargers = 2 AND v_vehicles = 1 THEN
    RAISE NOTICE 'CASE 1.1 PASSED: Baseline environment cleaned and seed entities populated successfully.';
  ELSE
    RAISE EXCEPTION 'CASE 1.1 FAILED: Unexpected row counts after seeding.';
  END IF;
END $$;
