
<<<<<<< HEAD
-- ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN reused_well_reference varchar;
-- COMMENT ON COLUMN "inbound"."WellInstallationActivities".reused_well_reference IS E'if an existing installation was reused or refreshed, this is its reference';

-- ALTER TABLE "inbound"."WellInstallationActivities" DROP COLUMN IF EXISTS reused_well_reference;

ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN reused_existing_well boolean DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".reused_existing_well IS E'flag if an existing installation was reused';

ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN reused_with_replacement boolean DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".reused_with_replacement IS E'whether an existing installation was reused and refreshed';


UPDATE "inbound"."WellInstallationActivities"
SET reused_existing_well = TRUE
WHERE random_point_number = 0
;

SELECT * FROM "inbound"."WellInstallationActivities"
WHERE watina_code_used_2_piezometer = 'LIEP014F'
;

UPDATE "inbound"."WellInstallationActivities"
SET reused_with_replacement = TRUE
WHERE random_point_number = 0
  AND watina_code_used_2_piezometer = 'LIEP014F'
;

SELECT * FROM "inbound"."WellInstallationActivities"
WHERE random_point_number = 0
;
=======
























ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN reused_well_reference varchar;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".reused_well_reference IS E'if an existing installation was reused or refreshed, this is its reference';


>>>>>>> 799abfc (dbinit: fieldwork ++re-use)
-- views adjusted:
--   gw_FieldWork
--   gw_myFieldWork
