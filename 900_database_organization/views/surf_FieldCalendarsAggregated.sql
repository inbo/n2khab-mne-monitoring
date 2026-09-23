
DROP VIEW IF EXISTS  "outbound"."FieldCalendarsAggregated" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldCalendarsAggregated" AS
SELECT
  grts_address, date_start, activity_group_id, matching_occasion, visit_id,
  ARRAY_AGG(DISTINCT stratum ORDER BY stratum) AS stratums,
  ARRAY_AGG(DISTINCT sampleunit_id ORDER BY sampleunit_id) AS sampleunit_ids,
  ARRAY_AGG(DISTINCT fieldcalendar_id ORDER BY fieldcalendar_id) AS fieldcalendar_ids,
  STRING_AGG(DISTINCT log_user, ', ') AS log_users,
  MAX(log_update) AS log_update,
  UNNEST(ARRAY_AGG(DISTINCT date_end)) AS date_end,
  UNNEST(ARRAY_AGG(DISTINCT date_interval)) AS date_interval,
  UNNEST(ARRAY_AGG(DISTINCT activity_rank)) AS activity_rank,
  MIN(date_suggested) AS date_suggested,
  MIN(priority) AS priority,
  BOOL_AND(wait_any) AS wait_any,
  BOOL_AND(wait_watersurface)   AS wait_watersurface,
  BOOL_AND(wait_3260)           AS wait_3260,
  BOOL_AND(wait_7220)           AS wait_7220,
  BOOL_AND(wait_floating)       AS wait_floating,
  BOOL_AND(wait_obsolete_types) AS wait_obsolete_types,
  BOOL_AND(is_sideloaded)       AS is_sideloaded,
  BOOL_AND(is_frozen)           AS is_frozen,
  BOOL_AND(excluded) AS excluded,
  STRING_AGG(DISTINCT excluded_reason, ', ') AS excluded_reason,
  BOOL_AND(done_planning) AS done_planning
FROM "outbound"."FieldCalendars"
WHERE archive_version_id IS NULL
  AND grts_address = 1012434 AND date_start = '2026-07-01'
GROUP BY grts_address, date_start, activity_group_id, matching_occasion, visit_id
;

--  AND grts_address = 1012434 AND date_start = '2026-07-01'

-- SELECT *
-- FROM "outbound"."FieldCalendars"
-- WHERE archive_version_id IS NULL
--   AND grts_address = 1012434 AND date_start = '2026-07-01'
-- ;
