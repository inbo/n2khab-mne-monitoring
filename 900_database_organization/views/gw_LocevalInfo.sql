
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
  LOCEVAL.photo
FROM "outbound"."LocationEvaluations" AS LOCEVAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON (LOCEVAL.samplelocation_id = SLOC.samplelocation_id)
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
WHERE TRUE
  AND eval_source = 'loceval'
;



GRANT SELECT ON  "outbound"."LocevalInfo"  TO  tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;

GRANT SELECT ON  "outbound"."LocevalInfo"  TO  tester;
