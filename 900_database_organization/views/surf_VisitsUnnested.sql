

DROP VIEW IF EXISTS  "inbound"."VisitsUnnested" CASCADE;
CREATE OR REPLACE VIEW "inbound"."VisitsUnnested" AS
SELECT
 *,
 UNNEST(stratums) AS stratum,
 UNNEST(sampleunit_ids) AS sampleunit_id,
 UNNEST(fieldcalendar_ids) AS fieldcalendar_id
FROM "inbound"."Visits"
;


GRANT SELECT ON  "inbound"."VisitsUnnested"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."VisitsUnnested"  TO  user_surfdb;

-- SELECT *
-- FROM "inbound"."Visits"
-- WHERE grts_address = 1012434 AND date_start = '2026-07-01'
-- ;
