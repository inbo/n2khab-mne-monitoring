
DROP VIEW "inbound"."ReplacementOngoing" CASCADE;
CREATE OR REPLACE VIEW "inbound"."ReplacementOngoing" AS
SELECT
  REPU.*,
  VISIT.grts_address AS grts_parent,
  VISIT.notes AS unit_notes,
  VISIT.issues,
  VISIT.replacement_recovery_notes,
  VISIT.gps_type,
  VISIT.gps_accuracy_cm,
  VISIT.visit_id,
  VISIT.type_assessed,
  VISIT.photo,
  VISIT.visit_done
FROM "inbound"."Visits" AS VISIT
LEFT JOIN (
  SELECT
    REP.ogc_fid,
    REP.wkb_geometry,
    REP.replacement_id,
    UNIT.location_id,
    UNIT.sampleunit_id,
    UNIT.grts_address,
    UNIT.type AS type_expected,
    UNIT.replacement_ongoing,
    UNIT.replacement_reason,
    UNIT.replacement_permanence,
    UNIT.is_replaced,
    UNIT.type_is_absent,
    REP.grts_address_replacement,
    REP.replacement_rank,
    REP.is_selected,
    REP.is_inappropriate,
    REP.implications_habitatmap,
    REP.type_suggested,
    REP.notes AS rep_notes,
    INFO.locationinfo_id,
    INFO.accessibility_inaccessible,
    INFO.accessibility_revisit,
    INFO.recovery_hints,
    ( UNIT.replacement_ongoing
      AND NOT (UNIT.is_replaced OR UNIT.type_is_absent)
    ) AS visible_by_ongoing,
    ( REP.is_selected
    ) AS visible_by_selection
  FROM "outbound"."Replacements" AS REP
  LEFT JOIN "outbound"."SampleUnits" AS UNIT
    ON UNIT.sampleunit_id = REP.sampleunit_id
  LEFT JOIN "outbound"."LocationInfos" AS INFO
    ON UNIT.location_id = INFO.location_id
  WHERE TRUE
) AS REPU
  ON REPU.sampleunit_id = VISIT.sampleunit_id
WHERE TRUE
  AND activity_group_id IN (
      SELECT DISTINCT activity_group_id
      FROM "metadata"."GroupedActivities"
      WHERE activity = 'LOCEVALTERR'
    )
  AND (visible_by_ongoing OR (visible_by_selection AND visit_done))
  AND VISIT.archive_version_id IS NULL
;


CREATE OR REPLACE RULE ReplacementOngoing_upd_reset AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO INSTEAD NOTHING
;

CREATE OR REPLACE RULE ReplacementOngoing_upd_replacements AS
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

CREATE OR REPLACE RULE ReplacementOngoing_upd_locationinfos AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit,
  recovery_hints = NEW.recovery_hints
 WHERE locationinfo_id = OLD.locationinfo_id
;

CREATE OR REPLACE RULE ReplacementOngoing_upd_sampleunits AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "outbound"."SampleUnits"
 SET
  replacement_ongoing = NEW.replacement_ongoing,
  replacement_reason = NEW.replacement_reason,
  replacement_permanence = NEW.replacement_permanence,
  type_is_absent = NEW.type_is_absent,
  is_replaced = NEW.is_replaced
 WHERE sampleunit_id = OLD.sampleunit_id
;

CREATE OR REPLACE RULE ReplacementOngoing_upd_visits AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  type_assessed = NEW.type_assessed,
  notes = NEW.unit_notes,
  photo = NEW.photo,
  issues = NEW.issues,
  replacement_recovery_notes = NEW.replacement_recovery_notes,
  gps_type = NEW.gps_type,
  gps_accuracy_cm = NEW.gps_accuracy_cm,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;


GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO viewer_mnmdb;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO user_loceval;

-- only on testing:
-- GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO tester_mnmdb;
-- GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO tester_mnmdb;
