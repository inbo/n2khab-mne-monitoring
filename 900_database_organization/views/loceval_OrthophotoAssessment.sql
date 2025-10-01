DROP VIEW IF EXISTS  "outbound"."OrthophotoAssessment" ;
CREATE VIEW  "outbound"."OrthophotoAssessment"  AS
SELECT
  LOC.*,
  LOCASS.locationassessment_id,
  (UNIT.location_id IS NULL) AS sample_location_obsolete,
  UNIT.grts_join_method,
  UNIT.schemes,
  UNIT.scheme_ps_targetpanels,
  UNIT.has_mhq_assessment AS assessment,
  UNIT.mhq_assessment_date AS assessment_date,
  LOCASS.type,
  LOCASS.cell_disapproved,
  LOCASS.revisit_disapproval,
  LOCASS.disapproval_explanation,
  LOCASS.type_suggested,
  LOCASS.implications_habitatmap,
  LOCASS.feedback_habitatmap,
  LOCASS.notes,
  LOCASS.assessment_done
FROM "outbound"."LocationAssessments" AS LOCASS
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = LOCASS.location_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON (LOCASS.grts_address = UNIT.grts_address
  -- AND LOCASS.type = UNIT.type
     )
  WHERE UNIT.location_id IS NOT NULL
;


DROP RULE IF EXISTS OrthophotoAssessment_upd ON "outbound"."OrthophotoAssessment";
CREATE RULE OrthophotoAssessment_upd AS
ON UPDATE TO "outbound"."OrthophotoAssessment"
DO INSTEAD
 UPDATE "outbound"."LocationAssessments"
 SET
  type_suggested = NEW.type_suggested,
  cell_disapproved = NEW.cell_disapproved,
  revisit_disapproval = NEW.revisit_disapproval,
  disapproval_explanation = NEW.disapproval_explanation,
  implications_habitatmap = NEW.implications_habitatmap,
  feedback_habitatmap = NEW.feedback_habitatmap,
  notes = NEW.notes,
  assessment_done = NEW.assessment_done
 WHERE locationassessment_id = OLD.locationassessment_id
;


GRANT SELECT ON  "outbound"."OrthophotoAssessment"  TO ward, karen, floris;
GRANT UPDATE ON  "outbound"."OrthophotoAssessment"  TO ward, karen, floris;
