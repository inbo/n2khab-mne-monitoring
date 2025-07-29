-- add table
SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"outbound";

DROP TABLE IF EXISTS "outbound"."RandomPoints" CASCADE;

BEGIN;
CREATE TABLE "outbound"."RandomPoints"();

COMMENT ON TABLE "outbound"."RandomPoints" IS E'random points for placement in the cell';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_randompoints_fid" PRIMARY KEY;
SELECT AddGeometryColumn('outbound', 'RandomPoints', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "randompoints_wkb_geometry_geom_idx" ON "outbound"."RandomPoints" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO yoda;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO tom;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO yglinga;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO jens;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO lise;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO wouter;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO floris;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO karen;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO ward;

GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO monkey;

GRANT SELECT ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO monkey;

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN randompoint_id int NOT NULL UNIQUE;
COMMENT ON COLUMN "outbound"."RandomPoints".randompoint_id IS E'random point index (technical)';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN samplelocation_id int;
COMMENT ON COLUMN "outbound"."RandomPoints".samplelocation_id IS E'optional link to sample locations';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN location_id int;
COMMENT ON COLUMN "outbound"."RandomPoints".location_id IS E'optional link to locations';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "outbound"."RandomPoints".grts_address IS E'GRTS address (`final`, i.e. after prior replacements)';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN random_point_rank smallint NOT NULL;
COMMENT ON COLUMN "outbound"."RandomPoints".random_point_rank IS E'serial = priority of the random point';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN compass varchar(3);
COMMENT ON COLUMN "outbound"."RandomPoints".compass IS E'nan';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN angle double precision;
COMMENT ON COLUMN "outbound"."RandomPoints".angle IS E'nan';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN angle_look double precision;
COMMENT ON COLUMN "outbound"."RandomPoints".angle_look IS E'nan';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN distance_m double precision;
COMMENT ON COLUMN "outbound"."RandomPoints".distance_m IS E'nan';

COMMIT;

-- sequence randompoint_id
CREATE SEQUENCE "outbound".seq_randompoint_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "outbound"."RandomPoints".randompoint_id;
ALTER TABLE "outbound"."RandomPoints" ALTER COLUMN randompoint_id
 SET DEFAULT nextval('outbound.seq_randompoint_id'::regclass);

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO tom;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO yglinga;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO jens;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO lise;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO wouter;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO floris;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO karen;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO ward;

GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO monkey;

GRANT SELECT ON SEQUENCE "outbound"."seq_randompoint_id" TO monkey;

GRANT SELECT ON "outbound"."RandomPoints" TO tom;

GRANT SELECT ON "outbound"."RandomPoints" TO yglinga;

GRANT SELECT ON "outbound"."RandomPoints" TO jens;

GRANT SELECT ON "outbound"."RandomPoints" TO lise;

GRANT SELECT ON "outbound"."RandomPoints" TO wouter;

GRANT SELECT ON "outbound"."RandomPoints" TO floris;

GRANT SELECT ON "outbound"."RandomPoints" TO karen;

GRANT SELECT ON "outbound"."RandomPoints" TO ward;

GRANT SELECT ON "outbound"."RandomPoints" TO monkey;



GRANT USAGE ON SEQUENCE "outbound"."seq_randompoint_id" TO tester;
GRANT SELECT ON "outbound"."RandomPoints" TO tester;
GRANT USAGE ON SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" TO tester;


-- source 230_*
SELECT * FROM "outbound"."RandomPoints";
