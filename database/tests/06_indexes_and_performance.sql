-- ============================================================================
-- ChargeSync Platform - Database Test Suite
-- Test 06: Index Verification & Query Performance
-- Target Database: ChargeSync-Test
-- ============================================================================

\set ON_ERROR_STOP off

-- Case 6.1: Verify Core Performance Indexes Exist in PostgreSQL Catalog
DO $$
DECLARE
  v_missing_indexes text[];
BEGIN
  SELECT array_agg(expected_index) INTO v_missing_indexes
  FROM (
    VALUES 
      ('IX_Users_Email'),
      ('IX_Stations_OwnerId'),
      ('IX_Chargers_StationId'),
      ('IX_Reservations_ChargerId'),
      ('IX_Reservations_DriverId'),
      ('IX_Reservations_ChargerId_StartTime_EndTime'),
      ('IX_ChargingSessions_ReservationId'),
      ('IX_PaymentInvoices_SessionId'),
      ('IX_PaymentInvoices_Status'),
      ('IX_WalletTopUps_PaymentId'),
      ('IX_WalletTopUps_DriverId_RequestId'),
      ('IX_SupportTickets_InvoiceId')
  ) AS t(expected_index)
  WHERE expected_index NOT IN (
    SELECT indexname FROM pg_indexes WHERE schemaname = 'public'
  );

  IF v_missing_indexes IS NULL OR array_length(v_missing_indexes, 1) IS NULL THEN
    RAISE NOTICE 'CASE 6.1 PASSED: All 12 critical performance indexes verified in pg_catalog.';
  ELSE
    RAISE EXCEPTION 'CASE 6.1 FAILED: Missing indexes: %', v_missing_indexes;
  END IF;
END $$;

-- Case 6.2: Explain Plan on Active Stations & Chargers Query
EXPLAIN (COSTS OFF)
SELECT s."Id", s."Name", c."Identifier", c."PowerKw"
FROM "Stations" s
JOIN "Chargers" c ON c."StationId" = s."Id"
WHERE s."Status" = 'Approved';

-- Case 6.3: Explain Plan on Driver Reservation Lookup
EXPLAIN (COSTS OFF)
SELECT *
FROM "Reservations"
WHERE "DriverId" = '33333333-3333-3333-3333-333333333333';
