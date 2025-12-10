
DROP VIEW IF EXISTS "outbound"."MissingTeammember" ;
CREATE VIEW "outbound"."MissingTeammember" AS
SELECT DISTINCT LOC.*
FROM "outbound"."FieldworkCalendar" AS FwCal
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FwCal.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
WHERE done_planning
  AND teammember_assigned IS NULL
  AND NOT excluded
  AND NOT no_visit_planned
;

GRANT SELECT ON  "outbound"."MissingTeammember" TO  tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;

GRANT UPDATE ON  "outbound"."MissingTeammember" TO  tom, yglinga, jens, lise, wouter, floris, karen, falk;
