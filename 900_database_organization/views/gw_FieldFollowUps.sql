
DROP TRIGGER IF EXISTS log_fieldfollowups ON "inbound"."FieldFollowUps";
CREATE TRIGGER log_fieldfollowups
BEFORE UPDATE ON "inbound"."FieldFollowUps"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

-- no view: should be filtered in qgis

-- view DID NOT WORK / ogc_fid not found!

DROP VIEW IF EXISTS  "inbound"."FollowUp" ;
CREATE VIEW "inbound"."FollowUp" AS
SELECT *
FROM "inbound"."FieldFollowUps"
WHERE TRUE
;


DROP VIEW IF EXISTS  "inbound"."ToDos" ;
CREATE VIEW "inbound"."ToDos" AS
SELECT *
FROM "inbound"."FieldFollowUps"
WHERE NOT done
;

GRANT SELECT ON "inbound"."FollowUp" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT INSERT ON "inbound"."FollowUp" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT UPDATE ON "inbound"."FollowUp" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT DELETE ON "inbound"."FollowUp" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;

GRANT SELECT ON "inbound"."ToDos" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT INSERT ON "inbound"."ToDos" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT UPDATE ON "inbound"."ToDos" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT DELETE ON "inbound"."ToDos" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;


--
  ogc_fid,
  wkb_geometry,
  followup_id,
  teammember_id,
  issue_date,
  location,
  todo,
  activity,
  replacement,
  repair,
  desktop_only,
  photo,
  audio,
  deadline,
  solution_comment,
  solved_date,
  done
