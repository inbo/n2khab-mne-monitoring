
BEGIN;


DROP VIEW IF EXISTS  "outbound"."RequireTotalStation" CASCADE;
CREATE OR REPLACE VIEW "outbound"."RequireTotalStation" AS
SELECT
  *
FROM "metadata"."Locations"
WHERE grts_address IN (
  SELECT DISTINCT grts_address
  FROM "inbound"."PositioningVisits"
  WHERE require_total_station IS TRUE
)
;


GRANT SELECT ON  "outbound"."RequireTotalStation"  TO  viewer_mnmdb;

COMMIT;
