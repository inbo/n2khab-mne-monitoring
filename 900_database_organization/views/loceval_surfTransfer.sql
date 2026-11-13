BEGIN;

DROP VIEW IF EXISTS  "outbound"."surfTransfer" ;
CREATE VIEW "outbound"."surfTransfer" AS
SELECT
  LOC.*,
  VISIT.log_user,
  VISIT.log_update,
  UNIT.schemes,
  UNIT.type,
  UNIT.grts_address AS grts_address_original,
  VISIT.date_start,
  VISIT.activity_group_id,
  ACT.activity_group,
  VISIT.type_assessed,
  UNIT.type_is_absent,
  'loceval' AS eval_source,
  TEAM.given_name AS eval_name,
  VISIT.date_visit AS eval_date,
  VISIT.visit_id AS eval_id,
  VISIT.notes,
  VISIT.photo
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON UNIT.location_id = LOC.location_id
LEFT JOIN "metadata"."TeamMembers" AS TEAM
  ON TEAM.teammember_id = VISIT.teammember_id
LEFT JOIN "metadata"."ActivityGroups" AS ACT
  ON ACT.activity_group_id = VISIT.activity_group_id
WHERE TRUE
  AND VISIT.visit_done
  AND (
    (ACT.activity_group = 'LOCEVALAQ')
    OR (UNIT.schemes LIKE 'SURF%' OR UNIT.schemes LIKE '%SURF%')
  )
  AND (ACT.activity_group NOT LIKE '%SAMPLPOINT')
;


GRANT SELECT ON  "outbound"."surfTransfer"  TO  reporter_mnmdb, viewer_mnmdb;

COMMIT;

-- SELECT count(*) FROM "outbound"."surfTransfer";

-- SELECT DISTINCT grts_address, type, date_start, MIN(eval_date), MAX(eval_date), count(*) AS n
-- FROM "outbound"."surfTransfer"
-- WHERE eval_source = 'loceval'
-- GROUP BY grts_address, type, date_start
-- HAVING count(*) > 1
-- ;
