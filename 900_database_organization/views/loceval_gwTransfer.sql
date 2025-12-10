DROP VIEW IF EXISTS  "outbound"."gwTransfer" ;
CREATE VIEW "outbound"."gwTransfer" AS
SELECT
  VISIT.log_user,
  VISIT.log_update,
  UNIT.schemes,
  UNIT.type,
  UNIT.grts_address AS grts_address_original,
  CASE WHEN LOREP.grts_address_replacement IS NULL
    THEN UNIT.grts_address
    ELSE LOREP.grts_address_replacement
    END AS grts_address,
  VISIT.type_assessed,
  UNIT.type_is_absent,
  'loceval' AS eval_source,
  LOWER(TEAM.username) AS eval_name,
  VISIT.date_visit AS eval_date,
  VISIT.visit_id AS eval_id,
  VISIT.notes || '|' || LOREP.replacement_notes AS notes,
  VISIT.photo
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."TeamMembers" AS TEAM
  ON TEAM.teammember_id = VISIT.teammember_id
LEFT JOIN (
  SELECT
    sampleunit_id,
    grts_address_replacement,
    notes AS replacement_notes
  FROM "outbound"."Replacements"
  WHERE is_selected
  ) AS LOREP
  ON UNIT.sampleunit_id = LOREP.sampleunit_id
WHERE TRUE
  AND VISIT.visit_done
UNION
SELECT
  LOCASS.log_user,
  LOCASS.log_update,
  UNIT.schemes,
  UNIT.type,
  UNIT.grts_address AS grts_address_original,
  CASE WHEN LOREP.grts_address_replacement IS NULL
    THEN UNIT.grts_address
    ELSE LOREP.grts_address_replacement
    END AS grts_address,
  LOCASS.type_suggested AS type_assessed,
  UNIT.type_is_absent,
  'orthophotos' AS eval_source,
  LOWER(LOCASS.log_user) AS eval_name,
  CAST(LOCASS.log_update AS DATE) AS eval_date,
  LOCASS.locationassessment_id AS eval_id,
  LOCASS.notes,
  NULL AS photo
FROM "outbound"."LocationAssessments" AS LOCASS
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON (LOCASS.grts_address = UNIT.grts_address
     AND LOCASS.type = UNIT.type)
LEFT JOIN (
  SELECT
    sampleunit_id,
    grts_address_replacement,
    notes AS replacement_notes
  FROM "outbound"."Replacements"
  WHERE is_selected
  ) AS LOREP
  ON UNIT.sampleunit_id = LOREP.sampleunit_id
WHERE TRUE
  AND LOCASS.assessment_done
  AND (UNIT.location_id IS NOT NULL)
;


GRANT SELECT ON  "outbound"."gwTransfer"  TO  monkey;

-- GRANT SELECT ON  "outbound"."gwTransfer"  TO  yoda;

