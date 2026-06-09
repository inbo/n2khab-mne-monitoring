

DROP VIEW IF EXISTS  "outbound"."MHQSafety" CASCADE;
CREATE VIEW "outbound"."MHQSafety" AS
SELECT *
FROM "outbound"."MHQPolygons"
WHERE location_id IN (
  SELECT DISTINCT location_id
  FROM "inbound"."InstallationVisits"
)
;


GRANT SELECT ON  "outbound"."MHQSafety"  TO  viewer_mnmdb;

-- GRANT SELECT ON  "outbound"."MHQSafety"  TO  tester_mnmdb;
