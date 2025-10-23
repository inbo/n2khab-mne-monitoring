
-- *for testing*
-- UPDATE "outbound"."SampleUnits"
-- SET replacement_ongoing = TRUE
-- WHERE sampleunit_id <= 42
-- ;

DROP VIEW IF EXISTS  "inbound"."ReplacementOngoing" ;
CREATE VIEW "inbound"."ReplacementOngoing" AS
SELECT
  REPU.*,
  VISIT.notes AS unit_notes,
  VISIT.visit_id,
  VISIT.type_assessed,
  VISIT.photo,
  VISIT.visit_done
FROM (
  SELECT
    REP.ogc_fid,
    REP.wkb_geometry,
    REP.replacement_id,
    UNIT.location_id,
    UNIT.sampleunit_id,
    REP.grts_address_replacement AS grts_address,
    REP.replacement_rank,
    REP.is_selected,
    REP.is_inappropriate,
    REP.implications_habitatmap,
    REP.type_suggested,
    UNIT.is_replaced,
    UNIT.type_is_absent,
    REP.notes AS rep_notes,
    INFO.locationinfo_id,
    INFO.accessibility_inaccessible,
    INFO.accessibility_revisit,
    INFO.recovery_hints
  FROM "outbound"."Replacements" AS REP
  LEFT JOIN "outbound"."SampleUnits" AS UNIT
    ON UNIT.sampleunit_id = REP.sampleunit_id
  LEFT JOIN "outbound"."LocationInfos" AS INFO
   ON UNIT.location_id = INFO.location_id
  WHERE UNIT.replacement_ongoing
    AND (
      REP.is_selected
      OR NOT (UNIT.is_replaced OR UNIT.type_is_absent)
    )
  ) AS REPU
LEFT JOIN (
  SELECT *
  FROM "inbound"."Visits"
  WHERE activity_group_id IN (
      SELECT DISTINCT activity_group_id
      FROM "metadata"."GroupedActivities"
      WHERE activity_group = 'LOCEVALTERR'
    )
  ) AS VISIT
  ON REPU.sampleunit_id = VISIT.sampleunit_id
WHERE VISIT.archive_version_id IS NULL
;


DROP RULE IF EXISTS ReplacementOngoing_upd0 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd0 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO INSTEAD NOTHING
;

DROP RULE IF EXISTS ReplacementOngoing_upd1 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd1 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "outbound"."Replacements"
 SET
  is_selected = NEW.is_selected,
  is_inappropriate = NEW.is_inappropriate,
  implications_habitatmap = NEW.implications_habitatmap,
  type_suggested = NEW.type_suggested,
  notes = NEW.rep_notes
 WHERE replacement_id = OLD.replacement_id
;

DROP RULE IF EXISTS ReplacementOngoing_upd4 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd4 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit,
  recovery_hints = NEW.recovery_hints
 WHERE locationinfo_id = OLD.locationinfo_id
;

DROP RULE IF EXISTS ReplacementOngoing_upd3 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd3 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "outbound"."SampleUnits"
 SET
  is_replaced = NEW.is_replaced
 WHERE sampleunit_id = OLD.sampleunit_id
;

DROP RULE IF EXISTS ReplacementOngoing_upd2 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd2 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  type_assessed = NEW.type_assessed,
  notes = NEW.unit_notes,
  photo = NEW.photo,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;


GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO ward, karen, floris, tom, monkey;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO ward, karen, floris, tom;

GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO tester;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO tester;
