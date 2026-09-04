-- create schema
-- DROP SCHEMA IF EXISTS "archive" CASCADE;

CREATE SCHEMA "archive";
ALTER SCHEMA "archive" OWNER TO yoda;

GRANT USAGE ON SCHEMA "archive" TO monkey;

SET search_path TO pg_catalog,public,"outbound","inbound","metadata","archive";


-- create table archive.ReplacementData;
SET standard_conforming_strings = ON;

DROP TABLE IF EXISTS "archive"."ReplacementData" CASCADE;

BEGIN;
CREATE TABLE "archive"."ReplacementData"();

COMMENT ON TABLE "archive"."ReplacementData" IS E'storing info about replacements (temporary solution)';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN replacementdata_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "archive"."ReplacementData".replacementdata_id IS E'location info index (technical)';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN type varchar NOT NULL;
COMMENT ON COLUMN "archive"."ReplacementData".type IS E'type (code), our latest best assessment';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN grts_address int NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "archive"."ReplacementData".grts_address IS E'GRTS address (`original`, i.e. prior to replacements)';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN grts_address_replacement int NOT NULL CHECK (grts_address_replacement > 0);
COMMENT ON COLUMN "archive"."ReplacementData".grts_address_replacement IS E'GRTS address (`final`, i.e. after replacements)';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN replacement_rank smallint NOT NULL CHECK (replacement_rank >= 0);
COMMENT ON COLUMN "archive"."ReplacementData".replacement_rank IS E'replacement preference order, can be zero if original is retained for one type';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN is_replaced boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "archive"."ReplacementData".is_replaced IS E'indicator whether we used a replacement location';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN new_location_id int NOT NULL;
COMMENT ON COLUMN "archive"."ReplacementData".new_location_id IS E'location index post';

ALTER TABLE "archive"."ReplacementData" ADD COLUMN new_samplelocation_id int NOT NULL;
COMMENT ON COLUMN "archive"."ReplacementData".new_samplelocation_id IS E'sample location index post';

COMMIT;

-- sequence replacementdata_id
CREATE SEQUENCE "archive".seq_replacementdata_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "archive"."ReplacementData".replacementdata_id;
ALTER TABLE "archive"."ReplacementData" ALTER COLUMN replacementdata_id
 SET DEFAULT nextval('archive.seq_replacementdata_id'::regclass);

GRANT USAGE ON SEQUENCE "archive"."seq_replacementdata_id" TO monkey;

GRANT SELECT ON SEQUENCE "archive"."seq_replacementdata_id" TO monkey;

GRANT SELECT ON "archive"."ReplacementData" TO monkey;
