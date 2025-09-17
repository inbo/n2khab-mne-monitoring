

DROP VIEW IF EXISTS  "outbound"."MHQSafety" CASCADE;
CREATE VIEW "outbound"."MHQSafety" AS
SELECT *
FROM "outbound"."MHQPolygons"
WHERE samplelocation_id IN (
    SELECT DISTINCT samplelocation_id
    FROM "outbound"."LocationEvaluations"
    WHERE eval_source = 'loceval'
  )
;


GRANT SELECT ON  "outbound"."MHQSafety"  TO  tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;

GRANT SELECT ON  "outbound"."MHQSafety"  TO  tester;
