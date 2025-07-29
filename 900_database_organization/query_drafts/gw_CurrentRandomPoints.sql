

DROP VIEW IF EXISTS  "outbound"."RandomCellPoints" CASCADE;
CREATE VIEW "outbound"."RandomCellPoints" AS
SELECT *
FROM "outbound"."RandomPoints"
WHERE samplelocation_id IN (
    SELECT DISTINCT samplelocation_id
    FROM "outbound"."LocationEvaluations"
    WHERE eval_source = 'loceval'
  )
;


GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;

GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  tester;
