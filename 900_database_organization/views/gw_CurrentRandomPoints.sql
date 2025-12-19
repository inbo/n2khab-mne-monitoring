

DROP VIEW IF EXISTS  "outbound"."RandomCellPoints" CASCADE;
CREATE VIEW "outbound"."RandomCellPoints" AS
SELECT *
FROM "outbound"."RandomPoints"
WHERE grts_address IN (
    SELECT DISTINCT grts_address
    FROM "outbound"."LocationEvaluations"
    WHERE eval_source = 'loceval'
    UNION
    SELECT DISTINCT grts_address
    FROM "outbound"."FieldworkCalendar"
    WHERE done_planning
  )
;


GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;

GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  tester;
