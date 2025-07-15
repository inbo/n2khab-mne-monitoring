



DROP VIEW IF EXISTS  "inbound"."FieldWork" ;
CREATE VIEW "inbound"."FieldWork" AS
SELECT
  LOC.*,
  FACAL.teammember_assigned,
  FACAL.activity_rank,
  CASE WHEN (FACAL.date_visit_planned IS NULL) THEN FALSE ELSE TRUE END AS is_scheduled,
  FACAL.date_visit_planned,
  FACAL.date_visit_planned - current_date AS days_to_visit,
  FACAL.date_end - current_date AS days_to_deadline,
  FACAL.landowner,
  FACAL.watina_code,
  FACAL.notes AS preparation_notes,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.notes,
  VISIT.photo,
  VISIT.lims_code,
  VISIT.visit_cancelled,
  VISIT.visit_done,
  GAP.activity_group_id,
  GAP.is_field_activity,
  GAP.is_gw_activity,
  GAP.protocols
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."FieldActivityCalendar" AS FACAL
  ON FACAL.fieldactivitycalendar_id = VISIT.fieldactivitycalendar_id
LEFT JOIN (
  SELECT DISTINCT
    activity_group_id,
    activity_group,
    is_field_activity,
    is_gw_activity,
    string_agg('' || protocol, E',') AS protocols
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
WHERE TRUE
  AND ((FACAL.no_visit_planned IS NULL) OR (NOT FACAL.no_visit_planned))
  AND NOT FACAL.excluded
  AND GAP.is_gw_activity
;


-- https://stackoverflow.com/q/44005446

DROP RULE IF EXISTS FieldWork_upd0 ON "inbound"."FieldWork";
CREATE RULE FieldWork_upd0 AS
ON UPDATE TO "inbound"."FieldWork"
DO INSTEAD
 UPDATE "inbound"."Visits"
 SET
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  notes = NEW.notes,
  photo = NEW.photo,
  lims_code = NEW.lims_code,
  visit_cancelled = NEW.visit_cancelled,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;


GRANT SELECT ON  "inbound"."FieldWork"  TO  tom;
GRANT SELECT ON  "inbound"."FieldWork"  TO  yglinga;
GRANT SELECT ON  "inbound"."FieldWork"  TO  jens;
GRANT SELECT ON  "inbound"."FieldWork"  TO  lise;
GRANT SELECT ON  "inbound"."FieldWork"  TO  wouter;
GRANT SELECT ON  "inbound"."FieldWork"  TO  floris;
GRANT SELECT ON  "inbound"."FieldWork"  TO  karen;
GRANT SELECT ON  "inbound"."FieldWork"  TO  tester;
GRANT SELECT ON  "inbound"."FieldWork"  TO  ward;
GRANT SELECT ON  "inbound"."FieldWork"  TO  monkey;

GRANT UPDATE ON  "inbound"."FieldWork"  TO  tom;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  yglinga;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  jens;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  lise;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  wouter;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  floris;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  karen;
GRANT UPDATE ON  "inbound"."FieldWork"  TO  tester;
