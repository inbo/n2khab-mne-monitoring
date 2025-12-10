DROP VIEW IF EXISTS  "outbound"."FieldPreparation" ;
CREATE VIEW "outbound"."FieldPreparation" AS
SELECT
  LOC.*,
  FAC.fieldactivitycalendar_id,
  FAC.sampleunit_id,
  FAC.activity_group_id,
  FAC.activity_rank,
  FAC.priority,
  FAC.date_start,
  FAC.date_end,
  FAC.wait_watersurface,
  FAC.wait_3260,
  FAC.wait_7220,
  FAC.excluded,
  FAC.excluded_reason,
  FAC.landowner,
  FAC.inaccessible,
  FAC.acceccibility_revisit,
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
  UNIT.is_replaced,
  LOCASS.cell_disapproved,
  LOCASS.assessment_done
FROM "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = FAC.location_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON FAC.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN (
  SELECT
    location_id,
    cell_disapproved,
    assessment_done
  FROM "outbound"."LocationAssessments"
  ) AS LOCASS
  ON FAC.location_id = LOCASS.location_id
;


DROP RULE IF EXISTS FieldPreparation_upd ON "outbound"."FieldPreparation";
CREATE RULE FieldPreparation_upd AS
ON UPDATE TO "outbound"."FieldPreparation"
DO INSTEAD
 UPDATE "outbound"."FieldActivityCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  landowner = NEW.landowner,
  inaccessible = NEW.inaccessible,
  acceccibility_revisit = NEW.acceccibility_revisit,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldactivitycalendar_id = OLD.fieldactivitycalendar_id
;
