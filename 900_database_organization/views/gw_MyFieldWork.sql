
-- DEPRECATED: this was moved to the "FieldWork" definition file
DROP VIEW IF EXISTS  "inbound"."MyFieldWork" ;
CREATE VIEW "inbound"."MyFieldWork" AS
SELECT * FROM "inbound"."FieldWork"
WHERE teammember_assigned IN (
  SELECT DISTINCT teammember_id
  FROM "metadata"."TeamMembers"
  WHERE username = 'all_groundwater'
    OR LOWER(username) = LOWER(current_user)
) OR visit_done;


GRANT SELECT ON  "inbound"."MyFieldWork"  TO  viewer_mnmdb;
GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  user_gwdb;

-- GRANT SELECT ON  "inbound"."MyFieldWork"  TO  tester_mnmdb;
-- GRANT UPDATE ON  "inbound"."MyFieldWork"  TO  tester_mnmdb;
