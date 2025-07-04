DROP VIEW IF EXISTS  "inbound"."LocationEvaluation" ;
CREATE VIEW "inbound"."LocationEvaluation" AS
SELECT
  LOC.*,
  EVI.extravisit_id,
  EVI.grouped_activity_id,
  EVI.teammember_id,
  EVI.date_visit,
  EVI.type_assessed,
  EVI.notes,
  EVI.photo,
  EVI.visit_done,
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
  LOCASS.notes AS location_assessment
FROM "inbound"."ExtraVisits" AS EVI
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = EVI.location_id
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON EVI.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN (
  SELECT
    location_id,
    cell_disapproved,
    assessment_done,
    notes
  FROM "outbound"."LocationAssessments"
  ) AS LOCASS
  ON EVI.location_id = LOCASS.location_id
WHERE TRUE
  AND LOCASS.assessment_done
  AND NOT LOCASS.cell_disapproved
;


DROP RULE IF EXISTS LocationEvaluation_upd ON "inbound"."LocationEvaluation";
CREATE RULE LocationEvaluation_upd AS
ON UPDATE TO "inbound"."LocationEvaluation"
DO INSTEAD
 UPDATE "inbound"."ExtraVisits"
 SET
  grouped_activity_id = NEW.grouped_activity_id,
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  type_assessed = NEW.type_assessed,
  notes = NEW.notes,
  photo = NEW.photo,
  visit_done = NEW.visit_done
 WHERE extravisit_id = OLD.extravisit_id
;
