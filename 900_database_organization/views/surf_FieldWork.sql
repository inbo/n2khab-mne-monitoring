-- SELECT DISTINCT visit_id, count(*) AS n FROM "inbound"."FieldWork" GROUP BY visit_id ORDER BY n DESC;

-- !!! also re-create update MyFieldWork (below)



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
  VISIT.datetime_visit,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  VISIT.sampling_done,
  VISIT.visit_done,
  VISIT.lenticvisit_id,
  VISIT.loticvisit_id,
  (VISIT.lenticvisit_id IS NOT NULL) AS show_lenticvisits,
  (VISIT.loticvisit_id IS NOT NULL) AS show_loticvisits,
  VISIT.project_code,
  VISIT.recipient_code,
  VISIT.watertemperature_celsius,
  VISIT.sample_ph,
  VISIT.electric_conductivity_mus_cm,
  VISIT.dissolved_oxygen_mg_l,
  VISIT.dissolved_oxygen_percent,
VISIT.sample_contamination,
VISIT.sample_contamination_reason,
  VISIT.sneller_cm,
  VISIT.color,
  VISIT.smell,
  VISIT.zooplankton,
  VISIT.macroinvertebrates,
  VISIT.xphoto_sample,
  VISIT.equipment,
VISIT.chlorophytae_presence,
VISIT.chlorophytae_specification,
  VISIT.waterdepth_samplingpoint_cm,
  VISIT.secchi_depth_cm,
  VISIT.clear_to_bottom,
  VISIT.sludge_thickness,
  VISIT.waterlevel_elevation_mtaw,
  VISIT.sample_notes,
  VISIT.meandering,
  VISIT.flowvel,
  VISIT.flowvel_method,
  VISIT.barriers,
  VISIT.current_pits,
VISIT.link_observation_samplecontext,
SCOBS.samplecontextobservation_id,
SCOBS.notes AS samplecontext_notes,
SCOBS.alert AS samplecontext_alert,
SCOBS.photo AS samplecontext_photo,
SCOBS.max_depth_cm,
SCOBS.connectivity,
SCOBS.seep_influence,
SCOBS.coverage_rate,
SCOBS.shading,
SCOBS.leaf_deposition,
SCOBS.organic_material,
SCOBS.emergents,
SCOBS.float_pleustophytes,
SCOBS.float_nymphaeids,
SCOBS.submers_coverage,
SCOBS.submers_pvi,
SCOBS.metaphyton,
VISIT.link_observation_perturbation,
POBS.perturbationobservation_id,
POBS.notes AS perturbation_notes,
POBS.alert AS perturbation_alert,
POBS.photo AS perturbation_photo,
POBS.other_perturbations,
POBS.cow_pats,
POBS.other_animal_manure,
POBS.grazers,
POBS.trampling,
POBS.intense_livestock_farming,
POBS.agriculture_nearby,
POBS.recent_fertilization_nearby,
POBS.busy_roads_nearby,
POBS.industry_nearby,
POBS.fish,
POBS.birds,
POBS.bird_droppings,
POBS.beaver,
POBS.invasive_species,
POBS.bank_reinforcement,
POBS.drainage_structures,
POBS.fencing,
VISIT.link_observation_meteorology,
MOBS.meteorolobservation_id,
MOBS.notes AS meteo_notes,
MOBS.alert AS meteo_alert,
MOBS.photo AS meteo_photo,
MOBS.prior_48h,
MOBS.exceptional,
MOBS.precipitation,
MOBS.precipitation_specify,
MOBS.precipitation_intensity,
MOBS.overcast,
MOBS.airtemperature_celsius,
MOBS.wind,
MOBS.ice_layer_cm
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
LEFT JOIN "inbound"."SampleContextObservations" AS SCOBS
  ON (LOC.grts_address = SCOBS.grts_address
  AND VISIT.date_visit = SCOBS.date_visit)
LEFT JOIN "inbound"."PerturbationObservations" AS POBS
  ON (LOC.grts_address = POBS.grts_address
  AND VISIT.date_visit = POBS.date_visit)
LEFT JOIN "inbound"."MeteorolObservations" AS MOBS
  ON (LOC.grts_address = MOBS.grts_address
  AND VISIT.date_visit = MOBS.date_visit)
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
  datetime_visit = NEW.datetime_visit,
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
  sampling_done = NEW.sampling_done,
  visit_done = NEW.visit_done,
  link_observation_samplecontext = NEW.link_observation_samplecontext,
  link_observation_meteorology = NEW.link_observation_meteorology,
  link_observation_perturbation = NEW.link_observation_perturbation
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
  watertemperature_celsius = NEW.watertemperature_celsius,
  sample_ph = NEW.sample_ph,
  electric_conductivity_mus_cm = NEW.electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l = NEW.dissolved_oxygen_mg_l,
  dissolved_oxygen_percent = NEW.dissolved_oxygen_percent,
  sample_contamination = NEW.sample_contamination,
  sample_contamination_reason = NEW.sample_contamination_reason,
  sneller_cm = NEW.sneller_cm,
  color = NEW.color,
  smell = NEW.smell,
  zooplankton = NEW.zooplankton,
  macroinvertebrates = NEW.macroinvertebrates,
  equipment = NEW.equipment,
  chlorophytae_presence = NEW.chlorophytae_presence,
  chlorophytae_specification = NEW.chlorophytae_specification,
  waterdepth_samplingpoint_cm = NEW.waterdepth_samplingpoint_cm,
  secchi_depth_cm = NEW.secchi_depth_cm,
  clear_to_bottom = NEW.clear_to_bottom,
  sludge_thickness = NEW.sludge_thickness,
  sample_notes = NEW.sample_notes
 WHERE lenticvisit_id = OLD.lenticvisit_id
   AND visit_id = OLD.visit_id
   AND lenticvisit_id IS NOT NULL
;

-- TODO
DROP RULE IF EXISTS FieldWork_upd_LOTIC ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_LOTIC AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."LoticVisits"
 SET
  project_code = NEW.project_code,
  recipient_code = NEW.recipient_code,
  sample_ph = NEW.sample_ph,
  watertemperature_celsius = NEW.watertemperature_celsius,
  electric_conductivity_mus_cm = NEW.electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l = NEW.dissolved_oxygen_mg_l,
  dissolved_oxygen_percent = NEW.dissolved_oxygen_percent,
  equipment = NEW.equipment,
  color = NEW.color,
  smell = NEW.smell,
  zooplankton = NEW.zooplankton,
  macroinvertebrates = NEW.macroinvertebrates,
  sample_notes = NEW.sample_notes,
  sampling_done = NEW.sampling_done,
  sneller_cm = NEW.sneller_cm,
  secchi_depth_cm = NEW.secchi_depth_cm,
  clear_to_bottom = NEW.clear_to_bottom,
  waterdepth_samplingpoint_cm = NEW.waterdepth_samplingpoint_cm,
  sludge_thickness = NEW.sludge_thickness,
  ice_layer_cm = NEW.ice_layer_cm,
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


DROP RULE IF EXISTS fieldwork_ins_SCOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_ins_SCOBS AS
ON UPDATE TO "inbound"."FieldWork"
WHERE (NEW.samplecontextobservation_id IS NULL
  AND NEW.link_observation_samplecontext)
DO ALSO
 INSERT INTO "inbound"."SampleContextObservations" (
  teammember_id,
  date_visit,
  location,
  visit_id,
  is_linked_to_visit,
  grts_address,
  wkb_geometry
 ) VALUES (
  NEW.teammember_id,
  NEW.datetime_visit::date,
  CAST( NEW.grts_address AS varchar),
  NEW.visit_id,
  TRUE,
  NEW.grts_address,
  NEW.wkb_geometry
 )
;


DROP RULE IF EXISTS fieldwork_upd_SCOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_upd_SCOBS AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."SampleContextObservations"
 SET
  notes = NEW.samplecontext_notes,
  alert = NEW.samplecontext_alert,
  photo = NEW.samplecontext_photo,
  max_depth_cm = NEW.max_depth_cm,
  connectivity = NEW.connectivity,
  seep_influence = NEW.seep_influence,
  coverage_rate = NEW.coverage_rate,
  shading = NEW.shading,
  leaf_deposition = NEW.leaf_deposition,
  organic_material = NEW.organic_material,
  emergents = NEW.emergents,
  float_pleustophytes = NEW.float_pleustophytes,
  float_nymphaeids = NEW.float_nymphaeids,
  submers_coverage = NEW.submers_coverage,
  submers_pvi = NEW.submers_pvi,
  metaphyton = NEW.metaphyton
WHERE
  samplecontextobservation_id = OLD.samplecontextobservation_id
  AND grts_address = OLD.grts_address
  AND visit_id = OLD.visit_id
;




DROP RULE IF EXISTS fieldwork_ins_POBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_ins_POBS AS
ON UPDATE TO "inbound"."FieldWork"
WHERE (NEW.perturbationobservation_id IS NULL
  AND NEW.link_observation_perturbation)
DO ALSO
 INSERT INTO "inbound"."PerturbationObservations" (
  teammember_id,
  date_visit,
  location,
  visit_id,
  is_linked_to_visit,
  grts_address,
  wkb_geometry
 ) VALUES (
  NEW.teammember_id,
  NEW.datetime_visit::date,
  CAST( NEW.grts_address AS varchar),
  NEW.visit_id,
  TRUE,
  NEW.grts_address,
  NEW.wkb_geometry
 )
;


DROP RULE IF EXISTS fieldwork_upd_POBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_upd_POBS AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."PerturbationObservations"
 SET
  notes = NEW.perturbation_notes,
  alert = NEW.perturbation_alert,
  photo = NEW.perturbation_photo,
  other_perturbations = NEW.other_perturbations,
  cow_pats = NEW.cow_pats,
  other_animal_manure = NEW.other_animal_manure,
  grazers = NEW.grazers,
  trampling = NEW.trampling,
  intense_livestock_farming = NEW.intense_livestock_farming,
  agriculture_nearby = NEW.agriculture_nearby,
  recent_fertilization_nearby = NEW.recent_fertilization_nearby,
  busy_roads_nearby = NEW.busy_roads_nearby,
  industry_nearby = NEW.industry_nearby,
  fish = NEW.fish,
  birds = NEW.birds,
  bird_droppings = NEW.bird_droppings,
  beaver = NEW.beaver,
  invasive_species = NEW.invasive_species,
  bank_reinforcement = NEW.bank_reinforcement,
  drainage_structures = NEW.drainage_structures,
  fencing = NEW.fencing
WHERE
  perturbationobservation_id = OLD.perturbationobservation_id
  AND grts_address = OLD.grts_address
  AND visit_id = OLD.visit_id
;





DROP RULE IF EXISTS fieldwork_ins_MOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_ins_MOBS AS
ON UPDATE TO "inbound"."FieldWork"
WHERE (NEW.meteorolobservation_id IS NULL
  AND NEW.link_observation_meteorology)
DO ALSO
 INSERT INTO "inbound"."MeteorolObservations" (
  teammember_id,
  date_visit,
  location,
  visit_id,
  is_linked_to_visit,
  grts_address,
  wkb_geometry
 ) VALUES (
  NEW.teammember_id,
  NEW.datetime_visit::date,
  CAST( NEW.grts_address AS varchar),
  NEW.visit_id,
  TRUE,
  NEW.grts_address,
  NEW.wkb_geometry
 )
;


DROP RULE IF EXISTS fieldwork_upd_MOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_upd_MOBS AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."MeteorolObservations"
 SET
  notes = NEW.meteo_notes,
  alert = NEW.meteo_alert,
  photo = NEW.meteo_photo,
  prior_48h = NEW.prior_48h,
  exceptional = NEW.exceptional,
  precipitation = NEW.precipitation,
  precipitation_specify = NEW.precipitation_specify,
  precipitation_intensity = NEW.precipitation_intensity,
  overcast = NEW.overcast,
  airtemperature_celsius = NEW.airtemperature_celsius,
  wind = NEW.wind,
  ice_layer_cm = NEW.ice_layer_cm
WHERE
  meteorolobservation_id = OLD.meteorolobservation_id
  AND grts_address = OLD.grts_address
  AND visit_id = OLD.visit_id
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


