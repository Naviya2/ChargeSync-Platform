-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 02: Unique Constraints & Primary Key Enforcement
-- Target Database: ChargeSync-Test
-- ============================================================================

\set ON_ERROR_STOP off

-- Case 2.1: Duplicate User Email Validation
DO $$
BEGIN
  INSERT INTO "Users" ("Id", "Email", "FullName", "PasswordHash", "Role", "IsActive", "CreatedAt", "UpdatedAt", "WalletBalance")
  VALUES (gen_random_uuid(), 'admin@chargesync.test', 'Duplicate Admin Attempt', 'hash', 'Admin', true, NOW(), NOW(), 0.00);
  
  RAISE EXCEPTION 'CASE 2.1 FAILED: Duplicate email was improperly permitted!';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'CASE 2.1 PASSED: Unique constraint "IX_Users_Email" rejected duplicate email as expected.';
END $$;

-- Case 2.2: Duplicate Primary Key Validation
DO $$
BEGIN
  INSERT INTO "Users" ("Id", "Email", "FullName", "PasswordHash", "Role", "IsActive", "CreatedAt", "UpdatedAt", "WalletBalance")
  VALUES ('11111111-1111-1111-1111-111111111111', 'different.email@chargesync.test', 'PK Collision Attempt', 'hash', 'Admin', true, NOW(), NOW(), 0.00);
  
  RAISE EXCEPTION 'CASE 2.2 FAILED: Duplicate Primary Key was improperly permitted!';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'CASE 2.2 PASSED: Primary Key constraint "PK_Users" rejected duplicate Id as expected.';
END $$;

-- Case 2.3: Payment Transaction ID Uniqueness (WalletTopUps)
DO $$
DECLARE
  v_driver_id uuid := '33333333-3333-3333-3333-333333333333';
  v_payment_id text := 'PAY-UNIQUE-TEST-001';
BEGIN
  -- Insert initial record
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), v_driver_id, 1500.00, 'LKR', 'Completed', true, gen_random_uuid(), v_payment_id, '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  -- Attempt duplicate insertion with identical PaymentId
  INSERT INTO "WalletTopUps" ("Id", "DriverId", "Amount", "Currency", "Status", "Sandbox", "RequestId", "PaymentId", "Phone", "Address", "City", "CreatedAt", "Version")
  VALUES (gen_random_uuid(), v_driver_id, 1500.00, 'LKR', 'Completed', true, gen_random_uuid(), v_payment_id, '+94771234567', '123 Main St', 'Colombo', NOW(), gen_random_uuid());

  RAISE EXCEPTION 'CASE 2.3 FAILED: Duplicate payment transaction ID was permitted!';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'CASE 2.3 PASSED: Unique constraint "IX_WalletTopUps_PaymentId" rejected duplicate payment ID.';
END $$;
