DROP VIEW IF EXISTS  "inbound"."LocationEvaluation" ;
CREATE VIEW "inbound"."LocationEvaluation" AS
SELECT
  LOC.*,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.type_assessed,
  VISIT.notes,
  VISIT.photo,
  VISIT.visit_done,
  UNIT.sampleunit_id,
  UNIT.grts_join_method,
  UNIT.scheme,
  UNIT.panel_set,
  UNIT.targetpanel,
  UNIT.scheme_ps_targetpanels,
  UNIT.sp_poststratum,
  UNIT.type,
  UNIT.assessment,
  UNIT.assessment_date,
  UNIT.recovery_hints,
  UNIT.is_replaced,
  UNIT.replacement_ongoing,
  UNIT.replacement_reason,
  UNIT.replacement_permanence,
  LOCASS.assessment_done,
  LOCASS.cell_disapproved,
  LOCASS.notes AS location_assessment,
  CASE WHEN (FAC.date_visit_planned IS NULL) THEN FALSE ELSE TRUE END AS is_scheduled,
  FAC.teammember_assigned,
  FAC.activity_group_id,
  FAC.date_visit_planned,
  FAC.date_visit_planned - current_date AS days_to_visit,
  FAC.date_end - current_date AS days_to_deadline,
  FAC.priority,
  FAC.notes AS preparation_notes
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN (
  SELECT
    sampleunit_id,
    activity_group_id,
    date_start,
    date_end,
    priority,
    landowner,
    teammember_assigned,
    date_visit_planned,
    no_visit_planned,
    notes
  FROM "outbound"."FieldActivityCalendar" AS CAL
  ) AS FAC
  ON (FAC.sampleunit_id = UNIT.sampleunit_id)
LEFT JOIN (
  SELECT DISTINCT
    location_id,
    cell_disapproved,
    assessment_done,
    notes
  FROM "outbound"."LocationAssessments"
  GROUP BY
    location_id,
    cell_disapproved,
    assessment_done,
    notes
  ) AS LOCASS
  ON VISIT.location_id = LOCASS.location_id
WHERE TRUE
  AND ((LOCASS.cell_disapproved IS NULL) OR (NOT LOCASS.cell_disapproved))
  AND ((FAC.no_visit_planned IS NULL) OR (NOT FAC.no_visit_planned))
  AND (FAC.activity_group_id IN
  (SELECT DISTINCT activity_group_id FROM "metadata"."GroupedActivities"
  WHERE is_loceval_activity)
  )
;


-- https://stackoverflow.com/q/44005446

DROP RULE IF EXISTS LocationEvaluation_upd0 ON "inbound"."LocationEvaluation";
CREATE RULE LocationEvaluation_upd0 AS
ON UPDATE TO "inbound"."LocationEvaluation"
DO INSTEAD NOTHING
;


DROP RULE IF EXISTS LocationEvaluation_upd1 ON "inbound"."LocationEvaluation";
CREATE RULE LocationEvaluation_upd1 AS
ON UPDATE TO "inbound"."LocationEvaluation"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  type_assessed = NEW.type_assessed,
  notes = NEW.notes,
  photo = NEW.photo,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;

DROP RULE IF EXISTS LocationEvaluation_upd2 ON "inbound"."LocationEvaluation";
CREATE RULE LocationEvaluation_upd2 AS
ON UPDATE TO "inbound"."LocationEvaluation"
DO ALSO
 UPDATE "outbound"."SampleUnits"
 SET
  is_replaced = NEW.is_replaced,
  replacement_ongoing = NEW.replacement_ongoing,
  replacement_reason = NEW.replacement_reason,
  replacement_permanence = NEW.replacement_permanence
 WHERE sampleunit_id = OLD.sampleunit_id
;



GRANT SELECT ON  "inbound"."LocationEvaluation"  TO floris;
GRANT SELECT ON  "inbound"."LocationEvaluation"  TO karen;
GRANT SELECT ON  "inbound"."LocationEvaluation"  TO tom;
GRANT SELECT ON  "inbound"."LocationEvaluation"  TO ward;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO floris;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO karen;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO tom;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO ward;
