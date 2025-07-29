SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"outbound";

DROP TABLE IF EXISTS "outbound"."CellMaps" CASCADE;

BEGIN;
CREATE TABLE "outbound"."CellMaps"();

COMMENT ON TABLE "outbound"."CellMaps" IS E'cell mapping input by drawing polygons';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_cellmaps_fid" PRIMARY KEY;
SELECT AddGeometryColumn('outbound', 'CellMaps', 'wkb_geometry', 31370, 'POLYGON', 2);
CREATE INDEX "cellmaps_wkb_geometry_geom_idx" ON "outbound"."CellMaps" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "outbound"."CellMaps_ogc_fid_seq" TO yoda;

GRANT USAGE ON SEQUENCE "outbound"."CellMaps_ogc_fid_seq" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT SELECT ON SEQUENCE "outbound"."CellMaps_ogc_fid_seq" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;

ALTER TABLE "outbound"."CellMaps" ADD COLUMN cellmap_id int NOT NULL UNIQUE;
COMMENT ON COLUMN "outbound"."CellMaps".cellmap_id IS E'cellmap polygon index';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "outbound"."CellMaps".log_creator IS E'(technical) user who created the entry';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN log_creation timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "outbound"."CellMaps".log_creation IS E'(technical) timestamp of creation';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "outbound"."CellMaps".log_user IS E'(technical) user who modified the entry';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN log_update timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "outbound"."CellMaps".log_update IS E'(technical) timestamp of last modification';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN label varchar;
COMMENT ON COLUMN "outbound"."CellMaps".label IS E'short label to classify the polygon (optional)';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN type varchar NOT NULL;
COMMENT ON COLUMN "outbound"."CellMaps".type IS E'type (code) of this polygon';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN location varchar;
COMMENT ON COLUMN "outbound"."CellMaps".location IS E'free reference to the location (database id or grts address)';

ALTER TABLE "outbound"."CellMaps" ADD COLUMN notes text;
COMMENT ON COLUMN "outbound"."CellMaps".notes IS E'extra space for notes';

COMMIT;

-- sequence cellmap_id
CREATE SEQUENCE "outbound".seq_cellmap_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "outbound"."CellMaps".cellmap_id;
ALTER TABLE "outbound"."CellMaps" ALTER COLUMN cellmap_id
 SET DEFAULT nextval('outbound.seq_cellmap_id'::regclass);

GRANT USAGE ON SEQUENCE "outbound"."seq_cellmap_id" TO tom,yglinga,jens,lise,wouter,floris,karen,ward,monkey;
GRANT SELECT ON "outbound"."CellMaps" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
