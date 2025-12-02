
























ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN reused_well_reference varchar;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".reused_well_reference IS E'if an existing installation was reused or refreshed, this is its reference';


-- views adjusted:
--   gw_FieldWork
--   gw_myFieldWork
