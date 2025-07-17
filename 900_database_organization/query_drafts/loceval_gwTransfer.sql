DROP VIEW IF EXISTS  "outbound"."gwTransfer" ;
CREATE VIEW "outbound"."gwTransfer" AS
SELECT
  VISIT.log_user,
  VISIT.log_update,
  UNIT.scheme,
  UNIT.panel_set,
  UNIT.targetpanel,
  UNIT.type,
  UNIT.grts_address,
  VISIT.type_assessed,
  'loceval' AS eval_source,
  LOWER(TEAM.username) AS eval_name,
  VISIT.date_visit AS eval_date,
  VISIT.visit_id AS eval_id,
  VISIT.notes,
  VISIT.photo,
  UNIT.recovery_hints
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."TeamMembers" AS TEAM
  ON TEAM.teammember_id = VISIT.teammember_id
WHERE TRUE
  AND (VISIT.visit_done)
UNION
SELECT
  LOCASS.log_user,
  LOCASS.log_update,
  UNIT.scheme,
  UNIT.panel_set,
  UNIT.targetpanel,
  UNIT.type,
  UNIT.grts_address,
  LOCASS.type_suggested AS type_assessed,
  'orthophotos' AS eval_source,
  LOWER(LOCASS.log_user) AS eval_name,
  CAST(LOCASS.log_update AS DATE) AS eval_date,
  LOCASS.locationassessment_id AS eval_id,
  LOCASS.notes,
  NULL AS photo,
  NULL AS recovery_hints
FROM "outbound"."LocationAssessments" AS LOCASS
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON (LOCASS.grts_address = UNIT.grts_address
     AND LOCASS.type = UNIT.type)
WHERE TRUE
  AND (LOCASS.assessment_done)
  AND (UNIT.location_id IS NOT NULL)
;


GRANT SELECT ON  "outbound"."gwTransfer"  TO  monkey;
