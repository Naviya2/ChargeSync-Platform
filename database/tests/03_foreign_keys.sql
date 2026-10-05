-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 03: Foreign Key Referential Integrity & Cascade/Restrict Rules
-- Target Database: ChargeSync-Test
-- ============================================================================

\set ON_ERROR_STOP off

-- Case 3.1: Reject Charger with Non-Existent Station
DO $$
BEGIN
  INSERT INTO "Chargers" ("Id", "StationId", "Identifier", "BayLabel", "Connector", "PowerKw", "Tariff", "Status", "CreatedAt", "UpdatedAt")
  VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'BAY-ORPHAN-01', 'Bay Orphan', 'CCS2', 50.00, 75.00, 'Available', NOW(), NOW());

  RAISE EXCEPTION 'CASE 3.1 FAILED: Orphan charger was inserted without valid station!';
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'CASE 3.1 PASSED: Foreign key "FK_Chargers_Stations_StationId" prevented orphan charger.';
END $$;

-- Case 3.2: Reject Reservation with Non-Existent Charger
DO $$
BEGIN
  INSERT INTO "Reservations" ("Id", "DriverId", "ChargerId", "StartTime", "EndTime", "AdvanceDepositAmount", "Status", "CreatedAt", "UpdatedAt")
  VALUES (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', NOW(), NOW() + INTERVAL '1 hour', 500.00, 'Pending', NOW(), NOW());

  RAISE EXCEPTION 'CASE 3.2 FAILED: Reservation allowed non-existent Charger!';
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'CASE 3.2 PASSED: Foreign key "FK_Reservations_Chargers_ChargerId" rejected invalid charger.';
END $$;

-- Case 3.3: DeleteBehavior.Restrict Protection (Driver with Reservations cannot be deleted)
DO $$
DECLARE
  v_res_id uuid := '88888888-8888-8888-8888-888888888881';
BEGIN
  -- Insert a valid reservation linked to Driver Nimal
  INSERT INTO "Reservations" ("Id", "DriverId", "ChargerId", "StartTime", "EndTime", "AdvanceDepositAmount", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_res_id, '33333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555551', NOW() + INTERVAL '1 hour', NOW() + INTERVAL '2 hours', 500.00, 'Pending', NOW(), NOW());

  -- Attempt to delete the Driver user (Must be blocked by FK Restrict)
  DELETE FROM "Users" WHERE "Id" = '33333333-3333-3333-3333-333333333333';

  RAISE EXCEPTION 'CASE 3.3 FAILED: Driver with linked reservations was deleted!';
EXCEPTION
  WHEN foreign_key_violation OR restrict_violation THEN
    RAISE NOTICE 'CASE 3.3 PASSED: DeleteBehavior.Restrict prevented deletion of User with active records.';
END $$;
