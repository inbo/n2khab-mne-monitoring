BEGIN;

DROP VIEW IF EXISTS  "outbound"."LocevalInfo" ;
CREATE VIEW "outbound"."LocevalInfo" AS
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
  LOCEVAL.photo,
  CASE WHEN (LOCEVAL.type_is_absent
    OR
    ( LOCEVAL.type_assessed IS NOT NULL
      AND NOT (LOCEVAL.type_assessed = LOCEVAL.type)
    )) THEN FALSE
    ELSE TRUE
    END AS loceval_is_positive
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

COMMIT;
