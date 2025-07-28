
DROP VIEW IF EXISTS  "outbound"."SampleCells" ;
CREATE VIEW "outbound"."SampleCells" AS
SELECT
 *
FROM "metadata"."LocationCells"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "outbound"."SampleLocations"
)
;

GRANT SELECT ON  "outbound"."SampleCells"  TO ward;
GRANT SELECT ON  "outbound"."SampleCells"  TO karen;
GRANT SELECT ON  "outbound"."SampleCells"  TO floris;
GRANT UPDATE ON  "outbound"."SampleCells"  TO ward;
GRANT UPDATE ON  "outbound"."SampleCells"  TO karen;
GRANT UPDATE ON  "outbound"."SampleCells"  TO floris;
GRANT SELECT ON  "outbound"."SampleCells"  TO tom;
GRANT UPDATE ON  "outbound"."SampleCells"  TO tom;

GRANT SELECT ON  "outbound"."SampleCells"  TO tester;
GRANT UPDATE ON  "outbound"."SampleCells"  TO tester;
