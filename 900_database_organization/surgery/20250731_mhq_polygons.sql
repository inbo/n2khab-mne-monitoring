SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"outbound";

DROP TABLE IF EXISTS "outbound"."MHQPolygons" CASCADE;

BEGIN;
CREATE TABLE "outbound"."MHQPolygons"();

COMMENT ON TABLE "outbound"."MHQPolygons" IS E'MHQ sample areas NO TRESPASSING!';

ALTER TABLE "outbound"."MHQPolygons" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_mhqpolygons_fid" PRIMARY KEY;
SELECT AddGeometryColumn('outbound', 'MHQPolygons', 'wkb_geometry', 31370, 'POLYGON', 2);
CREATE INDEX "mhqpolygons_wkb_geometry_geom_idx" ON "outbound"."MHQPolygons" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO falk;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO tom;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO yglinga;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO jens;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO lise;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO wouter;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO floris;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO karen;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO ward;

GRANT USAGE ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO monkey;

GRANT SELECT ON SEQUENCE "outbound"."MHQPolygons_ogc_fid_seq" TO monkey;

ALTER TABLE "outbound"."MHQPolygons" ADD COLUMN mhqpolygon_id int NOT NULL UNIQUE;
COMMENT ON COLUMN "outbound"."MHQPolygons".mhqpolygon_id IS E'mhq polygon index (technical)';

ALTER TABLE "outbound"."MHQPolygons" ADD COLUMN samplelocation_id int;
COMMENT ON COLUMN "outbound"."MHQPolygons".samplelocation_id IS E'optional link to sample locations';

ALTER TABLE "outbound"."MHQPolygons" ADD COLUMN location_id int;
COMMENT ON COLUMN "outbound"."MHQPolygons".location_id IS E'optional link to locations';

ALTER TABLE "outbound"."MHQPolygons" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "outbound"."MHQPolygons".grts_address IS E'GRTS address (`final`, i.e. after prior replacements)';

COMMIT;

-- sequence mhqpolygon_id
CREATE SEQUENCE "outbound".seq_mhqpolygon_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "outbound"."MHQPolygons".mhqpolygon_id;
ALTER TABLE "outbound"."MHQPolygons" ALTER COLUMN mhqpolygon_id
 SET DEFAULT nextval('outbound.seq_mhqpolygon_id'::regclass);

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO tom;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO yglinga;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO jens;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO lise;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO wouter;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO floris;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO karen;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO falk;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO ward;

GRANT USAGE ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO monkey;

GRANT SELECT ON SEQUENCE "outbound"."seq_mhqpolygon_id" TO monkey;

GRANT SELECT ON "outbound"."MHQPolygons" TO tom;

GRANT SELECT ON "outbound"."MHQPolygons" TO yglinga;

GRANT SELECT ON "outbound"."MHQPolygons" TO jens;

GRANT SELECT ON "outbound"."MHQPolygons" TO lise;

GRANT SELECT ON "outbound"."MHQPolygons" TO wouter;

GRANT SELECT ON "outbound"."MHQPolygons" TO floris;

GRANT SELECT ON "outbound"."MHQPolygons" TO karen;

GRANT SELECT ON "outbound"."MHQPolygons" TO falk;

GRANT SELECT ON "outbound"."MHQPolygons" TO ward;

GRANT SELECT ON "outbound"."MHQPolygons" TO monkey;
