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
  INFO.recovery_hints,
  INFO.landowner,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  FAGS.activity_group,
  FAGS.is_field_activity,
  FAGS.is_surf_activity,
  FAGS.protocols,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  VISIT.lenticvisit_id,
  VISIT.loticvisit_id,
  (VISIT.lenticvisit_id IS NOT NULL) AS show_lenticvisits,
  (VISIT.loticvisit_id IS NOT NULL) AS show_loticvisits,
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
  FROM "outbound"."FieldCalendar"
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



-- ON HOLD

DROP RULE IF EXISTS FieldWork_upd_INSTALLATION ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd_INSTALLATION AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."InstallationVisits"
 SET
  photo_installation = NEW.photo_installation,
 WHERE installationvisit_id = OLD.installationvisit_id
   AND installationvisit_id IS NOT NULL
;
