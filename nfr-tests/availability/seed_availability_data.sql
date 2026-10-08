-- 1. Ensure Station status is Active (Valid Domain Enum: Active, Pending, Rejected, Suspended)
UPDATE "Stations" 
SET "Status" = 'Active' 
WHERE "Id" = '44444444-4444-4444-4444-444444444444';

-- 2. Ensure Charger statuses are Available (Valid Domain Enum: Available, Occupied, Maintenance, Offline)
UPDATE "Chargers"
SET "Status" = 'Available'
WHERE "Id" IN ('55555555-5555-5555-5555-555555555551', '55555555-5555-5555-5555-555555555552');

-- 3. Seed Operating Hours for Station (06:00 to 23:00 everyday)
DELETE FROM "OperatingHours" WHERE "StationId" = '44444444-4444-4444-4444-444444444444';

INSERT INTO "OperatingHours" ("Id", "StationId", "DayOfWeek", "IsEnabled", "OpenTime", "CloseTime", "CreatedAt", "UpdatedAt")
VALUES 
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 0, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 1, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 2, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 3, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 4, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 5, true, '06:00:00', '23:00:00', now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 6, true, '06:00:00', '23:00:00', now(), now());

-- 4. Seed a test Maintenance Window on Bay 2 (AC22) for exclusion verification
DELETE FROM "MaintenanceWindows" WHERE "ChargerId" = '55555555-5555-5555-5555-555555555552';

INSERT INTO "MaintenanceWindows" ("Id", "ChargerId", "StartTime", "EndTime", "Reason", "CreatedAt")
VALUES (
  gen_random_uuid(),
  '55555555-5555-5555-5555-555555555552',
  '2026-10-15 10:00:00+05:30',
  '2026-10-15 14:00:00+05:30',
  'Scheduled maintenance window calibration',
  now()
);
