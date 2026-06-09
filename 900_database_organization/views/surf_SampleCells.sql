
DROP VIEW IF EXISTS  "outbound"."SampleCells" ;
CREATE VIEW "outbound"."SampleCells" AS
SELECT
 *
FROM "metadata"."LocationCells"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "outbound"."SampleUnits"
  WHERE sampleunit_id
  IN (
    SELECT DISTINCT sampleunit_id
    FROM "outbound"."FieldCalendar"
    WHERE archive_version_id IS NULL
  )
)
;

GRANT SELECT ON  "outbound"."SampleCells"  TO viewer_mnmdb;
