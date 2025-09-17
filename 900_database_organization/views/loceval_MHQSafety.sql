

DROP VIEW IF EXISTS  "outbound"."MHQSafety" CASCADE;
CREATE VIEW "outbound"."MHQSafety" AS
SELECT *
FROM "outbound"."MHQPolygons"
WHERE sampleunit_id IN (
    SELECT DISTINCT sampleunit_id
    FROM "inbound"."Visits"
  )
;

GRANT SELECT ON  "outbound"."MHQSafety"  TO  tom, floris, karen, falk, ward, monkey;
