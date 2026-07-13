---
aliases:
tags:
  - Trails
started: 2026-07-13
finished:
execution:
status: false
---

# Structure

via [[locations/structure sheets|structure sheets]]: create table

also uses `log_origindb` and  `archive_date` on #mnmsyncdb 


```sql
SET standard_conforming_strings = ON;
DROP TABLE IF EXISTS "inbound"."Trails" CASCADE;

BEGIN;
CREATE TABLE "inbound"."Trails"();
COMMENT ON TABLE "inbound"."Trails" IS E'store and share paths which facilitate relocation in the field';

ALTER TABLE "inbound"."Trails" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_trails_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'Trails', 'wkb_geometry', 31370, 'LINESTRING', 2);
CREATE INDEX "trails_wkb_geometry_geom_idx" ON "inbound"."Trails" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "inbound"."Trails_ogc_fid_seq" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."Trails_ogc_fid_seq" TO viewer_mnmdb;

ALTER TABLE "inbound"."Trails" ADD COLUMN trail_id int NOT NULL UNIQUE; 
COMMENT ON COLUMN "inbound"."Trails".trail_id IS E'note index';
ALTER TABLE "inbound"."Trails" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."Trails".log_creator IS E'(technical) user who created the entry';
ALTER TABLE "inbound"."Trails" ADD COLUMN log_creation timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."Trails".log_creation IS E'(technical) timestamp of creation';
ALTER TABLE "inbound"."Trails" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."Trails".log_user IS E'(technical) user who modified the entry';
ALTER TABLE "inbound"."Trails" ADD COLUMN log_update timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."Trails".log_update IS E'(technical) timestamp of last modification';
ALTER TABLE "inbound"."Trails" ADD COLUMN trail_name varchar; 
COMMENT ON COLUMN "inbound"."Trails".trail_name IS E'identifying name of the trail';
ALTER TABLE "inbound"."Trails" ADD COLUMN trail_note text; 
COMMENT ON COLUMN "inbound"."Trails".trail_note IS E'note about the trail';
ALTER TABLE "inbound"."Trails" ADD COLUMN location varchar; 
COMMENT ON COLUMN "inbound"."Trails".location IS E'free reference to the location (e.g. area common name, database id, or grts address)';
ALTER TABLE "inbound"."Trails" ADD COLUMN photo varchar; 
COMMENT ON COLUMN "inbound"."Trails".photo IS E'an optional photo along the way';

COMMIT;

-- sequence trail_id
CREATE SEQUENCE "inbound".seq_trail_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."Trails".trail_id;
ALTER TABLE "inbound"."Trails" ALTER COLUMN trail_id
 SET DEFAULT nextval('inbound.seq_trail_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_trail_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_trail_id" TO viewer_mnmdb;

GRANT SELECT ON "inbound"."Trails" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."Trails" TO user_<dbname>;
GRANT UPDATE ON "inbound"."Trails" TO user_<dbname>;
GRANT DELETE ON "inbound"."Trails" TO user_<dbname>;


DROP TRIGGER IF EXISTS log_trails ON "inbound"."Trails";
CREATE TRIGGER log_trails
BEFORE UPDATE ON "inbound"."Trails"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

```