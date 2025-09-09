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

ALTER TABLE "outbound"."SampleUnits" DROP COLUMN IF EXISTS archive_version_id;
ALTER TABLE "outbound"."SampleUnits" ADD COLUMN archive_version_id smallint DEFAULT NULL;
COMMENT ON COLUMN "outbound"."SampleUnits".archive_version_id IS E'(technical) archived SampleUnits are retained but flagged';
-- OR
ALTER TABLE "outbound"."SampleLocations" DROP COLUMN IF EXISTS archive_version_id;
ALTER TABLE "outbound"."FieldworkCalendar" DROP COLUMN IF EXISTS archive_version_id;
ALTER TABLE "inbound"."Visits" DROP COLUMN IF EXISTS archive_version_id;

ALTER TABLE "outbound"."SampleLocations" ADD COLUMN archive_version_id smallint DEFAULT NULL;
COMMENT ON COLUMN "outbound"."SampleLocations".archive_version_id IS E'(technical) archived SampleLocations are retained but flagged';
-- foreign key archive_version_id
ALTER TABLE "outbound"."SampleLocations" DROP CONSTRAINT IF EXISTS fk_Versions_SampleLocations CASCADE;
ALTER TABLE "outbound"."SampleLocations" ADD CONSTRAINT fk_Versions_SampleLocations FOREIGN KEY (archive_version_id)
REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;



ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN archive_version_id smallint DEFAULT NULL;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".archive_version_id IS E'(technical) flag archived calendar entries';
-- foreign key archive_version_id
ALTER TABLE "outbound"."FieldworkCalendar" DROP CONSTRAINT IF EXISTS fk_Versions_FieldworkCalendar CASCADE;
ALTER TABLE "outbound"."FieldworkCalendar" ADD CONSTRAINT fk_Versions_FieldworkCalendar FOREIGN KEY (archive_version_id)
REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "inbound"."Visits" ADD COLUMN archive_version_id smallint DEFAULT NULL;
COMMENT ON COLUMN "inbound"."Visits".archive_version_id IS E'(technical) flagged archived visits';
-- foreign key archive_version_id
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_Versions_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_Versions_Visits FOREIGN KEY (archive_version_id)
REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;


-- just for testing on -staging mirror
-- # ALTER TABLE "metadata"."Protocols" ADD COLUMN archive_version_id smallint DEFAULT NULL;
-- # COMMENT ON COLUMN "metadata"."Protocols".archive_version_id IS E'TESTING';
-- # -- foreign key archive_version_id
-- # ALTER TABLE "metadata"."Protocols" DROP CONSTRAINT IF EXISTS fk_Versions_Visits CASCADE;
-- # ALTER TABLE "metadata"."Protocols" ADD CONSTRAINT fk_Versions_Protocols FOREIGN KEY (archive_version_id)
-- # REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
-- # ON DELETE SET NULL ON UPDATE CASCADE;
-- #
-- # ALTER TABLE "metadata"."Protocols" DROP COLUMN archive_version_id;
