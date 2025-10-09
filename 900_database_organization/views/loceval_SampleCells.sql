
-- https://stackoverflow.com/questions/59836997/select-single-first-occurrence-of-row-against-distinct-local-id-from-a-table-and

DROP VIEW IF EXISTS  "outbound"."SampleCells" ;
CREATE VIEW "outbound"."SampleCells" AS
SELECT DISTINCT ON (location_id) *
FROM (
SELECT
 *
FROM "metadata"."LocationCells"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "outbound"."SampleUnits"
)
UNION
SELECT
 *
FROM "outbound"."ReplacementCells"
WHERE replacement_id IN (
  SELECT DISTINCT REP.replacement_id
  FROM "outbound"."Replacements" AS REP
  LEFT JOIN "outbound"."SampleUnits" AS UNIT
    ON UNIT.sampleunit_id = REP.sampleunit_id
  WHERE replacement_ongoing
    AND (
      REP.is_selected
      OR NOT (UNIT.is_replaced OR UNIT.type_is_absent)
    )
)
)
GROUP BY ogc_fid, wkb_geometry, location_id
ORDER BY location_id
;

GRANT SELECT ON  "outbound"."SampleCells"  TO ward, karen, floris, tom, monkey;
GRANT UPDATE ON  "outbound"."SampleCells"  TO ward, karen, floris, tom;

GRANT SELECT ON  "outbound"."SampleCells"  TO tester;
GRANT UPDATE ON  "outbound"."SampleCells"  TO tester;
