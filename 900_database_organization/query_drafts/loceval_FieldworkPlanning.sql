
SELECT *
  FROM "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON FAC.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN (
  SELECT DISTINCT
    location_id,
    cell_disapproved,
    assessment_done
  FROM "outbound"."LocationAssessments"
  GROUP BY
    location_id,
    cell_disapproved,
    assessment_done
  ) AS LOCASS
  ON UNIT.location_id = LOCASS.location_id
WHERE done_planning
;

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" ;
CREATE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  FAC.fieldactivitycalendar_id,
  FAC.sampleunit_id,
  FAC.activity_group_id,
  FAC.activity_group_id IN (
    SELECT DISTINCT activity_group_id FROM "metadata"."GroupedActivities"
    WHERE is_loceval_activity
  ) AS is_loceval_activity,
  FAC.activity_rank,
  FAC.priority,
  FAC.date_start,
  FAC.date_end,
  FAC.date_interval,
  FAC.date_end - current_date AS days_to_deadline,
  FAC.wait_watersurface,
  FAC.wait_3260,
  FAC.wait_7220,
  (FAC.wait_watersurface OR FAC.wait_3260 OR FAC.wait_7220) AS is_waiting,
  FAC.excluded,
  FAC.excluded_reason,
  INFO.landowner,
  FAC.teammember_assigned,
  FAC.date_visit_planned,
  FAC.no_visit_planned,
  FAC.notes,
  FAC.done_planning,
  UNIT.grts_join_method,
  UNIT.scheme,
  UNIT.panel_set,
  UNIT.targetpanel,
  UNIT.scheme_ps_targetpanels,
  UNIT.sp_poststratum,
  UNIT.type,
  UNIT.assessment,
  UNIT.assessment_date,
  UNIT.previous_notes,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.recovery_hints,
  UNIT.is_replaced,
  LOCASS.cell_disapproved,
  LOCASS.assessment_done
FROM "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON FAC.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.location_id = UNIT.location_id
LEFT JOIN (
  SELECT DISTINCT
    location_id,
    cell_disapproved,
    assessment_done
  FROM "outbound"."LocationAssessments"
  GROUP BY
    location_id,
    cell_disapproved,
    assessment_done
  ) AS LOCASS
  ON UNIT.location_id = LOCASS.location_id
ORDER BY
  FAC.date_end,
  FAC.priority,
  is_waiting,
  FAC.stratum,
  FAC.grts_address,
  FAC.activity_rank,
  FAC.activity_group_id
;


DROP RULE IF EXISTS FieldworkPlanning_upd0 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd0 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD NOTHING
;


DROP RULE IF EXISTS FieldworkPlanning_upd1 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd1 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."FieldActivityCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldactivitycalendar_id = OLD.fieldactivitycalendar_id
;


DROP RULE IF EXISTS FieldworkPlanning_upd2 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd2 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit,
  landowner = NEW.landowner,
  recovery_hints = NEW.recovery_hints
 WHERE locationinfo_id = OLD.locationinfo_id
;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO ward;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO karen;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO floris;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO ward;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO karen;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO floris;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO tom;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO tom;
