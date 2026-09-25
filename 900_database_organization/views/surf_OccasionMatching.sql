
-- providing a tree link table for Visits 1 : n FieldCalendars


DROP VIEW IF EXISTS  "outbound"."MatchingOccasions" CASCADE;
CREATE OR REPLACE VIEW "outbound"."MatchingOccasions" AS
SELECT
  FC.fieldcalendar_id,
  FC.visit_id,
  FC.grts_address,
  FC.stratum,
  FC.matching_occasion
FROM "outbound"."FieldCalendars" FC
LEFT JOIN "inbound"."Visits" VZ
  ON VZ.visit_id = FC.visit_id
  AND VZ.grts_address = FC.grts_address
  AND VZ.date_start = FC.date_start
  AND VZ.activity_group_id = FC.activity_group_id
WHERE VZ.visit_id IS NOT NULL
;


GRANT SELECT ON  "outbound"."MatchingOccasions"  TO  viewer_mnmdb;
-- GRANT UPDATE ON  "outbound"."MatchingOccasions"  TO  user_surfdb;
