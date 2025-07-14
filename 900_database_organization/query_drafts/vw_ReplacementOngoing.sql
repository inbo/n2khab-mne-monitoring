
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
  VISIT.visit_done
FROM (
  SELECT
    REP.ogc_fid,
    REP.wkb_geometry,
    REP.replacement_id,
    UNIT.sampleunit_id,
    REP.grts_address_replacement AS grts_address,
    REP.replacement_rank,
    REP.is_selected,
    REP.is_inappropriate,
    REP.implications_habitatmap,
    UNIT.is_replaced,
    REP.notes AS rep_notes
  FROM "outbound"."Replacements" AS REP
  LEFT JOIN "outbound"."SampleUnits" AS UNIT
    ON UNIT.sampleunit_id = REP.sampleunit_id
  WHERE UNIT.replacement_ongoing
    AND (NOT UNIT.is_replaced OR REP.is_selected)
) AS REPU
LEFT JOIN "inbound"."Visits" AS VISIT
  ON REPU.sampleunit_id = VISIT.sampleunit_id
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
  notes = NEW.rep_notes
 WHERE replacement_id = OLD.replacement_id
;

DROP RULE IF EXISTS ReplacementOngoing_upd2 ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd2 AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  type_assessed = NEW.type_assessed,
  notes = NEW.unit_notes,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;


GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO ward;
GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO karen;
GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO floris;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO ward;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO karen;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO floris;
GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO tom;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO tom;

GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO tester;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO tester;
