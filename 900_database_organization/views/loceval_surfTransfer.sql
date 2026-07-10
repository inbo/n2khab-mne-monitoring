
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
  VISIT.type_assessed,
  UNIT.type_is_absent,
  TEAM.given_name AS eval_name,
  VISIT.date_visit AS eval_date,
  VISIT.visit_id AS eval_id,
  VISIT.notes,
  VISIT.photo
FROM "inbound"."AquaticTypesVisits" AS VISIT
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON UNIT.location_id = LOC.location_id
LEFT JOIN "metadata"."TeamMembers" AS TEAM
  ON TEAM.teammember_id = VISIT.teammember_id
WHERE TRUE
  AND VISIT.visit_done
;


GRANT SELECT ON  "outbound"."surfTransfer"  TO  reporter_mnmdb, viewer_mnmdb;
