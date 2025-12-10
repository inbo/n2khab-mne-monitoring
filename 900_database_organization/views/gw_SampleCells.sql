
DROP VIEW IF EXISTS  "outbound"."SampleCells" ;
CREATE VIEW "outbound"."SampleCells" AS
SELECT
 *
FROM "metadata"."LocationCells"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "outbound"."SampleLocations"
  WHERE samplelocation_id
  IN (
    SELECT DISTINCT samplelocation_id
    FROM "outbound"."FieldworkCalendar"
    WHERE archive_version_id IS NULL
  )
)
;

GRANT SELECT ON  "outbound"."SampleCells"  TO tom,yglinga,jens,lise,wouter,floris,karen,ward;
