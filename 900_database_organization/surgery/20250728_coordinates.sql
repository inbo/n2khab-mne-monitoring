SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"metadata";

DROP TABLE IF EXISTS "metadata"."Coordinates" CASCADE;

BEGIN;
CREATE TABLE "metadata"."Coordinates"();

COMMENT ON TABLE "metadata"."Coordinates" IS E'coordinates of the grts points (in other CRS)';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN coordinate_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "metadata"."Coordinates".coordinate_id IS E'coordinate index (technical)';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN location_id int NOT NULL;
COMMENT ON COLUMN "metadata"."Coordinates".location_id IS E'location index (technical)';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "metadata"."Coordinates".grts_address IS E'GRTS address (`final`, i.e. after prior replacements)';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN lambert_x double precision;
COMMENT ON COLUMN "metadata"."Coordinates".lambert_x IS E'x coordinate in EPSG:31370 BD72 Lambert';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN lambert_y double precision;
COMMENT ON COLUMN "metadata"."Coordinates".lambert_y IS E'y coordinate in EPSG:31370 BD72 Lambert';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN wgs84_x double precision;
COMMENT ON COLUMN "metadata"."Coordinates".wgs84_x IS E'x coordinate in EPSG:4326 WGS84';

ALTER TABLE "metadata"."Coordinates" ADD COLUMN wgs84_y double precision;
COMMENT ON COLUMN "metadata"."Coordinates".wgs84_y IS E'y coordinate in EPSG:4326 WGS84';

COMMIT;

-- sequence coordinate_id
CREATE SEQUENCE "metadata".seq_coordinate_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "metadata"."Coordinates".coordinate_id;
ALTER TABLE "metadata"."Coordinates" ALTER COLUMN coordinate_id
 SET DEFAULT nextval('metadata.seq_coordinate_id'::regclass);

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO tom;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO yglinga;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO jens;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO lise;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO wouter;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO floris;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO karen;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO ward;

GRANT USAGE ON SEQUENCE "metadata"."seq_coordinate_id" TO monkey;

GRANT SELECT ON SEQUENCE "metadata"."seq_coordinate_id" TO monkey;

GRANT SELECT ON "metadata"."Coordinates" TO tom;

GRANT SELECT ON "metadata"."Coordinates" TO yglinga;

GRANT SELECT ON "metadata"."Coordinates" TO jens;

GRANT SELECT ON "metadata"."Coordinates" TO lise;

GRANT SELECT ON "metadata"."Coordinates" TO wouter;

GRANT SELECT ON "metadata"."Coordinates" TO floris;

GRANT SELECT ON "metadata"."Coordinates" TO karen;

GRANT SELECT ON "metadata"."Coordinates" TO ward;

GRANT SELECT ON "metadata"."Coordinates" TO monkey;

SELECT * FROM "metadata"."Coordinates";





DROP VIEW IF EXISTS  "outbound"."LocationCoords";
CREATE VIEW "outbound"."LocationCoords" AS
SELECT
  LOC.*,
  COORDS.wgs84_x,
  COORDS.wgs84_y,
  COORDS.lambert_x,
  COORDS.lambert_y,
  '<a href="https://www.google.com/maps/dir/?api=1&destination=' ||
    CAST(COORDS.wgs84_y AS VARCHAR) ||
    '%2C' ||
    CAST(COORDS.wgs84_x AS VARCHAR) ||
    '&travelmode=driving"> to google </a>'
    AS google_link
FROM "metadata"."Locations" AS LOC
LEFT JOIN "metadata"."Coordinates" AS COORDS
  ON COORDS.location_id = LOC.location_id
WHERE LOC.location_id IS NOT NULL
  AND COORDS.location_id IS NOT NULL
;

GRANT SELECT ON  "outbound"."LocationCoords"  TO  tom,yglinga,jens,lise,wouter,floris,karen,ward;
