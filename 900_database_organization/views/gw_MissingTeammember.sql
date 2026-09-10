
DROP VIEW IF EXISTS "outbound"."MissingTeammember" ;
CREATE VIEW "outbound"."MissingTeammember" AS
SELECT DISTINCT LOC.*
FROM "outbound"."FieldCalendars" AS FwCal
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON FwCal.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
WHERE done_planning
  AND teammember_assigned IS NULL
  AND NOT excluded
  AND NOT no_visit_planned
;

GRANT SELECT ON  "outbound"."MissingTeammember" TO  viewer_mnmdb;
GRANT UPDATE ON  "outbound"."MissingTeammember" TO  planner_gwdb;
