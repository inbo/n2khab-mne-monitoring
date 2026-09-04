
DROP VIEW IF EXISTS  "outbound"."SamplePolygons" ;
CREATE VIEW "outbound"."SamplePolygons" AS
SELECT DISTINCT
 POL.ogc_fid,
 POL.wkb_geometry,
 UNIT.type,
 UNIT.replacement_ongoing,
 UNIT.is_replaced
FROM "outbound"."SampleUnitPolygons" AS POL
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = POL.sampleunit_id
;

GRANT SELECT ON  "outbound"."SamplePolygons"  TO viewer_mnmdb;
GRANT UPDATE ON  "outbound"."SamplePolygons"  TO user_loceval;
