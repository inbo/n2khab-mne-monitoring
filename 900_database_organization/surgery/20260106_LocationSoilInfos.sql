
SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"metadata";

DROP TABLE IF EXISTS "metadata"."LocationSoilInfos" CASCADE;

BEGIN;
CREATE TABLE "metadata"."LocationSoilInfos"();

COMMENT ON TABLE "metadata"."LocationSoilInfos" IS E'Infos from soilmap (via n2khab package) for all locations';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN locationsoilinfo_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".locationsoilinfo_id IS E'soil info index (technical)';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN location_id int NOT NULL;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".location_id IS E'location index (technical)';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "metadata"."LocationSoilInfos".grts_address IS E'GRTS address';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN region varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".region IS E'name of the region';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN converted varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".converted IS E'Were morphogenetic texture and drainage variables derived from a conversion table?';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN soil_unit_type_codes varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".soil_unit_type_codes IS E'the soil type of the Belgian soil map (mixed nature: morphogenetic & geomorphological codes).';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN substrate varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".substrate IS E'substrate';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN texture varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".texture IS E'texture category';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN drainage varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".drainage IS E'drainage category';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN profile varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".profile IS E'profile category';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN profile_variant varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".profile_variant IS E'variant regarding the soil profile';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN parent_material varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".parent_material IS E'variant regarding the parent material';

ALTER TABLE "metadata"."LocationSoilInfos" ADD COLUMN info varchar;
COMMENT ON COLUMN "metadata"."LocationSoilInfos".info IS E'combination of drainage, texture, substrate, profile';

COMMIT;

-- sequence locationsoilinfo_id
CREATE SEQUENCE "metadata".seq_locationsoilinfo_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "metadata"."LocationSoilInfos".locationsoilinfo_id;
ALTER TABLE "metadata"."LocationSoilInfos" ALTER COLUMN locationsoilinfo_id
 SET DEFAULT nextval('metadata.seq_locationsoilinfo_id'::regclass);

GRANT USAGE ON SEQUENCE "metadata"."seq_locationsoilinfo_id" TO tom, yglinga, jens, lise, wouter, floris, karen, janne, falk, ward, monkey;
GRANT SELECT ON SEQUENCE "metadata"."seq_locationsoilinfo_id" TO monkey;

-- foreign key location_id
ALTER TABLE "metadata"."LocationSoilInfos" DROP CONSTRAINT IF EXISTS fk_Locations_LocationSoilInfos CASCADE;
ALTER TABLE "metadata"."LocationSoilInfos" ADD CONSTRAINT fk_Locations_LocationSoilInfos FOREIGN KEY (location_id)
REFERENCES "metadata"."Locations" (location_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

GRANT SELECT ON "metadata"."LocationSoilInfos" TO tom, yglinga, jens, lise, wouter, floris, karen, janne, falk, ward, monkey;
