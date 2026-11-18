
BEGIN;

DROP VIEW IF EXISTS "inbound"."UnplannedVisitCheck" CASCADE;
CREATE VIEW "inbound"."UnplannedVisitCheck" AS
SELECT
  LOC.*,
  VIS.visit_id,
  VIS.stratum,
  ACT.activity_group,
  VIS.date_start,
  VIS.log_user,
  VIS.log_update,
  VIS.date_visit,
  TEAM.username,
  ACT.activity_group || ' visit unplanned!' AS label
FROM "inbound"."Visits" VIS
LEFT JOIN "metadata"."Locations" LOC
  ON LOC.location_id = VIS.location_id
LEFT JOIN "outbound"."FieldCalendars" CAL
  ON VIS.visit_id = CAL.visit_id
LEFT JOIN "metadata"."ActivityGroups" ACT
  ON ACT.activity_group_id = VIS.activity_group_id
LEFT JOIN "metadata"."TeamMembers" TEAM
  ON TEAM.teammember_id = VIS.teammember_id
WHERE NOT done_planning
  AND visit_done
;

GRANT SELECT ON  "inbound"."UnplannedVisitCheck"  TO  viewer_mnmdb;

COMMIT;
