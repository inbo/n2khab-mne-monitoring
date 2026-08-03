---
aliases:
tags:
  - ElevationPoints
started:
finished:
execution:
status: false
---

```sql
SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."ElevationPoints" CASCADE;

BEGIN;
CREATE TABLE "inbound"."ElevationPoints"();
COMMENT ON TABLE "inbound"."ElevationPoints" IS E'three dimensional points intended for measuring elevation with an RTK-GPS or similar devices';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_elevationpoints_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'ElevationPoints', 'wkb_geometry', 31370, 'POINTM', 3);
CREATE INDEX "elevationpoints_wkb_geometry_geom_idx" ON "inbound"."ElevationPoints" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "inbound"."ElevationPoints_ogc_fid_seq" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."ElevationPoints_ogc_fid_seq" TO viewer_mnmdb;

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN elevationpoint_id int NOT NULL UNIQUE; 
COMMENT ON COLUMN "inbound"."ElevationPoints".elevationpoint_id IS E'sampling point technical index';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."ElevationPoints".log_creator IS E'(technical) user who created the entry';

ALTER TABLE "inbound"."ElevationPoints" ADD COLUMN log_creation timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."ElevationPoints".log_creation IS E'(technical) timestamp of creation';

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