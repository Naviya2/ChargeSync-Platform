-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 04: Domain Check Constraints & End-to-End Workflow Integrity
-- Target Database: ChargeSync-Test
-- ============================================================================

\set ON_ERROR_STOP off

-- Ensure baseline reservation exists for workflow tests
INSERT INTO "Reservations" ("Id", "DriverId", "ChargerId", "StartTime", "EndTime", "AdvanceDepositAmount", "Status", "CreatedAt", "UpdatedAt")
VALUES ('88888888-8888-8888-8888-888888888881', '33333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555551', NOW(), NOW() + INTERVAL '2 hours', 500.00, 'Pending', NOW(), NOW())
ON CONFLICT ("Id") DO NOTHING;

-- Case 4.1: Check Constraint - Reject Negative Amounts on PaymentInvoices
DO $$
DECLARE
  v_res_id uuid := '88888888-8888-8888-8888-888888888881';
  v_session_id uuid := gen_random_uuid();
BEGIN
  -- Insert dummy session first
  INSERT INTO "ChargingSessions" ("Id", "ReservationId", "StartTime", "Status", "AutoCalculatedKwh", "CreatedAt", "UpdatedAt")
  VALUES (v_session_id, v_res_id, NOW(), 'InProgress', 20.00, NOW(), NOW());

  -- Attempt to insert an invoice with illegal negative net amount
  INSERT INTO "PaymentInvoices" ("Id", "SessionId", "DriverId", "TariffPerKwh", "GrossAmount", "AdvanceDeducted", "NetAmountDue", "RefundedAmount", "DiscountPercentage", "DiscountAmount", "Status", "IssuedAt", "CreatedAt", "UpdatedAt")
  VALUES (gen_random_uuid(), v_session_id, '33333333-3333-3333-3333-333333333333', 75.00, 1500.00, 0.00, -500.00, 0.00, 0.00, 0.00, 'Pending', NOW(), NOW(), NOW());

  RAISE EXCEPTION 'CASE 4.1 FAILED: Check constraint allowed negative NetAmountDue!';
EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'CASE 4.1 PASSED: Check constraint "CK_PaymentInvoices_Amounts" blocked negative invoice amount.';
    -- Cleanup dummy session
    DELETE FROM "ChargingSessions" WHERE "Id" = v_session_id;
END $$;

-- Case 4.2: Check Constraint - Reject Invalid Charging Session Status
DO $$
DECLARE
  v_res_id uuid := '88888888-8888-8888-8888-888888888881';
BEGIN
  INSERT INTO "ChargingSessions" ("Id", "ReservationId", "StartTime", "Status", "AutoCalculatedKwh", "CreatedAt", "UpdatedAt")
  VALUES (gen_random_uuid(), v_res_id, NOW(), 'InvalidSessionStatus', 10.00, NOW(), NOW());

  RAISE EXCEPTION 'CASE 4.2 FAILED: Check constraint allowed illegal Status string!';
EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'CASE 4.2 PASSED: Check constraint "CK_ChargingSessions_Status" rejected invalid status.';
END $$;

-- Case 4.3: Valid Workflow Integrity - Chain from Reservation -> Session -> Invoice
DO $$
DECLARE
  v_res_id uuid := '88888888-8888-8888-8888-888888888881';
  v_session_id uuid := '99999999-9999-9999-9999-999999999991';
  v_invoice_id uuid := '99999999-9999-9999-9999-999999999992';
  v_joined_count int;
BEGIN
  -- Insert Completed Session
  INSERT INTO "ChargingSessions" ("Id", "ReservationId", "StartTime", "EndTime", "Status", "AutoCalculatedKwh", "FinalEnergyDeliveredKwh", "CreatedAt", "UpdatedAt")
  VALUES (v_session_id, v_res_id, NOW() - INTERVAL '45 minutes', NOW(), 'Completed', 28.50, 28.50, NOW(), NOW())
  ON CONFLICT ("Id") DO NOTHING;

  -- Insert Paid Invoice (Tariff: 75 LKR/kWh * 28.5 kWh = 2137.50 LKR)
  INSERT INTO "PaymentInvoices" ("Id", "SessionId", "DriverId", "TariffPerKwh", "GrossAmount", "AdvanceDeducted", "NetAmountDue", "RefundedAmount", "DiscountPercentage", "DiscountAmount", "Status", "PaymentMethod", "IssuedAt", "CreatedAt", "UpdatedAt")
  VALUES (v_invoice_id, v_session_id, '33333333-3333-3333-3333-333333333333', 75.00, 2137.50, 0.00, 2137.50, 0.00, 0.00, 0.00, 'Paid', 'Wallet', NOW(), NOW(), NOW())
  ON CONFLICT ("Id") DO NOTHING;

  -- Assert relational join works flawlessly
  SELECT COUNT(*) INTO v_joined_count
  FROM "Reservations" r
  JOIN "ChargingSessions" s ON s."ReservationId" = r."Id"
  JOIN "PaymentInvoices" i ON i."SessionId" = s."Id"
  WHERE r."Id" = v_res_id;

  IF v_joined_count = 1 THEN
    RAISE NOTICE 'CASE 4.3 PASSED: Full lifecycle chain (Reservation -> Session -> Invoice) successfully verified.';
  ELSE
    RAISE EXCEPTION 'CASE 4.3 FAILED: Relational join query failed to resolve the lifecycle chain!';
  END IF;
END $$;
