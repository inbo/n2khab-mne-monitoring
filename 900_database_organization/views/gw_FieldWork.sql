-- SELECT DISTINCT visit_id, count(*) AS n FROM "inbound"."FieldWork" GROUP BY visit_id ORDER BY n DESC;

-- !!! also re-create update MyFieldWork

DROP VIEW IF EXISTS  "inbound"."FieldWork" CASCADE;
CREATE VIEW "inbound"."FieldWork" AS
SELECT
  LOC.*,
  FwCAL.teammember_assigned,
  FwCAL.activity_rank,
  CASE WHEN (FwCAL.date_visit_planned IS NULL) THEN FALSE ELSE TRUE END AS is_scheduled,
  FwCAL.date_visit_planned,
  FwCAL.date_visit_planned - current_date AS days_to_visit,
  FwCAL.date_end - current_date AS days_to_deadline,
  FwCAL.notes AS preparation_notes,
  SLOC.strata AS type,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.recovery_hints,
  INFO.landowner,
  INFO.watina_code_1,
  INFO.watina_code_2,
  LOCEVAL.loceval_photo,
  GAP.activity_group_id,
  GAP.is_field_activity,
  GAP.is_gw_activity,
  GAP.protocols,
  COALESCE( WIA.fieldwork_id, CSA.fieldwork_id) AS fieldwork_id,
  CASE WHEN WIA.is_installation IS NULL THEN FALSE ELSE WIA.is_installation END AS show_installation,
  CASE WHEN CSA.is_sampling IS NULL THEN FALSE ELSE CSA.is_sampling END AS show_sampling,
  WIA.photo_soil_1_peilbuis,
  WIA.photo_soil_2_piezometer,
  WIA.photo_well,
  WIA.watina_code_used_1_peilbuis,
  WIA.watina_code_used_2_piezometer,
  WIA.soilprofile_notes,
  WIA.soilprofile_unclear,
  WIA.no_diver,
  WIA.random_point_number,
  WIA.diver_id,
  WIA.free_diver,
<<<<<<< HEAD
  WIA.reused_existing_well,
  WIA.reused_with_replacement,
=======
  WIA.reused_well_reference,
>>>>>>> 799abfc (dbinit: fieldwork ++re-use)
  WIA.used_water_from_tap,
  WIA.used_water_source,
  CSA.project_code,
  CSA.recipient_code,
  VISIT.visit_done
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.location_id = VISIT.location_id
LEFT JOIN "outbound"."FieldworkCalendar" AS FwCAL
  ON FwCAL.fieldworkcalendar_id = VISIT.fieldworkcalendar_id
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FwCAL.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN (
  SELECT DISTINCT
    activity_group_id,
    activity_group,
    is_field_activity,
    is_gw_activity,
    string_agg(DISTINCT('' || protocol_code || '/v' || protocol_version), E',') AS protocols
  FROM "metadata"."GroupedActivities" AS GACT
  LEFT JOIN "metadata"."Protocols" AS PRT
    ON PRT.protocol_id = GACT.protocol_id
  GROUP BY
    activity_group_id,
    activity_group,
    is_field_activity,
    is_gw_activity
  ) AS GAP
  ON GAP.activity_group_id = VISIT.activity_group_id
LEFT JOIN (
  SELECT *, TRUE AS is_installation
  FROM "inbound"."WellInstallationActivities"
) AS WIA
  ON VISIT.visit_id = WIA.visit_id
LEFT JOIN (
  SELECT *, TRUE AS is_sampling
  FROM "inbound"."ChemicalSamplingActivities"
) AS CSA
  ON VISIT.visit_id = CSA.visit_id
LEFT JOIN (
  SELECT samplelocation_id, loceval_photo
  FROM (
    SELECT DISTINCT
      samplelocation_id,
      MAX(eval_date) AS latest_visit,
      eval_date,
      photo AS loceval_photo
    FROM "outbound"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY samplelocation_id, eval_date, photo
  ) WHERE eval_date = latest_visit AND loceval_photo IS NOT NULL
) AS LOCEVAL
  ON SLOC.samplelocation_id = LOCEVAL.samplelocation_id
WHERE TRUE
  AND ((FwCAL.no_visit_planned IS NULL) OR (NOT FwCAL.no_visit_planned))
  AND NOT FwCAL.excluded
  AND GAP.is_gw_activity
  AND (VISIT.visit_done OR (FwCAL.archive_version_id IS NULL))
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
  recovery_hints = NEW.recovery_hints
 WHERE locationinfo_id = OLD.locationinfo_id
;

DROP RULE IF EXISTS FieldWork_upd_WIA ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_WIA AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."WellInstallationActivities"
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
<<<<<<< HEAD
  reused_existing_well = NEW.reused_existing_well,
  reused_with_replacement = NEW.reused_with_replacement,
=======
  reused_well_reference = NEW.reused_well_reference,
>>>>>>> 799abfc (dbinit: fieldwork ++re-use)
  used_water_from_tap = NEW.used_water_from_tap,
  used_water_source = NEW.used_water_source
 WHERE fieldwork_id = OLD.fieldwork_id
;

DROP RULE IF EXISTS FieldWork_upd_CSA ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_CSA AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."ChemicalSamplingActivities"
 SET
  project_code = NEW.project_code,
  recipient_code = NEW.recipient_code
 WHERE fieldwork_id = OLD.fieldwork_id
;


GRANT SELECT ON  "inbound"."FieldWork"  TO  tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  tom, yglinga, jens, lise, wouter, floris, karen, falk;

GRANT SELECT ON  "inbound"."FieldWork"  TO  tester;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  tester;
