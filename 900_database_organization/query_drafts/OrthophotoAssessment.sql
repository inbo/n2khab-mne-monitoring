DROP VIEW IF EXISTS  "outbound"."OrthophotoAssessment" ;
CREATE VIEW  "outbound"."OrthophotoAssessment"  AS
SELECT
  LOC.*,
  LOCASS.locationassessment_id,
  SLOC.loceval_year,
  SLOC.priority_orthophoto,
  (SLOC.location_id IS NULL) AS sample_location_obsolete,
  SLOC.grts_join_method,
  SLOC.sp_poststratum,
  SLOC.scheme_ps_targetpanels,
  SLOC.type,
  SLOC.previous_assessment,
  SLOC.previous_assessment_date,
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
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON (LOCASS.type = SLOC.type
     AND LOCASS.grts_address = SLOC.grts_address
     AND LOCASS.location_id = SLOC.location_id
     )
;


DROP RULE IF EXISTS OrthophotoAssessment_upd ON "outbound"."OrthophotoAssessment";
CREATE RULE OrthophotoAssessment_upd AS
ON UPDATE TO "outbound"."OrthophotoAssessment"
DO INSTEAD
 UPDATE "outbound"."LocationAssessments"
 SET
  type_adjusted = NEW.type_adjusted,
  cell_disapproved = NEW.cell_disapproved,
  revisit_disapproval = NEW.revisit_disapproval,
  disapproval_explanation = NEW.disapproval_explanation,
  implications_habitatmap = NEW.implications_habitatmap,
  feedback_habitatmap = NEW.feedback_habitatmap,
  notes = NEW.notes,
  assessment_done = NEW.assessment_done
 WHERE locationassessment_id = OLD.locationassessment_id
;


GRANT SELECT ON  "outbound"."OrthophotoAssessment"  TO ward;
GRANT UPDATE ON  "outbound"."OrthophotoAssessment"  TO ward;

