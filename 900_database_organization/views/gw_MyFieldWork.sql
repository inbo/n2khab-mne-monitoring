

DROP VIEW IF EXISTS  "inbound"."MyFieldWork" ;
CREATE VIEW "inbound"."MyFieldWork" AS
SELECT * FROM "inbound"."FieldWork"
WHERE teammember_assigned IN (
  SELECT DISTINCT teammember_id
  FROM "metadata"."TeamMembers"
  WHERE username = 'all_groundwater'
    OR LOWER(username) = LOWER(current_user)
);


GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tom, yglinga, jens, lise, wouter, floris, karen;

GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tester;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tester;
