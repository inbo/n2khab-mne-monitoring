-- SELECT DISTINCT visit_id, count(*) AS n FROM "inbound"."FieldWork" GROUP BY visit_id ORDER BY n DESC;
SELECT *,
  CASE WHEN (date_visit_planned IS NULL) THEN FALSE ELSE done_planning END AS is_scheduled
FROM "outbound"."FieldCalendars"
  WHERE grts_address = 1176286
  AND activity_group_id = 4
;



-- refactoring notes
SELECT *
FROM ONLY "inbound"."Visits"
UNION
SELECT *
FROM ONLY "inbound"."InstallationVisits"

\COPY (SELECT * FROM "inbound"."RefactorFieldWork") TO '/data/mnm_db_backups/refactor_fieldwork_new.csv' WITH CSV DELIMITER ',' HEADER ;
\COPY (SELECT * FROM "inbound"."FieldWork") TO '/data/mnm_db_backups/refactor_fieldwork_old.csv' WITH CSV DELIMITER ',' HEADER ;

missing fields:
- is_gw_activity
- is_fieldwork_activity
- protocol_id (wip)
- default_protocol_id (wip)

WITH test_query AS (

DROP VIEW IF EXISTS  "inbound"."RefactorFieldWork" CASCADE;
CREATE OR REPLACE VIEW "inbound"."RefactorFieldWork" AS
SELECT
  LOC.*,
  UNIT.stratum AS type,
  CALVIS.date_start,
  CALVIS.date_end,
  CALVIS.date_interval,
  CALVIS.activity_group_id,
  CALVIS.teammember_assigned,
  CALVIS.activity_rank,
  CALVIS.is_scheduled,
  CALVIS.date_visit_planned,
  CALVIS.days_to_visit,
  CALVIS.days_to_deadline,
  CALVIS.preparation_notes,
  CALVIS.visit_id,
  CALVIS.teammember_id,
  CALVIS.date_visit,
  CALVIS.notes,
  CALVIS.photo,
  CALVIS.issues,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  INFO.is_secret_location,
  INFO.landowner,
  INFO.watina_code_1,
  INFO.watina_code_2,
  SOIL.soil_info,
  LOCEVAL.loceval_notes,
  LOCEVAL.loceval_photo,
  ACT.activity_group,
  ACT.protocols,
  IVIS.installationvisit_id,
  SVIS.samplingvisit_id,
  PVIS.positioningvisit_id,
  OVIS.othervisit_id,
  (IVIS.installationvisit_id IS NOT NULL) AS show_installation,
  (SVIS.samplingvisit_id IS NOT NULL) AS show_sampling,
  (PVIS.positioningvisit_id IS NOT NULL) AS show_positioning,
  (OVIS.othervisit_id IS NOT NULL) AS show_other,
  IVIS.photo_soil_1_peilbuis,
  IVIS.photo_soil_2_piezometer,
  IVIS.photo_well,
  IVIS.watina_code_used_1_peilbuis,
  IVIS.watina_code_used_2_piezometer,
  IVIS.soilprofile_notes,
  IVIS.soilprofile_unclear,
  IVIS.no_diver,
  IVIS.random_point_number,
  IVIS.diver_id,
  IVIS.free_diver,
  IVIS.reused_existing_well,
  IVIS.reused_with_replacement,
  IVIS.used_water_from_tap,
  IVIS.used_water_source,
  IVIS.is_cattleproof,
  SVIS.project_code,
  SVIS.recipient_code,
  PVIS.require_total_station,
  CALVIS.visit_done,
  ACT.activity_group ||
    CASE WHEN  CALVIS.issues
    THEN ' issues'
    ELSE (
      CASE WHEN CALVIS.visit_done THEN ' done' ELSE ''
      END)
    END AS status,
  CASE WHEN CALVIS.visit_done
      THEN '[✓] '
      ELSE '[_] '
      END ||
    ACT.activity_group ||
    CASE WHEN (CALVIS.date_visit_planned IS NOT NULL)
    THEN ' (' || TO_CHAR(CALVIS.date_visit_planned, 'yyyy-mm-dd') || ')'
    ELSE ''
    END
  AS label
FROM (
  SELECT
    CAL.sampleunit_id,
    CAL.date_end,
    CAL.date_interval,
    CAL.teammember_assigned,
    CAL.activity_rank,
    CASE WHEN (CAL.date_visit_planned IS NULL) THEN FALSE ELSE CAL.done_planning = TRUE END AS is_scheduled,
    CAL.date_visit_planned,
    CAL.date_visit_planned - current_date AS days_to_visit,
    CAL.date_end - current_date AS days_to_deadline,
    CAL.notes AS preparation_notes,
    CAL.sampling_route_group,
    CAL.done_planning,
    VIS.visit_id,
    VIS.grts_address,
    VIS.stratum,
    VIS.activity_group_id,
    VIS.date_start,
    VIS.teammember_id,
    VIS.date_visit,
    VIS.notes,
    VIS.photo,
    VIS.issues,
    VIS.visit_done
  FROM
    "inbound"."Visits" AS VIS,
    "outbound"."FieldCalendars" AS CAL
  WHERE (VIS.visit_id = CAL.visit_id)
    AND (
      (CAL.done_planning IS TRUE
      AND CAL.archive_version_id IS NULL
      AND VIS.archive_version_id IS NULL
      AND NOT CAL.excluded
      )
      OR (VIS.visit_done IS TRUE)
    )
) AS CALVIS
LEFT JOIN "inbound"."InstallationVisits" AS IVIS
  ON IVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."SamplingVisits" AS SVIS
  ON SVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."PositioningVisits" AS PVIS
  ON PVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."OtherVisits" AS OVIS
  ON OVIS.visit_id = CALVIS.visit_id
INNER JOIN (
  SELECT DISTINCT
    activity_group_id,
    activity_group,
    string_agg(DISTINCT('' || protocol_code || '/v' || protocol_version), E',') AS protocols
  FROM "metadata"."GroupedActivities" AS GACT
  LEFT JOIN "metadata"."Protocols" AS PRT
    ON PRT.protocol_id = GACT.protocol_id
  WHERE is_gw_activity
  GROUP BY
    activity_group_id,
    activity_group
) AS ACT
  ON ACT.activity_group_id = CALVIS.activity_group_id
INNER JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = CALVIS.sampleunit_id
INNER JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON UNIT.location_id = INFO.location_id
LEFT JOIN (
  SELECT DISTINCT location_id, info AS soil_info
  FROM "metadata"."LocationSoilInfos"
  ) AS SOIL
  ON UNIT.location_id = SOIL.location_id
LEFT JOIN (
  SELECT sampleunit_id, loceval_notes, loceval_photo
  FROM (
    SELECT DISTINCT
      sampleunit_id,
      MAX(eval_date) AS latest_visit,
      eval_date,
      notes AS loceval_notes,
      photo AS loceval_photo
    FROM "transfer"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY sampleunit_id, eval_date, notes, photo
  ) WHERE eval_date = latest_visit
    AND ((loceval_notes IS NOT NULL) OR (loceval_photo IS NOT NULL))
) AS LOCEVAL
  ON UNIT.sampleunit_id = LOCEVAL.sampleunit_id
;


)
SELECT COUNT(*) FROM test_query
;




-- !!! also re-create update MyFieldWork
BEGIN;

DROP VIEW IF EXISTS  "inbound"."FieldWork" CASCADE;
CREATE OR REPLACE VIEW "inbound"."FieldWork" AS
SELECT
  LOC.*,
  UNIT.stratum AS type,
  CALVIS.date_start,
  CALVIS.date_end,
  CALVIS.date_interval,
  CALVIS.activity_group_id,
  CALVIS.teammember_assigned,
  CALVIS.activity_rank,
  CALVIS.protocol_id,
  CALVIS.is_scheduled,
  CALVIS.date_visit_planned,
  CALVIS.days_to_visit,
  CALVIS.days_to_deadline,
  CALVIS.preparation_notes,
  CALVIS.visit_id,
  CALVIS.teammember_id,
  CALVIS.date_visit,
  CALVIS.notes,
  CALVIS.photo,
  CALVIS.issues,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  INFO.is_secret_location,
  INFO.landowner,
  INFO.watina_code_1,
  INFO.watina_code_2,
  SOIL.soil_info,
  LOCEVAL.loceval_notes,
  LOCEVAL.loceval_photo,
  ACT.activity_group,
  ACT.protocols,
  IVIS.installationvisit_id,
  SVIS.samplingvisit_id,
  PVIS.positioningvisit_id,
  OVIS.othervisit_id,
  (IVIS.installationvisit_id IS NOT NULL) AS show_installation,
  (SVIS.samplingvisit_id IS NOT NULL) AS show_sampling,
  (PVIS.positioningvisit_id IS NOT NULL) AS show_positioning,
  (OVIS.othervisit_id IS NOT NULL) AS show_other,
  IVIS.photo_soil_1_peilbuis,
  IVIS.photo_soil_2_piezometer,
  IVIS.photo_well,
  IVIS.watina_code_used_1_peilbuis,
  IVIS.watina_code_used_2_piezometer,
  IVIS.soilprofile_notes,
  IVIS.soilprofile_unclear,
  IVIS.no_diver,
  IVIS.random_point_number,
  IVIS.diver_id,
  IVIS.free_diver,
  IVIS.reused_existing_well,
  IVIS.reused_with_replacement,
  IVIS.used_water_from_tap,
  IVIS.used_water_source,
  IVIS.is_cattleproof,
  SVIS.project_code,
  SVIS.recipient_code,
  PVIS.require_total_station,
  CALVIS.visit_done,
  ACT.activity_group ||
    CASE WHEN  CALVIS.issues
    THEN ' issues'
    ELSE (
      CASE WHEN CALVIS.visit_done THEN ' done' ELSE ''
      END)
    END AS status,
  CASE WHEN CALVIS.visit_done
      THEN '[✓] '
      ELSE '[_] '
      END ||
    ACT.activity_group ||
    CASE WHEN (CALVIS.date_visit_planned IS NOT NULL)
    THEN ' (' || TO_CHAR(CALVIS.date_visit_planned, 'yyyy-mm-dd') || ')'
    ELSE ''
    END
  AS label
FROM (
  SELECT
    CAL.sampleunit_id,
    CAL.date_end,
    CAL.date_interval,
    CAL.teammember_assigned,
    CAL.activity_rank,
    CASE WHEN (CAL.date_visit_planned IS NULL) THEN FALSE ELSE CAL.done_planning = TRUE END AS is_scheduled,
    CAL.date_visit_planned,
    CAL.date_visit_planned - current_date AS days_to_visit,
    CAL.date_end - current_date AS days_to_deadline,
    CAL.notes AS preparation_notes,
    CAL.sampling_route_group,
    CAL.done_planning,
    VIS.visit_id,
    VIS.grts_address,
    VIS.stratum,
    VIS.activity_group_id,
    VIS.protocol_id,
    VIS.date_start,
    VIS.teammember_id,
    VIS.date_visit,
    VIS.notes,
    VIS.photo,
    VIS.issues,
    VIS.visit_done
  FROM
    "inbound"."Visits" AS VIS,
    "outbound"."FieldCalendars" AS CAL
  WHERE (VIS.visit_id = CAL.visit_id)
    AND (
      (CAL.done_planning IS TRUE
      AND CAL.archive_version_id IS NULL
      AND VIS.archive_version_id IS NULL
      AND NOT CAL.excluded
      )
      OR (VIS.visit_done IS TRUE)
    )
) AS CALVIS
LEFT JOIN "inbound"."InstallationVisits" AS IVIS
  ON IVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."SamplingVisits" AS SVIS
  ON SVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."PositioningVisits" AS PVIS
  ON PVIS.visit_id = CALVIS.visit_id
LEFT JOIN "inbound"."OtherVisits" AS OVIS
  ON OVIS.visit_id = CALVIS.visit_id
INNER JOIN (
  SELECT DISTINCT
    activity_group_id,
    activity_group,
    string_agg(DISTINCT('' || protocol_code || '/v' || protocol_version), E',') AS protocols
  FROM "metadata"."GroupedActivities" AS GACT
  LEFT JOIN "metadata"."Protocols" AS PRT
    ON PRT.protocol_id = GACT.protocol_id
  WHERE is_gw_activity
  GROUP BY
    activity_group_id,
    activity_group
) AS ACT
  ON ACT.activity_group_id = CALVIS.activity_group_id
INNER JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = CALVIS.sampleunit_id
INNER JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON UNIT.location_id = INFO.location_id
LEFT JOIN (
  SELECT DISTINCT location_id, info AS soil_info
  FROM "metadata"."LocationSoilInfos"
  ) AS SOIL
  ON UNIT.location_id = SOIL.location_id
LEFT JOIN (
  SELECT sampleunit_id, loceval_notes, loceval_photo
  FROM (
    SELECT DISTINCT
      sampleunit_id,
      MAX(eval_date) AS latest_visit,
      eval_date,
      notes AS loceval_notes,
      photo AS loceval_photo
    FROM "transfer"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY sampleunit_id, eval_date, notes, photo
  ) WHERE eval_date = latest_visit
    AND ((loceval_notes IS NOT NULL) OR (loceval_photo IS NOT NULL))
) AS LOCEVAL
  ON UNIT.sampleunit_id = LOCEVAL.sampleunit_id
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
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
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
  equipment_recommendations = NEW.equipment_recommendations,
  is_secret_location = NEW.is_secret_location
 WHERE locationinfo_id = OLD.locationinfo_id
;

DROP RULE IF EXISTS FieldWork_upd_INSTALLATION ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_INSTALLATION AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."InstallationVisits"
 SET
  photo_soil_1_peilbuis = NEW.photo_soil_1_peilbuis,
  photo_soil_2_piezometer = NEW.photo_soil_2_piezometer,
  soilprofile_notes = NEW.soilprofile_notes,
  soilprofile_unclear = NEW.soilprofile_unclear,
  photo_well = NEW.photo_well,
  watina_code_used_1_peilbuis = NEW.watina_code_used_1_peilbuis,
  watina_code_used_2_piezometer = NEW.watina_code_used_2_piezometer,
  random_point_number = NEW.random_point_number,
  no_diver = NEW.no_diver,
  diver_id = NEW.diver_id,
  free_diver = NEW.free_diver,
  reused_existing_well = NEW.reused_existing_well,
  reused_with_replacement = NEW.reused_with_replacement,
  used_water_from_tap = NEW.used_water_from_tap,
  used_water_source = NEW.used_water_source,
  is_cattleproof = NEW.is_cattleproof
 WHERE installationvisit_id = OLD.installationvisit_id
   AND installationvisit_id IS NOT NULL
;

DROP RULE IF EXISTS FieldWork_upd_SAMPLING ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_SAMPLING AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."SamplingVisits"
 SET
  project_code = NEW.project_code,
  recipient_code = NEW.recipient_code
 WHERE samplingvisit_id = OLD.samplingvisit_id
   AND samplingvisit_id IS NOT NULL
;

DROP RULE IF EXISTS FieldWork_upd_POSITIONING ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_POSITIONING AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."PositioningVisits"
 SET
  require_total_station = NEW.require_total_station
 WHERE positioningvisit_id = OLD.positioningvisit_id
   AND positioningvisit_id IS NOT NULL
;

GRANT SELECT ON  "inbound"."FieldWork"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  user_gwdb;



DROP VIEW IF EXISTS  "inbound"."MyFieldWork" ;
CREATE VIEW "inbound"."MyFieldWork" AS
SELECT * FROM "inbound"."FieldWork"
WHERE teammember_assigned IN (
  SELECT DISTINCT teammember_id
  FROM "metadata"."TeamMembers"
  WHERE username = 'all_groundwater'
    OR LOWER(username) = LOWER(current_user)
) OR visit_done;



GRANT SELECT ON  "inbound"."MyFieldWork"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  user_gwdb;


COMMIT;
