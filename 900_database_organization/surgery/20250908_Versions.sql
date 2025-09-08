SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"metadata";

DROP TABLE IF EXISTS "metadata"."Versions" CASCADE;

BEGIN;
CREATE TABLE "metadata"."Versions"();

COMMENT ON TABLE "metadata"."Versions" IS E'storing the POC versions which caused the data';

ALTER TABLE "metadata"."Versions" ADD COLUMN version_id smallint NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "metadata"."Versions".version_id IS E'version index (technical)';

ALTER TABLE "metadata"."Versions" ADD COLUMN version_tag varchar NOT NULL;
COMMENT ON COLUMN "metadata"."Versions".version_tag IS E'tag version in human-readable format';

ALTER TABLE "metadata"."Versions" ADD COLUMN data_iteration integer;
COMMENT ON COLUMN "metadata"."Versions".data_iteration IS E'repeated data updates without version tag change';

ALTER TABLE "metadata"."Versions" ADD COLUMN date_applied integer;
COMMENT ON COLUMN "metadata"."Versions".date_applied IS E'date when the data was uploaded';

ALTER TABLE "metadata"."Versions" ADD COLUMN notes text;
COMMENT ON COLUMN "metadata"."Versions".notes IS E'relevant notes on this change';

COMMIT;

-- sequence version_id
CREATE SEQUENCE "metadata".seq_version_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "metadata"."Versions".version_id;
ALTER TABLE "metadata"."Versions" ALTER COLUMN version_id
 SET DEFAULT nextval('metadata.seq_version_id'::regclass);

GRANT USAGE ON SEQUENCE "metadata"."seq_version_id" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT SELECT ON SEQUENCE "metadata"."seq_version_id" TO monkey;
GRANT SELECT ON "metadata"."Versions" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;


-- GRANT USAGE ON SEQUENCE "metadata"."seq_version_id" TO tester;
-- GRANT SELECT ON "metadata"."Versions" TO tester;

-- ALTER TABLE "outbound"."SampleLocations" DROP COLUMN to_archive;
-- ALTER TABLE "outbound"."FieldworkCalendar" DROP COLUMN to_archive;
-- ALTER TABLE "inbound"."Visits" DROP COLUMN to_archive;

ALTER TABLE "outbound"."SampleLocations" ADD COLUMN to_archive boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."SampleLocations".to_archive IS E'(technical) flagged for archive';

ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN to_archive boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".to_archive IS E'(technical) flagged for archive';

ALTER TABLE "inbound"."Visits" ADD COLUMN to_archive boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".to_archive IS E'(technical) flagged for archive';
