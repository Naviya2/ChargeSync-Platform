-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 05: Wallet Top-Up Constraints, Idempotency & Currency Checks
-- Target Database: ChargeSync-Test
-- ============================================================================

\set ON_ERROR_STOP off

-- Case 5.1: Check Constraint - Min/Max Top-up Amount Rules (100 <= Amount <= 50000)
DO $$
BEGIN
  -- Attempt to insert an invalid 50 LKR topup (Below 100 minimum)
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 50.00, 'LKR', 'Pending', true, gen_random_uuid(), 'PAY-INVALID-01', '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  RAISE EXCEPTION 'CASE 5.1 FAILED: Top-up below 100 LKR was allowed!';
EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'CASE 5.1 PASSED: Check constraint "CK_WalletTopUps_Amount" blocked below-minimum top-up.';
END $$;

-- Case 5.2: Check Constraint - Currency Restriction ("Currency" = 'LKR')
DO $$
BEGIN
  -- Attempt to insert an invalid USD topup
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 1000.00, 'USD', 'Pending', true, gen_random_uuid(), 'PAY-INVALID-02', '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  RAISE EXCEPTION 'CASE 5.2 FAILED: Non-LKR currency was allowed!';
EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'CASE 5.2 PASSED: Check constraint "CK_WalletTopUps_Currency" enforced LKR currency rule.';
END $$;

-- Case 5.3: Idempotency Protection - Duplicate RequestId per Driver
DO $$
DECLARE
  v_driver_id uuid := '33333333-3333-3333-3333-333333333333';
  v_req_id uuid := gen_random_uuid();
BEGIN
  -- Insert first top-up
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), v_driver_id, 2500.00, 'LKR', 'Completed', true, v_req_id, 'PAY-PH-1001', '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  -- Attempt duplicate insertion with same RequestId for same driver
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), v_driver_id, 2500.00, 'LKR', 'Completed', true, v_req_id, 'PAY-PH-1002', '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  RAISE EXCEPTION 'CASE 5.3 FAILED: Duplicate payment request ID was accepted!';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'CASE 5.3 PASSED: Unique composite index on (DriverId, RequestId) enforced payment idempotency.';
END $$;
