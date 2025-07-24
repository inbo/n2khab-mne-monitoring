

DROP VIEW IF EXISTS  "inbound"."MyFieldWork" ;
CREATE VIEW "inbound"."MyFieldWork" AS
SELECT * FROM "inbound"."FieldWork"
WHERE teammember_assigned IN (
  SELECT DISTINCT teammember_id
  FROM "metadata"."TeamMembers"
  WHERE username = 'all_groundwater'
    OR LOWER(username) = LOWER(current_user)
);



GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tom;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  yglinga;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  jens;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  lise;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  wouter;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  floris;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  karen;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tester;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  falk;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  ward;
GRANT SELECT ON  "inbound"."MyFieldWork"  TO  monkey;

GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tom;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  yglinga;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  jens;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  lise;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  wouter;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  floris;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  karen;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tester;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  falk;
