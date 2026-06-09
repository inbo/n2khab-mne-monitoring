
DROP VIEW IF EXISTS  "outbound"."LocevalInfo" ;
CREATE OR REPLACE VIEW "outbound"."LocevalInfo" AS
SELECT
  LOC.*,
  LOCEVAL.locationevaluation_id,
  LOCEVAL.schemes,
  LOCEVAL.type,
  LOCEVAL.type_assessed,
  LOCEVAL.type_is_absent,
  LOCEVAL.eval_source,
  LOCEVAL.eval_name,
  LOCEVAL.eval_date,
  LOCEVAL.notes,
  LOCEVAL.photo
FROM "transfer"."LocationEvaluations" AS LOCEVAL
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON (LOCEVAL.sampleunit_id = UNIT.sampleunit_id)
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
WHERE TRUE
  AND eval_source = 'loceval'
;


GRANT SELECT ON  "outbound"."LocevalInfo"  TO  viewer_mnmdb;

-- GRANT SELECT ON  "outbound"."LocevalInfo"  TO  tester_mnmdb;
