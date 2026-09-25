dbname='mnmsurfdb_staging' host=172.233.44.119 port=2407 authcfg=mnmuser key='samplecontextobservation_id' srid=31370 type=Point checkPrimaryKeyUnicity='0' table="inbound"."SampleContextObservations" (wkb_geometry)


-- Visits, all of them
ALTER TABLE "inbound"."Visits" ADD COLUMN link_observation_samplecontext boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".link_observation_samplecontext IS E'choice to capture pool observation';
ALTER TABLE "inbound"."Visits" ADD COLUMN link_observation_meteorology boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".link_observation_meteorology IS E'choice to capture weather observation';
ALTER TABLE "inbound"."Visits" ADD COLUMN link_observation_perturbation boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".link_observation_perturbation IS E'choice to capture perturbation observation';


-- LenticVisits
ALTER TABLE "inbound"."LenticVisits" ADD COLUMN sample_contamination boolean NOT NULL DEFAULT FALSE;
ALTER TABLE "inbound"."LenticVisits" ADD COLUMN sample_contamination_reason varchar;
ALTER TABLE "inbound"."LenticVisits" ADD COLUMN chlorophytae_presence boolean;
ALTER TABLE "inbound"."LenticVisits" RENAME COLUMN vegetation_and_algae TO chlorophytae_specification;

COMMENT ON COLUMN "inbound"."LenticVisits".clear_to_bottom IS E'all clear: whether Secchi depth equals water depth at sampling point';
COMMENT ON COLUMN "inbound"."LenticVisits".color IS E'(geen, geel, oranje, bruin, zwart, groen, grijs, rood) - color of the water';
COMMENT ON COLUMN "inbound"."LenticVisits".dissolved_oxygen_mg_l IS E'oxygen measurement';
COMMENT ON COLUMN "inbound"."LenticVisits".dissolved_oxygen_percent IS E'oxygen saturation in percent';
COMMENT ON COLUMN "inbound"."LenticVisits".electric_conductivity_mus_cm IS E'electric conductivity measurement';
COMMENT ON COLUMN "inbound"."LenticVisits".equipment IS E'(wadend, schepstok) - sampling equipment (wading, scoop stick)';
COMMENT ON COLUMN "inbound"."LenticVisits".float_layer IS E'floating layer of proximity (2m) of sampling point';
COMMENT ON COLUMN "inbound"."LenticVisits".ice_layer_cm IS E'ice layer thickness (if present)';
COMMENT ON COLUMN "inbound"."LenticVisits".latest_calibration IS E'date of latest calibration of the field kit (pH, EC, O2)';
COMMENT ON COLUMN "inbound"."LenticVisits".lenticvisit_id IS E'technical index (extra, on top of visit_id)';
COMMENT ON COLUMN "inbound"."LenticVisits".macroinvertebrates IS E'(geen, weinig, matig, veel) more / arthropod critter';
COMMENT ON COLUMN "inbound"."LenticVisits".open_water IS E'open water (rate of water surface not covered by plants), in percent';
COMMENT ON COLUMN "inbound"."LenticVisits".phytoplankton IS E'presence of phytoplankton in the sample';
COMMENT ON COLUMN "inbound"."LenticVisits".chlorophytae_presence IS E'presence of vegetation, metaphyton and/or float at the sample point';
COMMENT ON COLUMN "inbound"."LenticVisits".project_code IS E'LIMS project code of this sample';
COMMENT ON COLUMN "inbound"."LenticVisits".recipient_code IS E'LIMS recipient code of this sample';
COMMENT ON COLUMN "inbound"."LenticVisits".sample_contamination IS E'(waar/onwaar) - whether the sample is contaminated, i.e. not free of dirt particles';
COMMENT ON COLUMN "inbound"."LenticVisits".sample_contamination_reason IS E'reason / character of the sample contamination';
COMMENT ON COLUMN "inbound"."LenticVisits".sample_notes IS E'misc notes on hydrological parameters';
COMMENT ON COLUMN "inbound"."LenticVisits".sample_ph IS E'-log10([H+])';
COMMENT ON COLUMN "inbound"."LenticVisits".secchi_depth_cm IS E'the depth at which a monochrome radially patterned disc is visually perceivable, with the tools of Angelo Secchi (1865)';
COMMENT ON COLUMN "inbound"."LenticVisits".sludge_thickness IS E'sludge layer thickness in centimeters';
COMMENT ON COLUMN "inbound"."LenticVisits".smell IS E'(geen, metallisch, zwavel, ammoniak, mest, riool, visachtig) - specific, noteworthy smell of the water';
COMMENT ON COLUMN "inbound"."LenticVisits".sneller_cm IS E'visibility depth of a small Secchi disc in a gray PVC tube filled with sample water';
COMMENT ON COLUMN "inbound"."LenticVisits".turbidity IS E'glas clear, light, turbid TO BE REPLACED BY water_clarity';
COMMENT ON COLUMN "inbound"."LenticVisits".chlorophytae_specification IS E'specification of non-open water and expected effect on sample';
COMMENT ON COLUMN "inbound"."LenticVisits".water_clarity IS E'glas clear, light, turbid';
COMMENT ON COLUMN "inbound"."LenticVisits".waterdepth_samplingpoint_cm IS E'the current depth of the water body at the sampling point';
COMMENT ON COLUMN "inbound"."LenticVisits".waterdepth_samplingpoint_m IS E'the current depth of the water body at the sampling point';
COMMENT ON COLUMN "inbound"."LenticVisits".watertemperature_celsius IS E'water temperature at the sampling spot';
COMMENT ON COLUMN "inbound"."LenticVisits".zooplankton IS E'(geen, weinig, matig, veel) passively moving aquatic critter';


-- Observations

ALTER TABLE "inbound"."Observations" ADD COLUMN grts_address bigint CHECK (grts_address > 0);
ALTER TABLE "inbound"."Observations" ADD COLUMN is_linked_to_visit boolean NOT NULL DEFAULT FALSE;
ALTER TABLE "inbound"."Observations" ADD COLUMN visit_id int;
COMMENT ON COLUMN "inbound"."Observations".location IS E'free but unique link to the location, e.g. GRTS address or name of the area or follow-up number (filled automatically on linked observations)';
COMMENT ON COLUMN "inbound"."Observations".grts_address IS E'GRTS address in case of visit-linked observations';
COMMENT ON COLUMN "inbound"."Observations".is_linked_to_visit IS E'flag observations which link to a visit';
COMMENT ON COLUMN "inbound"."Observations".visit_id IS E'index link to visits';

-- SampleContextObservations

SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."SampleContextObservations" CASCADE;

BEGIN;
CREATE TABLE "inbound"."SampleContextObservations"()
INHERITS ("inbound"."Observations")
;

COMMENT ON TABLE "inbound"."SampleContextObservations" IS E'observations on and around the water body of interest';

ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN samplecontextobservation_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."SampleContextObservations".samplecontextobservation_id IS E'technical index (extra, on top of visit_id)';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN max_depth_cm int CHECK (max_depth_cm >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".max_depth_cm IS E'estimated maximum depth of the pool (cm)';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN connectivity varchar;
COMMENT ON COLUMN "inbound"."SampleContextObservations".connectivity IS E'(gesloten, instroom, doorstroom, overstroomd) how this pool connects to other water bodies: isolated, inflow, throughflow, overflow';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN seep_influence varchar;
COMMENT ON COLUMN "inbound"."SampleContextObservations".seep_influence IS E'(niet, iriserende film, roestbruinig water of slib) seep/spring instream of groundwater';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN coverage_rate int CHECK (coverage_rate >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".coverage_rate IS E'coverage / rate of non-open water, in percent';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN shading int;
COMMENT ON COLUMN "inbound"."SampleContextObservations".shading IS E'percantage shading of the water surface (estimated, noon)';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN leaf_deposition int;
COMMENT ON COLUMN "inbound"."SampleContextObservations".leaf_deposition IS E'share of watersurface which is straight under tree branches to indicate influence of leaf deposition';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN organic_material varchar;
COMMENT ON COLUMN "inbound"."SampleContextObservations".organic_material IS E'(weinig, matig, veel) rough estimate of organic input load';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN emergents int CHECK (emergents >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".emergents IS E'horizontal projection of ground-rooted plants which emerge from the water surface';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN float_pleustophytes int CHECK (float_pleustophytes >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".float_pleustophytes IS E'coverage rate with floating plants (e.g. Lemnoidae, Stratiotes); horizontal surface / percent';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN float_nymphaeids int CHECK (float_nymphaeids >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".float_nymphaeids IS E'coverage rate with floating parts of rooted plants (Nymphaeaceae, e.g. Nymphaea, Nuphar); horizontal surface / percent';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN submers_coverage int CHECK (submers_coverage >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".submers_coverage IS E'coverage with submersive plants';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN submers_pvi int CHECK (submers_pvi >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".submers_pvi IS E'submersive plant infestation (vertical projection), in percent';
ALTER TABLE "inbound"."SampleContextObservations" ADD COLUMN metaphyton int CHECK (metaphyton >= 0);
COMMENT ON COLUMN "inbound"."SampleContextObservations".metaphyton IS E'water column coverage rate (percentage) of metaphytic filamentous algae';

COMMIT;

-- sequence samplecontextobservation_id
CREATE SEQUENCE "inbound".seq_samplecontextobservation_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."SampleContextObservations".samplecontextobservation_id;
ALTER TABLE "inbound"."SampleContextObservations" ALTER COLUMN samplecontextobservation_id
 SET DEFAULT nextval('inbound.seq_samplecontextobservation_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_samplecontextobservation_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_samplecontextobservation_id" TO viewer_mnmdb;

GRANT SELECT ON "inbound"."SampleContextObservations" TO viewer_mnmdb;

GRANT INSERT ON "inbound"."SampleContextObservations" TO user_surfdb;
GRANT UPDATE ON "inbound"."SampleContextObservations" TO user_surfdb;
GRANT DELETE ON "inbound"."SampleContextObservations" TO user_surfdb;


-- PerturbationObservations

COMMENT ON COLUMN "inbound"."PerturbationObservations".other_perturbations IS E'other perturbation not listed below (specify)';
COMMENT ON COLUMN "inbound"."PerturbationObservations".drainage_structures IS E'(waar/onwaar) tubes, ditches, canals, pits';
COMMENT ON COLUMN "inbound"."PerturbationObservations".fencing IS E'(waar/onwaar) barbed or electric wire';

ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN cow_pats boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".cow_pats IS E'(aanwezig/niet) cow droppings, fresh or dry';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN other_animal_manure boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".other_animal_manure IS E'(aanwezig/niet) animal feces in noteworthy amounts';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN grazers boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".grazers IS E'(aanwezig/niet) noted the presence of grazers, then those are obviously no ninja grazers';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN trampling boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".trampling IS E'(aanwezig/niet) trampling, can be an indication of grazers, or fat German tourists';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN intense_livestock_farming boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".intense_livestock_farming IS E'(waar/onwaar) just what it says...';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN agriculture_nearby boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".agriculture_nearby IS E'(waar/onwaar) proximity of agricultural fields';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN recent_fertilization_nearby boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".recent_fertilization_nearby IS E'(waar/onwaar) indication of recent fertilization';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN busy_roads_nearby boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".busy_roads_nearby IS E'(waar/onwaar) potential influence of emissions from the transport sector';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN industry_nearby boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".industry_nearby IS E'(waar/onwaar) industrial sites which might affect the nitrogen situation';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN fish boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".fish IS E'(waar/onwaar) I suppose the MV referred to Osteichthyes';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN birds boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".birds IS E'(waar/onwaar) the avian subclade of theropod dinosaurs';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN bird_droppings boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".bird_droppings IS E'(waar/onwaar) bird shit';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN beaver boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".beaver IS E'(waar/onwaar) any traces of the beaver: bite marks, dams and lodges, or the animal itself';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN invasive_species boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".invasive_species IS E'(waar/onwaar) e.g. Impatiens glandilufera, Elodea canadensis, Lemna minuta, Hydrocotyle ranunculoides, Fallopia japonica, Heracleum mantegazzianum';
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN bank_reinforcement boolean;
COMMENT ON COLUMN "inbound"."PerturbationObservations".bank_reinforcement IS E'(waar/onwaar) anthropogenic support of erosive shorelines';


-- MeteorolObservations

ALTER TABLE "inbound"."MeteorolObservations" ADD COLUMN ice_layer_cm double precision DEFAULT 0.0 CHECK (ice_layer_cm >= 0);
COMMENT ON COLUMN "inbound"."MeteorolObservations".ice_layer_cm IS E'ice layer thickness (if present)';


-- triggers

DROP TRIGGER IF EXISTS log_observations ON "inbound"."Observations";
CREATE TRIGGER log_observations
BEFORE UPDATE ON "inbound"."Observations"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

DROP TRIGGER IF EXISTS log_samplecontextobservations ON "inbound"."SampleContextObservations";
CREATE TRIGGER log_samplecontextobservations
BEFORE UPDATE ON "inbound"."SampleContextObservations"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

DROP TRIGGER IF EXISTS log_perturbationobservations ON "inbound"."PerturbationObservations";
CREATE TRIGGER log_perturbationobservations
BEFORE UPDATE ON "inbound"."PerturbationObservations"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

DROP TRIGGER IF EXISTS log_meteorolobservations ON "inbound"."MeteorolObservations";
CREATE TRIGGER log_meteorolobservations
BEFORE UPDATE ON "inbound"."MeteorolObservations"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();




DROP VIEW IF EXISTS  "inbound"."FieldWork" CASCADE;
CREATE VIEW "inbound"."FieldWork" AS
SELECT
  LOC.*,
  VISIT.stratum,
  VISIT.date_start,
  VISIT.activity_group_id,
  FCAL.teammember_assigned,
  FCAL.activity_rank,
  CASE WHEN (FCAL.date_visit_planned IS NULL) THEN FALSE ELSE FCAL.done_planning = TRUE END AS is_scheduled,
  FCAL.date_visit_planned,
  FCAL.date_visit_planned - current_date AS days_to_visit,
  FCAL.date_end - current_date AS days_to_deadline,
  FCAL.notes AS preparation_notes,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.landowner,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  LOCEVAL.loceval_date,
  LOCEVAL.loceval_name,
  LOCEVAL.type_assessed,
  LOCEVAL.type_is_absent,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  FAGS.activity_group,
  FAGS.is_field_activity,
  FAGS.is_surf_activity,
  FAGS.protocols,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.datetime_visit,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  VISIT.lenticvisit_id,
  VISIT.loticvisit_id,
  (VISIT.lenticvisit_id IS NOT NULL) AS show_lenticvisits,
  (VISIT.loticvisit_id IS NOT NULL) AS show_loticvisits,
  VISIT.project_code,
  VISIT.recipient_code,
    VISIT.latest_calibration,
  VISIT.sample_ph,
  VISIT.watertemperature_celsius,
  VISIT.electric_conductivity_mus_cm,
  VISIT.dissolved_oxygen_mg_l,
  VISIT.dissolved_oxygen_percent,
  VISIT.equipment,
  VISIT.color,
  VISIT.smell,
    VISIT.phytoplankton,
    VISIT.zooplankton,
    VISIT.macroinvertebrates,
    VISIT.open_water,
  VISIT.sample_notes,
  VISIT.sampling_done,
  VISIT.sneller_cm,
  VISIT.secchi_depth_cm,
    VISIT.clear_to_bottom,
  VISIT.turbidity,
    VISIT.water_clarity,
  VISIT.waterdepth_samplingpoint_m,
  VISIT.waterdepth_samplingpoint_cm,
  VISIT.sludge_thickness,
  VISIT.ice_layer_cm,
  VISIT.chlorophytae_specification AS vegetation_and_algae,
  VISIT.float_layer,
  VISIT.meandering,
  VISIT.flowvel,
  VISIT.flowvel_method,
  VISIT.barriers,
  VISIT.current_pits,
  VISIT.visit_done
FROM (
  SELECT *
  FROM ONLY "inbound"."Visits"
  NATURAL FULL JOIN "inbound"."LenticVisits"
  NATURAL FULL JOIN "inbound"."LoticVisits"
  NATURAL FULL JOIN "inbound"."OtherVisits"
) AS VISIT
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.location_id = VISIT.location_id
LEFT JOIN (
  SELECT *,
    CASE WHEN (date_visit_planned IS NULL) THEN FALSE ELSE done_planning = TRUE END AS is_scheduled
  FROM "outbound"."FieldCalendars"
  ) AS FCAL
  ON FCAL.fieldcalendar_id = VISIT.fieldcalendar_id
LEFT JOIN (
  SELECT DISTINCT
    activity_group_id,
    activity_group,
    is_field_activity,
    is_surf_activity,
    string_agg(DISTINCT('' || protocol_code || '/v' || protocol_version), E',') AS protocols
  FROM "metadata"."GroupedActivities" AS GACT
  LEFT JOIN "metadata"."Protocols" AS PRT
    ON PRT.protocol_id = GACT.protocol_id
  GROUP BY
    activity_group_id,
    activity_group,
    is_field_activity,
    is_surf_activity
  ) AS FAGS
  ON FAGS.activity_group_id = VISIT.activity_group_id
LEFT JOIN (
  SELECT
    sampleunit_id,
    loceval_name,
    loceval_date,
    type_assessed,
    type_is_absent,
    loceval_notes,
    loceval_photo
  FROM (
    SELECT DISTINCT
      sampleunit_id,
      MAX(eval_date) AS latest_visit,
      eval_date AS loceval_date,
      eval_name AS loceval_name,
      type AS type_planned,
      type_assessed,
      type_is_absent,
      notes AS loceval_notes,
      photo AS loceval_photo
    FROM "transfer"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY sampleunit_id,
    eval_date,
    eval_name,
    type,
    type_assessed,
    type_is_absent,
    notes,
    photo
  ) WHERE loceval_date = latest_visit
    AND ((loceval_notes IS NOT NULL) OR (loceval_photo IS NOT NULL) OR (type_assessed IS NOT NULL))
) AS LOCEVAL
  ON VISIT.sampleunit_id = LOCEVAL.sampleunit_id
WHERE TRUE
  AND FCAL.is_scheduled
  AND ((FCAL.no_visit_planned IS NULL) OR (NOT FCAL.no_visit_planned))
  AND NOT FCAL.excluded
  AND FAGS.is_surf_activity
  AND (VISIT.visit_done OR (FCAL.archive_version_id IS NULL))
  AND (VISIT.visit_done OR (VISIT.archive_version_id IS NULL))
;


-- https://stackoverflow.com/q/44005446
DROP RULE IF EXISTS FieldWork_upd0 ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd0 AS
ON UPDATE TO "inbound"."FieldWork"
DO INSTEAD NOTHING
;

DROP RULE IF EXISTS FieldWork_upd_VIS ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_VIS AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  datetime_visit = NEW.datetime_visit,
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
  sampling_done = NEW.sampling_done,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;


DROP RULE IF EXISTS FieldWork_upd_LENTIC ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_LENTIC AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."LenticVisits"
 SET
  project_code = NEW.project_code,
  recipient_code = NEW.recipient_code,
  latest_calibration = NEW.latest_calibration,
  sample_ph = NEW.sample_ph,
  watertemperature_celsius = NEW.watertemperature_celsius,
  electric_conductivity_mus_cm = NEW.electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l = NEW.dissolved_oxygen_mg_l,
  dissolved_oxygen_percent = NEW.dissolved_oxygen_percent,
  equipment = NEW.equipment,
  color = NEW.color,
  smell = NEW.smell,
  phytoplankton = NEW.phytoplankton,
  zooplankton = NEW.zooplankton,
  macroinvertebrates = NEW.macroinvertebrates,
  open_water = NEW.open_water,
  sample_notes = NEW.sample_notes,
  sampling_done = NEW.sampling_done,
  sneller_cm = NEW.sneller_cm,
  secchi_depth_cm = NEW.secchi_depth_cm,
  clear_to_bottom = NEW.clear_to_bottom,
  turbidity = NEW.turbidity,
  water_clarity = NEW.water_clarity,
  waterdepth_samplingpoint_m = NEW.waterdepth_samplingpoint_m,
  waterdepth_samplingpoint_cm = NEW.waterdepth_samplingpoint_cm,
  sludge_thickness = NEW.sludge_thickness,
  ice_layer_cm = NEW.ice_layer_cm,
  chlorophytae_specification = NEW.vegetation_and_algae,
  float_layer = NEW.float_layer,
  visit_done = NEW.visit_done
 WHERE lenticvisit_id = OLD.lenticvisit_id
   AND visit_id = OLD.visit_id
   AND lenticvisit_id IS NOT NULL
;

DROP RULE IF EXISTS FieldWork_upd_LOTIC ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_LOTIC AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."LoticVisits"
 SET
  project_code = NEW.project_code,
  recipient_code = NEW.recipient_code,
  latest_calibration = NEW.latest_calibration,
  sample_ph = NEW.sample_ph,
  watertemperature_celsius = NEW.watertemperature_celsius,
  electric_conductivity_mus_cm = NEW.electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l = NEW.dissolved_oxygen_mg_l,
  dissolved_oxygen_percent = NEW.dissolved_oxygen_percent,
  equipment = NEW.equipment,
  color = NEW.color,
  smell = NEW.smell,
  phytoplankton = NEW.phytoplankton,
  zooplankton = NEW.zooplankton,
  macroinvertebrates = NEW.macroinvertebrates,
  open_water = NEW.open_water,
  sample_notes = NEW.sample_notes,
  sampling_done = NEW.sampling_done,
  sneller_cm = NEW.sneller_cm,
  secchi_depth_cm = NEW.secchi_depth_cm,
  clear_to_bottom = NEW.clear_to_bottom,
  turbidity = NEW.turbidity,
  water_clarity = NEW.water_clarity,
  waterdepth_samplingpoint_m = NEW.waterdepth_samplingpoint_m,
  sludge_thickness = NEW.sludge_thickness,
  ice_layer_cm = NEW.ice_layer_cm,
  vegetation_and_algae = NEW.vegetation_and_algae,
  float_layer = NEW.float_layer,
  meandering = NEW.meandering,
  flowvel = NEW.flowvel,
  flowvel_method = NEW.flowvel_method,
  barriers = NEW.barriers,
  current_pits = NEW.current_pits,
  visit_done = NEW.visit_done
 WHERE loticvisit_id = OLD.loticvisit_id
   AND visit_id = OLD.visit_id
   AND loticvisit_id IS NOT NULL
;

DROP RULE IF EXISTS FieldWork_upd_INFO ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_INFO AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit,
  recovery_hints = NEW.recovery_hints,
  equipment_recommendations = NEW.equipment_recommendations
 WHERE locationinfo_id = OLD.locationinfo_id
;


GRANT SELECT ON  "inbound"."FieldWork"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  user_surfdb;



-- DROP VIEW IF EXISTS  "inbound"."MyFieldWork" ;
CREATE OR REPLACE VIEW "inbound"."MyFieldWork" AS
SELECT * FROM "inbound"."FieldWork"
WHERE teammember_assigned IN (
  SELECT DISTINCT teammember_id
  FROM "metadata"."TeamMembers"
  WHERE (username = 'all_surfers')
    OR (LOWER(username) = LOWER(current_user))
) OR visit_done;



GRANT SELECT ON  "inbound"."MyFieldWork"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  user_surfdb;

-- only on testing:
-- GRANT SELECT ON  "inbound"."FieldWork"  TO  tester;
-- GRANT UPDATE ON  "inbound"."FieldWork"  TO  tester;

-- GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tester;
-- GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tester;
