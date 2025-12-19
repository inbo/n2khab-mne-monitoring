
DROP VIEW IF EXISTS  "metadata"."ActivityGroups" ;
CREATE VIEW "metadata"."ActivityGroups" AS
SELECT DISTINCT
  activity_group_id, activity_group
FROM "metadata"."GroupedActivities"
GROUP BY activity_group_id, activity_group
ORDER BY activity_group_id
;


GRANT SELECT ON  "metadata"."ActivityGroups"  TO  tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT UPDATE ON  "metadata"."ActivityGroups"  TO  tom, yglinga, jens, lise, wouter, floris, karen;
