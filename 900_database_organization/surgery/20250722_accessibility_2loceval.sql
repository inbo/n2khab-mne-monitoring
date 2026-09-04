
-- persistent -> give extra locations
-- parallel to LocationAssessments
-- adjust views AND split update rules

-- also MOVE landowner


-- ++ update rules
DROP TRIGGER IF EXISTS log_locationinfos ON "inbound"."LocationInfos";
CREATE TRIGGER log_locationinfos
BEFORE UPDATE ON "inbound"."LocationInfos"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

-- (1) backup to `testing` with *_db* structure
-- (2) establish `staging` with *_dev* structure


DROP TABLE IF EXISTS "outbound"."LocationInfos" CASCADE;

BEGIN;
CREATE TABLE "outbound"."LocationInfos"();
COMMENT ON TABLE "outbound"."LocationInfos" IS E'persistent infos about specific locations, e.g. accessibility; synced between loceval and mnmgwdb';

ALTER TABLE "outbound"."LocationInfos" ADD COLUMN locationinfo_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "outbound"."LocationInfos".locationinfo_id IS E'location info index (technical)';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "outbound"."LocationInfos".log_creator IS E'(technical) user who created the entry';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN log_creation timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "outbound"."LocationInfos".log_creation IS E'(technical) timestamp of creation';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "outbound"."LocationInfos".log_user IS E'(technical) user who modified the entry';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN log_update timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "outbound"."LocationInfos".log_update IS E'(technical) timestamp of last modification';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN location_id int NOT NULL;
COMMENT ON COLUMN "outbound"."LocationInfos".location_id IS E'the technical sequence of all locations';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN grts_address int NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "outbound"."LocationInfos".grts_address IS E'GRTS address (`final`, i.e. after prior replacements)';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN landowner varchar;
COMMENT ON COLUMN "outbound"."LocationInfos".landowner IS E'reference to the land owner';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN accessibility_inaccessible boolean;
COMMENT ON COLUMN "outbound"."LocationInfos".accessibility_inaccessible IS E'tag inaccessible locations';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN accessibility_revisit date;
COMMENT ON COLUMN "outbound"."LocationInfos".accessibility_revisit IS E'anticipate accessibility change';
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN recovery_hints varchar;
COMMENT ON COLUMN "outbound"."LocationInfos".recovery_hints IS E'notes on how to find back the marking';
COMMIT;

-- sequence locationinfo_id
CREATE SEQUENCE "outbound".seq_locationinfo_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "outbound"."LocationInfos".locationinfo_id;
ALTER TABLE "outbound"."LocationInfos" ALTER COLUMN locationinfo_id
 SET DEFAULT nextval('outbound.seq_locationinfo_id'::regclass);

GRANT USAGE ON SEQUENCE "outbound"."seq_locationinfo_id" TO tom;
GRANT USAGE ON SEQUENCE "outbound"."seq_locationinfo_id" TO ward;
GRANT USAGE ON SEQUENCE "outbound"."seq_locationinfo_id" TO floris;
GRANT USAGE ON SEQUENCE "outbound"."seq_locationinfo_id" TO karen;
GRANT USAGE ON SEQUENCE "outbound"."seq_locationinfo_id" TO monkey;
GRANT SELECT ON SEQUENCE "outbound"."seq_locationinfo_id" TO monkey;

GRANT SELECT ON "outbound"."LocationInfos" TO tom;
GRANT SELECT ON "outbound"."LocationInfos" TO ward;
GRANT SELECT ON "outbound"."LocationInfos" TO floris;
GRANT SELECT ON "outbound"."LocationInfos" TO karen;
GRANT SELECT ON "outbound"."LocationInfos" TO monkey;

GRANT INSERT ON "outbound"."LocationInfos" TO tom;
GRANT UPDATE ON "outbound"."LocationInfos" TO tom;
GRANT DELETE ON "outbound"."LocationInfos" TO tom;
GRANT INSERT ON "outbound"."LocationInfos" TO ward;
GRANT UPDATE ON "outbound"."LocationInfos" TO ward;
GRANT DELETE ON "outbound"."LocationInfos" TO ward;

GRANT INSERT ON "outbound"."LocationInfos" TO floris;
GRANT UPDATE ON "outbound"."LocationInfos" TO floris;
GRANT DELETE ON "outbound"."LocationInfos" TO floris;

GRANT INSERT ON "outbound"."LocationInfos" TO karen;
GRANT UPDATE ON "outbound"."LocationInfos" TO karen;
GRANT DELETE ON "outbound"."LocationInfos" TO karen;




-- adjust views:
--  FieldworkPlanning
--  LocationEvaluation
--  gwTransfer


-- update data
--  carefully; in the upload script

-- also migrate `recovery_hints`
UPDATE "outbound"."LocationInfos" AS INFO
SET    recovery_hints = UNIT.recovery_hints
FROM   "outbound"."SampleUnits" AS UNIT
WHERE  INFO.location_id = UNIT.location_id
;
SELECT * FROM "outbound"."LocationInfos" WHERE recovery_hints IS NOT NULL;

-- remove columns
SELECT DISTINCT accessibility_inaccessible FROM "outbound"."SampleUnits";
ALTER TABLE "outbound"."SampleUnits" DROP COLUMN accessibility_inaccessible;

SELECT DISTINCT accessibility_revisit FROM "outbound"."SampleUnits";
ALTER TABLE "outbound"."SampleUnits" DROP COLUMN accessibility_revisit;

SELECT DISTINCT recovery_hints FROM "outbound"."SampleUnits";
ALTER TABLE "outbound"."SampleUnits" DROP COLUMN recovery_hints;


-- recovery_hints to database sync script

-- database sync of LocationInfos (new script activated)
