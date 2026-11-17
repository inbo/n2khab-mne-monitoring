
BEGIN;

DROP VIEW IF EXISTS "outbound"."MissingTeammember" ;
CREATE VIEW "outbound"."MissingTeammember" AS
SELECT DISTINCT LOC.*, CAL.teammember_assigned, CAL.log_user, ACT.activity_group
FROM "outbound"."FieldCalendars" AS CAL
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON CAL.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "metadata"."ActivityGroups" AS ACT
  ON CAL.activity_group_id = ACT.activity_group_id
WHERE done_planning
  AND teammember_assigned IS NULL
  AND NOT excluded
;

GRANT SELECT ON  "outbound"."MissingTeammember" TO  viewer_mnmdb;
GRANT UPDATE ON  "outbound"."MissingTeammember" TO  planner_gwdb;

COMMIT;
