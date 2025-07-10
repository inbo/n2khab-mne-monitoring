DROP VIEW IF EXISTS  "inbound"."ReplacementOngoing" ;
CREATE VIEW "inbound"."ReplacementOngoing" AS
SELECT
  REP.ogc_fid,
  REP.wkb_geometry,
  REP.replacement_id,
  SLOC.samplelocation_id,
  REP.grts_address_replacement AS grts_address,
  REP.replacement_rank,
  REP.is_selected,
  REP.is_inappropriate,
  REP.implications_habitatmap,
  REP.notes
FROM "outbound"."ReplacementLocations" AS REP
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON SLOC.samplelocation_id = REP.samplelocation_id
WHERE SLOC.replacement_ongoing
  AND NOT SLOC.is_replaced
;


DROP RULE IF EXISTS ReplacementOngoing_upd ON "inbound"."ReplacementOngoing";
CREATE RULE ReplacementOngoing_upd AS
ON UPDATE TO "inbound"."ReplacementOngoing"
DO INSTEAD
 UPDATE "outbound"."ReplacementLocations"
 SET
  is_selected = NEW.is_selected,
  is_inappropriate = NEW.is_inappropriate,
  implications_habitatmap = NEW.implications_habitatmap,
  notes = NEW.notes
 WHERE replacement_id = OLD.replacement_id
;



GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO ward;
GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO karen;
GRANT SELECT ON  "inbound"."ReplacementOngoing"  TO floris;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO ward;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO karen;
GRANT UPDATE ON  "inbound"."ReplacementOngoing"  TO floris;
