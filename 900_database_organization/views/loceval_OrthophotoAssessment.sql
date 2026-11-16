BEGIN;

ALTER TABLE "outbound"."LocationAssessments"
RENAME TO "OrthophotoEvaluations";

ALTER TABLE "outbound"."OrthophotoEvaluations"
RENAME locationassessment_id TO orthophotoevaluation_id;

-- update views: OrthophotoAssessment, LocationAssessments and gwTransfer
DROP VIEW IF EXISTS  "outbound"."LocationAssessments" ;
CREATE VIEW  "outbound"."LocationAssessments"  AS
  SELECT  orthophotoevaluation_id AS locationassessment_id, *
  FROM  "outbound"."OrthophotoEvaluations";
GRANT SELECT ON  "outbound"."LocationAssessments"  TO viewer_mnmdb;
GRANT UPDATE ON  "outbound"."LocationAssessments"  TO user_loceval;


DROP TRIGGER IF EXISTS log_orthophotoevaluations ON "outbound"."OrthophotoEvaluations";
CREATE TRIGGER log_orthophotoevaluations
BEFORE UPDATE ON "outbound"."OrthophotoEvaluations"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

COMMIT;


BEGIN;

DROP VIEW IF EXISTS  "outbound"."OrthophotoAssessment" CASCADE;
CREATE VIEW  "outbound"."OrthophotoAssessment"  AS
SELECT
  LOC.*,
  UNIT.type,
  UNIT.grts_join_method,
  UNIT.schemes,
  UNIT.scheme_ps_targetpanels_served AS scheme_ps_targetpanels,
  UNIT.domain_part,
  UNIT.is_forest,
  UNIT.in_mhq_samples,
  UNIT.has_mhq_assessment AS assessment,
  UNIT.mhq_assessment_date AS assessment_date,
  (UNIT.archive_version_id IS NOT NULL) AS sample_unit_obsolete,
  LOCASS.orthophotoevaluation_id,
  LOCASS.cell_disapproved,
  LOCASS.revisit_disapproval,
  LOCASS.disapproval_explanation,
  LOCASS.type_suggested,
  LOCASS.implications_habitatmap,
  LOCASS.feedback_habitatmap,
  LOCASS.notes,
  LOCASS.assessment_done
FROM "outbound"."OrthophotoEvaluations" AS LOCASS
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON LOCASS.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
;


DROP RULE IF EXISTS OrthophotoAssessment_upd ON "outbound"."OrthophotoAssessment";
CREATE RULE OrthophotoAssessment_upd AS
ON UPDATE TO "outbound"."OrthophotoAssessment"
DO INSTEAD
 UPDATE "outbound"."OrthophotoEvaluations"
 SET
  type_suggested = NEW.type_suggested,
  cell_disapproved = NEW.cell_disapproved,
  revisit_disapproval = NEW.revisit_disapproval,
  disapproval_explanation = NEW.disapproval_explanation,
  implications_habitatmap = NEW.implications_habitatmap,
  feedback_habitatmap = NEW.feedback_habitatmap,
  notes = NEW.notes,
  assessment_done = NEW.assessment_done
 WHERE orthophotoevaluation_id = OLD.orthophotoevaluation_id
;


GRANT SELECT ON  "outbound"."OrthophotoAssessment"  TO viewer_mnmdb;
GRANT UPDATE ON  "outbound"."OrthophotoAssessment"  TO user_loceval;

COMMIT;
