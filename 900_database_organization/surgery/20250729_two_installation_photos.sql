SELECT * FROM "inbound"."WellInstallationActivities";

ALTER TABLE "inbound"."WellInstallationActivities" RENAME COLUMN
watina_code_used_1 TO watina_code_used_1_peilbuis;
ALTER TABLE "inbound"."WellInstallationActivities" RENAME COLUMN
watina_code_used_2 TO watina_code_used_2_piezometer;
ALTER TABLE "inbound"."WellInstallationActivities" RENAME COLUMN
photo_soil TO photo_soil_1_peilbuis;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".photo_soil_1_peilbuis IS 'photo of the soil drill profile: peilbuis';



ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN photo_soil_2_piezometer varchar DEFAULT NULL;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".photo_soil_2_piezometer IS 'photo of the soil drill profile: piezometer';

ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN free_diver varchar DEFAULT NULL;
COMMENT ON COLUMN "inbound"."WellInstallationActivities".free_diver IS 'free field to enter a non-registered diver code';




SELECT * FROM "inbound"."ChemicalSamplingActivities";

ALTER TABLE "inbound"."ChemicalSamplingActivities" RENAME COLUMN
lims_code TO recipient_code;
COMMENT ON COLUMN "inbound"."ChemicalSamplingActivities".recipient_code IS 'LIMS recipient code of this sample';

ALTER TABLE "inbound"."ChemicalSamplingActivities" ADD COLUMN project_code varchar DEFAULT NULL;
COMMENT ON COLUMN "inbound"."ChemicalSamplingActivities".project_code IS 'LIMS project code of this sample';


-- adjust views!!
