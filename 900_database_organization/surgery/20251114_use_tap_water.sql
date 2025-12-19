
-- ALTER TABLE "inbound"."WellInstallationActivities" DROP COLUMN used_tap_water;
ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN used_water_from_tap boolean DEFAULT NULL;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".used_water_from_tap IS E'whether or not tap water was used for installation';

ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN used_water_source varchar DEFAULT NULL;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".used_water_source IS E'source of the water used for facilitating installation';
