---
aliases:
tags:
  - ElevationPoints
  - altitude
started: 2026-08-04
finished: 2026-08-04
execution:
  - FM
status: true
---

<https://docs.qfield.org/how-to/navigation-and-positioning/gnss/#capturing-longitude-latitude-and-altitude-in-attribute-form>

```sql

SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."ElevationPoints" CASCADE;

BEGIN;
CREATE TABLE "inbound"."ElevationPoints"() ;

COMMENT ON TABLE "inbound"."ElevationPoints" IS E'three dimensional points intended for measuring elevation with an RTK-GPS or similar devices';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_elevationpoints_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'ElevationPoints', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "elevationpoints_wkb_geometry_geom_idx" ON "inbound"."ElevationPoints" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "inbound"."ElevationPoints_ogc_fid_seq" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."ElevationPoints_ogc_fid_seq" TO viewer_mnmdb;

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN elevationpoint_id int NOT NULL UNIQUE; 
COMMENT ON COLUMN "inbound"."ElevationPoints".elevationpoint_id IS E'sampling point technical index';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."ElevationPoints".log_creator IS E'(technical) user who created the entry';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN log_creation timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."ElevationPoints".log_creation IS E'(technical) timestamp of creation';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN notes varchar; 
COMMENT ON COLUMN "inbound"."ElevationPoints".notes IS E'free notes on the purpose of these coordinates';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN longitude_position double precision NOT NULL; 
COMMENT ON COLUMN "inbound"."ElevationPoints".longitude_position IS E'longitude (west-east angular cooridante), in GNSS CRS';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN latitude_position double precision NOT NULL; 
COMMENT ON COLUMN "inbound"."ElevationPoints".latitude_position IS E'latitude (south-north angular coordinate), in GNSS CRS';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN longitude_position_bd72 double precision; 
COMMENT ON COLUMN "inbound"."ElevationPoints".longitude_position_bd72 IS E'longitude (west-east angular cooridante), in EPSG:31370 BD72 Lambert';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN latitude_position_bd72 double precision; 
COMMENT ON COLUMN "inbound"."ElevationPoints".latitude_position_bd72 IS E'latitude (south-north angular coordinate), in EPSG:31370 BD72 Lambert';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN altitude_at_position double precision; 
COMMENT ON COLUMN "inbound"."ElevationPoints".altitude_at_position IS E'the altitude recording of the current position';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN horizontal_accuracy double precision; 
COMMENT ON COLUMN "inbound"."ElevationPoints".horizontal_accuracy IS E'horizontal accuracy of the GNSS signal';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN vertical_accuracy double precision; 
COMMENT ON COLUMN "inbound"."ElevationPoints".vertical_accuracy IS E'vertical accuracy of the GNSS signal';

COMMIT;

-- sequence elevationpoint_id
CREATE SEQUENCE "inbound".seq_elevationpoint_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."ElevationPoints".elevationpoint_id;
ALTER TABLE "inbound"."ElevationPoints" ALTER COLUMN elevationpoint_id
 SET DEFAULT nextval('inbound.seq_elevationpoint_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_elevationpoint_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_elevationpoint_id" TO viewer_mnmdb;

GRANT SELECT ON "inbound"."ElevationPoints" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."ElevationPoints" TO user_surfdb;
GRANT UPDATE ON "inbound"."ElevationPoints" TO user_surfdb;
GRANT DELETE ON "inbound"."ElevationPoints" TO user_surfdb;

```

Then, in QGIS:
+ add default values in the feature form
	+ longitude: `x(transform(@position_coordinate, 'EPSG:4326', @project_crs))`
	+ latitude: `y(transform(@position_coordinate, 'EPSG:4326', @project_crs))`
	+ altitude: `z(@position_coordinate)`
	+ accuracies: `@position_horizontal_accuracy`, `@position_vertical_accuracy`
+ optionally: make non-editable

Then, in QField:
+ lock position to cursor