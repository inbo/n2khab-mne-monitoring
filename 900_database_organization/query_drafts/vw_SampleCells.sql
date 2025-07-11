

DROP VIEW IF EXISTS  "outbound"."SamplePolygons" ;
CREATE VIEW "outbound"."SamplePolygons" AS
SELECT
 *
FROM "metadata"."LocationCells"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "outbound"."SampleUnits"
)
;

GRANT SELECT ON  "outbound"."SamplePolygons"  TO ward;
GRANT SELECT ON  "outbound"."SamplePolygons"  TO karen;
GRANT SELECT ON  "outbound"."SamplePolygons"  TO floris;
GRANT UPDATE ON  "outbound"."SamplePolygons"  TO ward;
GRANT UPDATE ON  "outbound"."SamplePolygons"  TO karen;
GRANT UPDATE ON  "outbound"."SamplePolygons"  TO floris;
