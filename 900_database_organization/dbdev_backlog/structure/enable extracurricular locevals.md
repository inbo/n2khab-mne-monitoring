---
aliases:
  - REPless locevals to kickstart SURF activities
tags:
  - locevaldb
  - ExtraLocevals
started: 2026-06-26
finished: 2026-06-26
execution:
  - FM
status: true
---

location-independent but structurally identical to real terrestrial/aquatic #loceval
these must later be associated with #REP FAG calendar items

+ design (=copy together) a table with all loceval info, starting with columns of `loceval_LocevalFieldwork.sql`

```sql

SET standard_conforming_strings = ON;

DROP TABLE IF EXISTS "inbound"."ExtraLocevals" CASCADE;

BEGIN;
CREATE TABLE "inbound"."ExtraLocevals"();

COMMENT ON TABLE "inbound"."ExtraLocevals" IS E'extra locevals not noted in the REP, as an exceptional way to capture biotic information in times of tumult';

ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_extralocevals_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'ExtraLocevals', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "extralocevals_wkb_geometry_geom_idx" ON "inbound"."ExtraLocevals" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "inbound"."ExtraLocevals_ogc_fid_seq" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."ExtraLocevals_ogc_fid_seq" TO viewer_mnmdb;

ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN extraloceval_id int NOT NULL UNIQUE; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".extraloceval_id IS E'visit index';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".log_creator IS E'(technical) user who created the entry';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN log_creation timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."ExtraLocevals".log_creation IS E'(technical) timestamp of creation';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".log_user IS E'(technical) user who modified the entry';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN log_update timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."ExtraLocevals".log_update IS E'(technical) timestamp of last modification';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN teammember_id smallint; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".teammember_id IS E'link to the user who performed the visit';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN date_visit date; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".date_visit IS E'date of the field activity';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN show_aquatictypevisits boolean; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".show_aquatictypevisits IS E'flag aquatic locevals (default: terrestrial)';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN type_expected varchar; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".type_expected IS E'type, as planned in the sampling procedure';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN type_assessed varchar; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".type_assessed IS E'referring to "N2kHabTypes"."type"; any corrections from previous evaluation';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN type_is_absent boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".type_is_absent IS E'unsuccessful local replacement / target type not found';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN is_well_developed_type boolean; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".is_well_developed_type IS E'register cells which contain a well developed type, for info to adjacent teams/location research';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN gps_type varchar; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".gps_type IS E'which type of GPS was used';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN gps_accuracy_cm double precision; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".gps_accuracy_cm IS E'measurement accuracy of the RTK GPS, expressed in centimeters';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN notes text; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".notes IS E'Free text notes from the previous visits';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN photo varchar; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".photo IS E'an optional photo of the site or noteworthy thing';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN issues boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".issues IS E'highlight issues (use notes to specify)';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN samplingpoint_selection_done boolean; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".samplingpoint_selection_done IS E'check whether a point was selected for chemical sampling';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN crassula_was_here boolean; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".crassula_was_here IS E'flag aquatic units which are home to invasive Crassula helmsii';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN recovery_hints varchar; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".recovery_hints IS E'notes on how to find back the marking';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN accessibility_inaccessible boolean; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".accessibility_inaccessible IS E'tag inaccessible locations';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN accessibility_revisit date; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".accessibility_revisit IS E'anticipate accessibility change';
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN visit_done boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ExtraLocevals".visit_done IS E'indicate if all tasks were successfully executed';

COMMIT;

-- sequence extraloceval_id
CREATE SEQUENCE "inbound".seq_extraloceval_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."ExtraLocevals".extraloceval_id;
ALTER TABLE "inbound"."ExtraLocevals" ALTER COLUMN extraloceval_id
 SET DEFAULT nextval('inbound.seq_extraloceval_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_extraloceval_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_extraloceval_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."ExtraLocevals" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."ExtraLocevals" TO user_loceval;
GRANT UPDATE ON "inbound"."ExtraLocevals" TO user_loceval;
GRANT DELETE ON "inbound"."ExtraLocevals" TO user_loceval;


DROP TRIGGER IF EXISTS log_extralocevals ON "inbound"."ExtraLocevals";
CREATE TRIGGER log_extralocevals
BEFORE UPDATE ON "inbound"."ExtraLocevals"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

```


+ [x] added a qgis layer with style