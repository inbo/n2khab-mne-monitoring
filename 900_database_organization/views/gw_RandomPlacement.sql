


DROP VIEW IF EXISTS  "outbound"."RandomPlacement" CASCADE;
CREATE VIEW "outbound"."RandomPlacement" AS
SELECT *
FROM "outbound"."InstallationPoints"
WHERE grts_address IN (
    SELECT DISTINCT grts_address
    FROM "transfer"."LocationEvaluations"
    WHERE eval_source = 'loceval'
    UNION
    SELECT DISTINCT grts_address
    FROM "outbound"."FieldCalendars"
    WHERE done_planning
  )
;


GRANT SELECT ON  "outbound"."RandomPlacement"  TO  viewer_mnmdb;


-- BACKWARDS COMPATIBILITY to be removed 9/10

DROP VIEW IF EXISTS  "outbound"."RandomCellPoints" CASCADE;
CREATE VIEW "outbound"."RandomCellPoints" AS
SELECT *
FROM "outbound"."InstallationPoints"
WHERE grts_address IN (
    SELECT DISTINCT grts_address
    FROM "transfer"."LocationEvaluations"
    WHERE eval_source = 'loceval'
    UNION
    SELECT DISTINCT grts_address
    FROM "outbound"."FieldCalendars"
    WHERE done_planning
  )
;


GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  viewer_mnmdb;

-- GRANT SELECT ON  "outbound"."RandomCellPoints"  TO  tester_mnmdb;
