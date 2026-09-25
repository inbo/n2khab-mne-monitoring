
BEGIN;

-- views must temporarily be removed, they otherwise block the changes below
DROP VIEW "inbound"."AllVisits" CASCADE;
DROP VIEW "inbound"."FieldWork" CASCADE;
DROP VIEW "outbound"."FieldworkPlanning" CASCADE;

-- constraints will be reworked
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_fieldcalendar_visits;
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_FieldCalendars_Visits;
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_SampleUnits_Visits;



-- some columns change table: those are planned "per visit"
ALTER TABLE "inbound"."Visits" ADD COLUMN teammember_assigned smallint;
COMMENT ON COLUMN "inbound"."Visits".teammember_assigned IS E'filter for an assignee';

ALTER TABLE "inbound"."Visits" ADD COLUMN date_visit_planned date;
COMMENT ON COLUMN "inbound"."Visits".date_visit_planned IS E'planned date of visit';

ALTER TABLE "inbound"."Visits" ADD COLUMN preparation_notes text;
COMMENT ON COLUMN "inbound"."Visits".preparation_notes IS E'Free text notes from the colleague who planned this.';

-- foreign key teammember_assigned
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_TeamMembers_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_TeamMembers_Visits FOREIGN KEY (teammember_assigned)
REFERENCES "metadata"."TeamMembers" (teammember_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;


UPDATE "inbound"."Visits" AS TRGTAB
  SET
    teammember_assigned = SRCTAB.teammember_assigned,
    date_visit_planned = SRCTAB.date_visit_planned,
    preparation_notes = SRCTAB.notes
  FROM "outbound"."FieldCalendars" AS SRCTAB
  WHERE
    SRCTAB.fieldcalendar_id = TRGTAB.fieldcalendar_id
    AND SRCTAB.grts_address = TRGTAB.grts_address
    AND SRCTAB.date_start = TRGTAB.date_start
    AND SRCTAB.stratum = TRGTAB.stratum
;



-- STRUCTURE PREPARATION

-- NOTE: `Visits` and `FieldCalendars` have to switch order in the TABLES structure sheet

-- columns for matching occasions
ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN matching_occasion varchar;
COMMENT ON COLUMN "outbound"."FieldCalendars".matching_occasion IS E'group label of actifity groups which may be combined (optional match)';

ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN date_suggested date;
COMMENT ON COLUMN "outbound"."FieldCalendars".date_suggested IS E'earliest date of activities in an optional matching group';

UPDATE "outbound"."FieldCalendars"
SET date_suggested = date_start;


-- visit_id as fk to FieldCalendars
ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN visit_id int DEFAULT NULL;
COMMENT ON COLUMN "outbound"."FieldCalendars".visit_id IS E'link to the visit which serves this calendar entry';

-- ALTER TABLE "outbound"."FieldCalendars" DROP CONSTRAINT IF EXISTS fk_Visits_FieldCalendars CASCADE;
-- ALTER TABLE "outbound"."FieldCalendars" ADD CONSTRAINT fk_Visits_FieldCalendars FOREIGN KEY (visit_id)
-- REFERENCES "inbound"."Visits" (visit_id) MATCH SIMPLE
-- ON DELETE SET NULL ON UPDATE CASCADE;

UPDATE "outbound"."FieldCalendars" AS TRGTAB
  SET
    visit_id = SRCTAB.visit_id
  FROM "inbound"."Visits" AS SRCTAB
  WHERE
    SRCTAB.fieldcalendar_id = TRGTAB.fieldcalendar_id
    AND SRCTAB.grts_address = TRGTAB.grts_address
    AND SRCTAB.date_start = TRGTAB.date_start
    AND SRCTAB.stratum = TRGTAB.stratum
;



-- Visits.stratums
ALTER TABLE "inbound"."Visits"
ALTER COLUMN stratum TYPE varchar ARRAY
USING ARRAY[stratum];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN stratum TO stratums;
COMMENT ON COLUMN "inbound"."Visits".stratums IS E'strata for which this visit can provide data';


-- Visits.fieldcalendar_ids
ALTER TABLE "inbound"."Visits"
ALTER COLUMN fieldcalendar_id TYPE int ARRAY
USING ARRAY[fieldcalendar_id];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN fieldcalendar_id TO fieldcalendar_ids;
COMMENT ON COLUMN "inbound"."Visits".fieldcalendar_ids IS E'optional shortcut: collection of all FieldCalendars entries which are served by this visit';

-- Visits.sampleunit_ids
ALTER TABLE "inbound"."Visits"
ALTER COLUMN sampleunit_id TYPE int ARRAY
USING ARRAY[sampleunit_id];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN sampleunit_id TO sampleunit_ids;
COMMENT ON COLUMN "inbound"."Visits".sampleunit_ids IS E'array of sample unit indices (technical) or NULL for obsolete visits';


-- COMMIT;


-- DATA AGGREGATION

-- -- check match!
-- SELECT *
--   FROM (
-- SELECT DISTINCT
--   grts_address,
--   date_start,
--   activity_group_id,
--   count(*) AS n_visits
-- FROM "inbound"."Visits"
-- GROUP BY grts_address, date_start, activity_group_id
-- ) AS VZ
-- NATURAL FULL JOIN (
-- SELECT DISTINCT
--   grts_address,
--   date_start,
--   activity_group_id,
--   count(*) AS n_calendars
-- FROM "outbound"."FieldCalendars"
-- GROUP BY grts_address, date_start, activity_group_id
-- ) AS FC
-- ORDER BY activity_group_id, date_start, grts_address
-- ;


-- temporary helper column to identify the aggregated rows
ALTER TABLE "inbound"."Visits"
ADD COLUMN is_aggregated BOOLEAN NOT NULL DEFAULT FALSE;

-- has to happen separately per *Visit class

\COPY (SELECT * FROM "inbound"."LenticVisits" WHERE visit_done)  TO '~/20260925_lentic_visits_preaggregated.csv' With CSV DELIMITER ',' HEADER;

-- create a copy of the existing Visits
DROP TABLE IF EXISTS "archive"."UnaggregatedVisitsBackup";
CREATE TABLE "archive"."UnaggregatedVisitsBackup" AS
SELECT *
FROM ONLY "inbound"."Visits"
NATURAL FULL JOIN "inbound"."LenticVisits"
NATURAL FULL JOIN "inbound"."LoticVisits"
NATURAL FULL JOIN "inbound"."OtherVisits"
ORDER BY visit_id ASC
;


-- DROP the excess columns; note that they actually did contain data!
-- SELECT DISTINCT latest_calibration FROM "inbound"."LenticVisits";
-- SELECT DISTINCT water_clarity FROM "inbound"."LenticVisits";
-- SELECT DISTINCT turbidity FROM "inbound"."LenticVisits";
-- SELECT DISTINCT open_water FROM "inbound"."LenticVisits";
-- SELECT DISTINCT waterdepth_samplingpoint_m FROM "inbound"."LenticVisits";
-- SELECT DISTINCT float_layer FROM "inbound"."LenticVisits";
-- SELECT DISTINCT phytoplankton FROM "inbound"."LenticVisits";
-- SELECT DISTINCT ice_layer_cm FROM "inbound"."LenticVisits";

ALTER TABLE "inbound"."LenticVisits" DROP COLUMN latest_calibration;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN water_clarity;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN turbidity;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN open_water;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN waterdepth_samplingpoint_m;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN float_layer;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN phytoplankton;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN ice_layer_cm;




INSERT INTO "inbound"."LenticVisits" (
  log_user,
  log_update,
  location_id,
  fieldcalendar_ids,
  sampleunit_ids,
  stratums,
  grts_address,
  activity_group_id,
  date_start,
  teammember_assigned,
  date_visit_planned,
  preparation_notes,
  teammember_id,
  date_visit,
  datetime_visit,
  sampling_done,
  notes,
  photo,
  issues,
  visit_done,
  link_observation_samplecontext,
  link_observation_meteorology,
  link_observation_perturbation,
  archive_version_id,
  is_aggregated,
  equipment,
  chlorophytae_presence,
  chlorophytae_specification,
  waterdepth_samplingpoint_cm,
  secchi_depth_cm,
  clear_to_bottom,
  sludge_thickness,
  waterlevel_elevation_mtaw,
  project_code,
  recipient_code,
  watertemperature_celsius,
  sample_ph,
  electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l,
  dissolved_oxygen_percent,
  sample_notes,
  sample_contamination,
  sample_contamination_reason,
  sneller_cm,
  color,
  smell,
  zooplankton,
  macroinvertebrates,
  xphoto_sample
)
SELECT DISTINCT
-- ON (location_id, grts_address, date_start, activity_group_id)
  COALESCE(
    (STRING_AGG(DISTINCT log_user, ',' )
     FILTER (WHERE log_user NOT IN ('maintenance'))
    ),
    'maintenance'
    ) AS log_user,
  MAX(log_update) AS log_update,
  location_id,
  ARRAY_AGG(DISTINCT fc_id ORDER BY fc_id) AS fieldcalendar_ids,
  ARRAY_AGG(DISTINCT su_id ORDER BY su_id) AS sampleunit_ids,
  ARRAY_AGG(DISTINCT strats ORDER BY strats) AS stratums,
  grts_address,
  activity_group_id,
  date_start,
  MAX(teammember_assigned) AS teammember_assigned,
  MAX(date_visit_planned) AS date_visit_planned,
  STRING_AGG(DISTINCT preparation_notes, ', ') AS preparation_notes,
  MAX(teammember_id) AS teammember_id,
  MAX(date_visit) AS date_visit,
  MAX(datetime_visit) AS datetime_visit,
  BOOL_OR(sampling_done) AS sampling_done,
  STRING_AGG(notes, ', ') AS notes,
  STRING_AGG(photo, ', ') AS photo,
  BOOL_OR(issues) AS issues,
  BOOL_OR(visit_done) AS visit_done,
  BOOL_OR(link_observation_samplecontext) AS link_observation_samplecontext,
  BOOL_OR(link_observation_meteorology) AS link_observation_meteorology,
  BOOL_OR(link_observation_perturbation) AS link_observation_perturbation,
  CASE WHEN BOOL_OR(archive_version_id IS NULL)
    THEN NULL
    ELSE (SELECT DISTINCT MAX(version_id) FROM "metadata"."Versions")
    END AS archive_version_id,
  TRUE AS is_aggregated,
  STRING_AGG(DISTINCT equipment, ', ') AS equipment,
  BOOL_OR(chlorophytae_presence) AS chlorophytae_presence,
  STRING_AGG(DISTINCT chlorophytae_specification, ', ') AS chlorophytae_specification,
  AVG(waterdepth_samplingpoint_cm) AS waterdepth_samplingpoint_cm,
  AVG(secchi_depth_cm) AS secchi_depth_cm,
  BOOL_OR(clear_to_bottom) AS clear_to_bottom,
  AVG(sludge_thickness) AS sludge_thickness,
  AVG(waterlevel_elevation_mtaw) AS waterlevel_elevation_mtaw,
  STRING_AGG(DISTINCT project_code, ', ') AS project_code,
  STRING_AGG(DISTINCT recipient_code, ', ') AS recipient_code,
  AVG(watertemperature_celsius) AS watertemperature_celsius,
  AVG(sample_ph) AS sample_ph,
  AVG(electric_conductivity_mus_cm) AS electric_conductivity_mus_cm,
  AVG(dissolved_oxygen_mg_l) AS dissolved_oxygen_mg_l,
  AVG(dissolved_oxygen_percent) AS dissolved_oxygen_percent,
  STRING_AGG(DISTINCT sample_notes, ', ') AS sample_notes,
  BOOL_OR(COALESCE(sample_contamination, FALSE)) AS sample_contamination,
  STRING_AGG(DISTINCT sample_contamination_reason, ', ') AS sample_contamination_reason,
  AVG(sneller_cm) AS sneller_cm,
  STRING_AGG(DISTINCT color, ', ') AS color,
  STRING_AGG(DISTINCT smell, ', ') AS smell,
  STRING_AGG(DISTINCT zooplankton, ', ') AS zooplankton,
  STRING_AGG(DISTINCT macroinvertebrates, ', ') AS macroinvertebrates,
  STRING_AGG(DISTINCT xphoto_sample, ', ') AS xphoto_sample
FROM "inbound"."LenticVisits",
LATERAL
  UNNEST(fieldcalendar_ids) AS fc_id,
  UNNEST(sampleunit_ids) AS su_id,
  UNNEST(stratums) AS strats
GROUP BY location_id, grts_address, date_start, activity_group_id
;


INSERT INTO "inbound"."LenticVisits" (
  log_user,
  log_update,
  location_id,
  fieldcalendar_ids,
  sampleunit_ids,
  stratums,
  grts_address,
  activity_group_id,
  date_start,
  teammember_assigned,
  date_visit_planned,
  preparation_notes,
  teammember_id,
  date_visit,
  datetime_visit,
  sampling_done,
  notes,
  photo,
  issues,
  visit_done,
  link_observation_samplecontext,
  link_observation_meteorology,
  link_observation_perturbation,
  archive_version_id,
  equipment,
  chlorophytae_presence,
  chlorophytae_specification,
  waterdepth_samplingpoint_cm,
  secchi_depth_cm,
  clear_to_bottom,
  sludge_thickness,
  waterlevel_elevation_mtaw,
  project_code,
  recipient_code,
  watertemperature_celsius,
  sample_ph,
  electric_conductivity_mus_cm,
  dissolved_oxygen_mg_l,
  dissolved_oxygen_percent,
  sample_notes,
  sample_contamination,
  sample_contamination_reason,
  sneller_cm,
  color,
  smell,
  zooplankton,
  macroinvertebrates,
  xphoto_sample,
  is_aggregated
)
SELECT
  UV.log_user,
  UV.log_update,
  UV.location_id,
  UV.fieldcalendar_ids,
  UV.sampleunit_ids,
  UV.stratums,
  UV.grts_address,
  UV.activity_group_id,
  UV.date_start,
  UV.teammember_assigned,
  UV.date_visit_planned,
  UV.preparation_notes,
  UV.teammember_id,
  UV.date_visit,
  UV.datetime_visit,
  UV.sampling_done,
  UV.notes,
  UV.photo,
  UV.issues,
  UV.visit_done,
  UV.link_observation_samplecontext,
  UV.link_observation_meteorology,
  UV.link_observation_perturbation,
  UV.archive_version_id,
  UV.equipment,
  UV.chlorophytae_presence,
  UV.chlorophytae_specification,
  UV.waterdepth_samplingpoint_cm,
  UV.secchi_depth_cm,
  UV.clear_to_bottom,
  UV.sludge_thickness,
  UV.waterlevel_elevation_mtaw,
  UV.project_code,
  UV.recipient_code,
  UV.watertemperature_celsius,
  UV.sample_ph,
  UV.electric_conductivity_mus_cm,
  UV.dissolved_oxygen_mg_l,
  UV.dissolved_oxygen_percent,
  UV.sample_notes,
  COALESCE(UV.sample_contamination, FALSE),
  UV.sample_contamination_reason,
  UV.sneller_cm,
  UV.color,
  UV.smell,
  UV.zooplankton,
  UV.macroinvertebrates,
  UV.xphoto_sample,
  TRUE
FROM "archive"."UnaggregatedVisitsBackup" UV
LEFT JOIN (
  SELECT DISTINCT grts_address, stratums, fieldcalendar_ids, activity_group_id, date_start,
  lenticvisit_id AS already_present
  FROM "inbound"."LenticVisits" WHERE is_aggregated
) AS LV
  ON (UV.grts_address = LV.grts_address)
  AND (UV.date_start = LV.date_start)
  AND (UV.stratums <@ LV.stratums)
  AND (UV.activity_group_id = LV.activity_group_id)
  AND (UV.fieldcalendar_ids <@ LV.fieldcalendar_ids)
WHERE (already_present IS NULL)
  AND (lenticvisit_id IS NOT NULL)
; -- responds `(0, 0) updated`, but is fine


DELETE FROM "inbound"."LenticVisits" WHERE NOT is_aggregated;

ALTER TABLE "inbound"."Visits" DROP COLUMN is_aggregated;



DROP VIEW IF EXISTS  "outbound"."MatchingOccasions" CASCADE;
CREATE OR REPLACE VIEW "outbound"."MatchingOccasions" AS
SELECT
  FC.fieldcalendar_id,
  FC.visit_id,
  FC.grts_address,
  FC.stratum,
  FC.matching_occasion
FROM "outbound"."FieldCalendars" FC
LEFT JOIN "inbound"."Visits" VZ
  ON VZ.visit_id = FC.visit_id
  AND VZ.grts_address = FC.grts_address
  AND VZ.date_start = FC.date_start
  AND VZ.activity_group_id = FC.activity_group_id
WHERE VZ.visit_id IS NOT NULL
;
DROP VIEW IF EXISTS  "outbound"."FieldCalendarsAggregated" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldCalendarsAggregated" AS
SELECT
  grts_address, date_start, activity_group_id, matching_occasion, visit_id,
  ARRAY_AGG(DISTINCT stratum ORDER BY stratum) AS stratums,
  ARRAY_AGG(DISTINCT sampleunit_id ORDER BY sampleunit_id) AS sampleunit_ids,
  ARRAY_AGG(DISTINCT fieldcalendar_id ORDER BY fieldcalendar_id) AS fieldcalendar_ids,
  STRING_AGG(DISTINCT log_user, ', ') AS log_users,
  MAX(log_update) AS log_update,
  UNNEST(ARRAY_AGG(DISTINCT date_end)) AS date_end,
  UNNEST(ARRAY_AGG(DISTINCT date_interval)) AS date_interval,
  UNNEST(ARRAY_AGG(DISTINCT activity_rank)) AS activity_rank,
  MIN(date_suggested) AS date_suggested,
  MIN(priority) AS priority,
  BOOL_AND(wait_any) AS wait_any,
  BOOL_AND(wait_watersurface)   AS wait_watersurface,
  BOOL_AND(wait_3260)           AS wait_3260,
  BOOL_AND(wait_7220)           AS wait_7220,
  BOOL_AND(wait_floating)       AS wait_floating,
  BOOL_AND(wait_obsolete_types) AS wait_obsolete_types,
  BOOL_AND(is_sideloaded)       AS is_sideloaded,
  BOOL_AND(is_frozen)           AS is_frozen,
  BOOL_AND(excluded) AS excluded,
  STRING_AGG(DISTINCT excluded_reason, ', ') AS excluded_reason,
  BOOL_AND(done_planning) AS done_planning
FROM "outbound"."FieldCalendars"
WHERE archive_version_id IS NULL
  AND grts_address = 1012434 AND date_start = '2026-07-01'
GROUP BY grts_address, date_start, activity_group_id, matching_occasion, visit_id
;
DROP VIEW IF EXISTS  "inbound"."VisitsUnnested" CASCADE;
CREATE OR REPLACE VIEW "inbound"."VisitsUnnested" AS
SELECT
 *,
 UNNEST(stratums) AS stratum,
 UNNEST(sampleunit_ids) AS sampleunit_id,
 UNNEST(fieldcalendar_ids) AS fieldcalendar_id
FROM "inbound"."Visits"
;




COMMIT;


\COPY (SELECT * FROM "inbound"."LenticVisits" WHERE visit_done)  TO '~/20260925_lentic_visits_postaggregated.csv' With CSV DELIMITER ',' HEADER;

-- better join on SQL for comparison
\COPY (
  SELECT *
  FROM "archive"."UnaggregatedVisitsBackup" UV
  LEFT JOIN "inbound"."LenticVisits" LV
    ON  (UV.grts_address = LV.grts_address)
    AND (UV.date_start = LV.date_start)
    AND (UV.activity_group_id = LV.activity_group_id)
    AND (UV.stratums <@ LV.stratums)
)  TO '~/20260925_lentic_visits_prepostjoined.csv' With CSV DELIMITER ',' HEADER;
  -- WHERE UV.grts_address = 3514038 AND UV.date_start = '2026-07-01'
