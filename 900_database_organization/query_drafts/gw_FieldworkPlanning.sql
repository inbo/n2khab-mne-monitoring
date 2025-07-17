DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" ;
CREATE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  SLOC.scheme_ps_targetpanels,
  SSPSTP.stratum_scheme_ps_targetpanels,
  SLOC.schemes,
  SLOC.strata,
  SLOC.accessibility_inaccessible,
  SLOC.accessibility_revisit,
  FWCAL.fieldworkcalendar_id,
  FWCAL.samplelocation_id,
  FWCAL.date_start,
  FWCAL.date_end,
  FWCAL.date_interval,
  FWCAL.date_end - current_date AS days_to_deadline,
  FWCAL.activity_group_id,
  FWCAL.activity_group_id IN (
    SELECT DISTINCT activity_group_id FROM "metadata"."GroupedActivities"
    WHERE is_gw_activity
  ) AS is_gw_activity,
  FWCAL.activity_rank,
  FWCAL.priority,
  FWCAL.wait_watersurface,
  FWCAL.wait_3260,
  FWCAL.wait_7220,
  (FWCAL.wait_watersurface OR FWCAL.wait_3260 OR FWCAL.wait_7220) AS is_waiting,
  FWCAL.excluded,
  FWCAL.excluded_reason,
  FWCAL.landowner,
  FWCAL.teammember_assigned,
  FWCAL.date_visit_planned,
  FWCAL.no_visit_planned,
  FWCAL.watina_code,
  FWCAL.notes,
  FWCAL.done_planning,
  LOCEVAL.has_loceval,
  LOCEVAL.latest_visit
FROM "outbound"."FieldworkCalendar" AS FWCAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FWCAL.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN "metadata"."SSPSTaPas" AS SSPSTP
  ON SSPSTP.sspstapa_id = FWCAL.sspstapa_id
LEFT JOIN (
    SELECT DISTINCT
      samplelocation_id,
      eval_source,
      MAX(eval_date) AS latest_visit,
      TRUE AS has_loceval
    FROM "outbound"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY samplelocation_id, eval_source
  ) AS LOCEVAL
    ON SLOC.samplelocation_id = LOCEVAL.samplelocation_id
ORDER BY
  FWCAL.date_end,
  FWCAL.priority,
  is_waiting,
  SLOC.strata,
  FWCAL.grts_address,
  FWCAL.activity_rank,
  FWCAL.activity_group_id
;


DROP RULE IF EXISTS FieldworkPlanning_upd ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD
 UPDATE "outbound"."FieldworkCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  landowner = NEW.landowner,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  watina_code = NEW.watina_code,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldworkcalendar_id = OLD.fieldworkcalendar_id
;



GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tom;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  yglinga;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  jens;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  lise;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  wouter;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  floris;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  karen;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  ward;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  monkey;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tom;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  floris;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  karen;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester;
