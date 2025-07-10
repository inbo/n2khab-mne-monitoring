DROP VIEW IF EXISTS  "inbound"."LocationEvaluation" ;
CREATE VIEW "inbound"."LocationEvaluation" AS
SELECT
  LOC.*,
  EVI.extravisit_id,
  EVI.teammember_id,
  EVI.date_visit,
  EVI.type_assessed,
  EVI.notes,
  EVI.photo,
  EVI.visit_done,
  SLOC.samplelocation_id,
  SLOC.grts_join_method,
  SLOC.scheme,
  SLOC.panel_set,
  SLOC.targetpanel,
  SLOC.scheme_ps_targetpanels,
  SLOC.sp_poststratum,
  SLOC.type,
  SLOC.assessment,
  SLOC.assessment_date,
  SLOC.is_replaced,
  SLOC.replacement_ongoing,
  SLOC.replacement_reason,
  SLOC.replacement_permanence,
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
FROM "inbound"."ExtraVisits" AS EVI
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = EVI.location_id
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON EVI.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN (
  SELECT
    samplelocation_id,
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
  ON (FAC.samplelocation_id = SLOC.samplelocation_id)
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
  ON EVI.location_id = LOCASS.location_id
WHERE TRUE
  AND ((LOCASS.cell_disapproved IS NULL) OR (NOT LOCASS.cell_disapproved))
  AND ((FAC.no_visit_planned IS NULL) OR (NOT FAC.no_visit_planned))
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
 UPDATE "inbound"."ExtraVisits"
 SET
  -- grouped_activity_id = NEW.grouped_activity_id,
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  type_assessed = NEW.type_assessed,
  notes = NEW.notes,
  photo = NEW.photo,
  visit_done = NEW.visit_done
 WHERE extravisit_id = OLD.extravisit_id
;

DROP RULE IF EXISTS LocationEvaluation_upd2 ON "inbound"."LocationEvaluation";
CREATE RULE LocationEvaluation_upd2 AS
ON UPDATE TO "inbound"."LocationEvaluation"
DO ALSO
 UPDATE "outbound"."SampleLocations"
 SET
  is_replaced = NEW.is_replaced,
  replacement_ongoing = NEW.replacement_ongoing,
  replacement_reason = NEW.replacement_reason,
  replacement_permanence = NEW.replacement_permanence
 WHERE samplelocation_id = OLD.samplelocation_id
;



GRANT SELECT ON  "inbound"."LocationEvaluation"  TO ward;
GRANT SELECT ON  "inbound"."LocationEvaluation"  TO karen;
GRANT SELECT ON  "inbound"."LocationEvaluation"  TO floris;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO ward;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO karen;
GRANT UPDATE ON  "inbound"."LocationEvaluation"  TO floris;
