SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."FieldFollowUps" CASCADE;

BEGIN;
CREATE TABLE "inbound"."FieldFollowUps"();

COMMENT ON TABLE "inbound"."FieldFollowUps" IS E'forgotten, but never really forgotten tasks';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_fieldfollowups_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'FieldFollowUps', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "fieldfollowups_wkb_geometry_geom_idx" ON "inbound"."FieldFollowUps" USING GIST ("wkb_geometry");


GRANT USAGE ON SEQUENCE "inbound"."FieldFollowUps_ogc_fid_seq" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;

GRANT SELECT ON SEQUENCE "inbound"."FieldFollowUps_ogc_fid_seq" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT SELECT ON SEQUENCE "inbound"."FieldFollowUps_ogc_fid_seq" TO monkey;

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN followup_id int NOT NULL UNIQUE;
COMMENT ON COLUMN "inbound"."FieldFollowUps".followup_id IS E'follow-up index';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "inbound"."FieldFollowUps".log_creator IS E'(technical) user who created the entry';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN log_creation timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "inbound"."FieldFollowUps".log_creation IS E'(technical) timestamp of creation';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "inbound"."FieldFollowUps".log_user IS E'(technical) user who modified the entry';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN log_update timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "inbound"."FieldFollowUps".log_update IS E'(technical) timestamp of last modification';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN teammember_id smallint;
COMMENT ON COLUMN "inbound"."FieldFollowUps".teammember_id IS E'link to the user who performed the visit';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN issue_date date NOT NULL DEFAULT current_date;
COMMENT ON COLUMN "inbound"."FieldFollowUps".issue_date IS E'description of the issue';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN location varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".location IS E'free reference to the location (database id, watina location, grts address, ...)';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN todo varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".todo IS E'what is to do?';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN activity varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".activity IS E'is this related to an activity? (free text)';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN replacement boolean DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."FieldFollowUps".replacement IS E'mark necessary replacements';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN repair boolean DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."FieldFollowUps".repair IS E'mark necessary repairs';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN desktop_only boolean DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."FieldFollowUps".desktop_only IS E'mark desktop work';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN photo varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".photo IS E'an optional photo of the desaster';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN audio varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".audio IS E'audio message to swear at the world and the circumstances';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN deadline date;
COMMENT ON COLUMN "inbound"."FieldFollowUps".deadline IS E'date to solve this';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN solved_date date;
COMMENT ON COLUMN "inbound"."FieldFollowUps".solved_date IS E'date of the field activity';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN solution_comment varchar;
COMMENT ON COLUMN "inbound"."FieldFollowUps".solution_comment IS E'how was this solved?';

ALTER TABLE "inbound"."FieldFollowUps" ADD COLUMN done boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."FieldFollowUps".done IS E'to check once this task is done';

COMMIT;

-- sequence followup_id
CREATE SEQUENCE "inbound".seq_followup_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."FieldFollowUps".followup_id;
ALTER TABLE "inbound"."FieldFollowUps" ALTER COLUMN followup_id
 SET DEFAULT nextval('inbound.seq_followup_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_followup_id" TO tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;

GRANT SELECT ON SEQUENCE "inbound"."seq_followup_id" TO monkey;

-- foreign key teammember_id
ALTER TABLE "inbound"."FieldFollowUps" DROP CONSTRAINT IF EXISTS fk_TeamMembers_FieldFollowUps CASCADE;
ALTER TABLE "inbound"."FieldFollowUps" ADD CONSTRAINT fk_TeamMembers_FieldFollowUps FOREIGN KEY (teammember_id)
REFERENCES "metadata"."TeamMembers" (teammember_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;


GRANT SELECT ON "inbound"."FieldFollowUps" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT INSERT ON "inbound"."FieldFollowUps" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT UPDATE ON "inbound"."FieldFollowUps" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;
GRANT DELETE ON "inbound"."FieldFollowUps" TO tom, yglinga, jens, lise, wouter, floris, karen, ward;


GRANT SELECT ON "inbound"."FieldFollowUps" TO tester;
GRANT INSERT ON "inbound"."FieldFollowUps" TO tester;
GRANT UPDATE ON "inbound"."FieldFollowUps" TO tester;
GRANT DELETE ON "inbound"."FieldFollowUps" TO tester;
