
BEGIN;

DROP VIEW IF EXISTS "inbound"."VisitIncompleteCheck" CASCADE;
CREATE VIEW "inbound"."VisitIncompleteCheck" AS
SELECT
  LOC.*,
  VIS.visit_id,
  VIS.date_start,
  ACT.activity_group,
  VIS.teammember_id IS NULL AS teammember_missing,
  VIS.date_visit IS NULL AS date_missing,
  ACT.activity_group ||
    CASE WHEN  (VIS.teammember_id IS NULL) THEN ' teamlid' ELSE '' END ||
    CASE WHEN  (VIS.date_visit IS NULL) THEN ' datum' ELSE '' END ||
    ' aanvullen aub!' AS label,
  VIS.log_user || ' ' || VIS.log_update::varchar AS logging_info
FROM "inbound"."Visits" VIS
LEFT JOIN "metadata"."Locations" LOC
  ON LOC.location_id = VIS.location_id
LEFT JOIN "metadata"."ActivityGroups" ACT
  ON ACT.activity_group_id = VIS.activity_group_id
WHERE visit_done
  AND (
    (VIS.teammember_id IS NULL)
    OR (VIS.date_visit IS NULL)
  )
;

GRANT SELECT ON  "inbound"."VisitIncompleteCheck"  TO  viewer_mnmdb;

COMMIT;
