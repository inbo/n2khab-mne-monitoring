

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


GRANT SELECT ON  "inbound"."FieldWork"  TO  tom;
GRANT SELECT ON  "inbound"."FieldWork"  TO  yglinga;
GRANT SELECT ON  "inbound"."FieldWork"  TO  jens;
GRANT SELECT ON  "inbound"."FieldWork"  TO  lise;
GRANT SELECT ON  "inbound"."FieldWork"  TO  wouter;
GRANT SELECT ON  "inbound"."FieldWork"  TO  floris;
GRANT SELECT ON  "inbound"."FieldWork"  TO  karen;
GRANT SELECT ON  "inbound"."FieldWork"  TO  falk;
GRANT SELECT ON  "inbound"."FieldWork"  TO  ward;
GRANT SELECT ON  "inbound"."FieldWork"  TO  monkey;

GRANT SELECT ON  "inbound"."FieldWork"  TO  tester;
