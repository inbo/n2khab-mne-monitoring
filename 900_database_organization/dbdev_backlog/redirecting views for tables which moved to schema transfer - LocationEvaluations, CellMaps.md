---
aliases:
tags:
  - CellMaps
  - rename
  - schema
  - mnmgwdb
  - constraints
started: 2026-09-09
finished:
execution:
  - FM
status: false
priority:
---

side task: adding the #primarykey constraints for #InstallationVisits, #SamplingVisits, #PositioningVisits 


```sql
BEGIN;

ALTER TABLE "outbound"."LocationEvaluations" SET SCHEMA "transfer";
ALTER TABLE "outbound"."CellMaps" SET SCHEMA "transfer";

DROP VIEW IF EXISTS "outbound"."LocationEvaluations";
CREATE VIEW "outbound"."LocationEvaluations" AS
SELECT * FROM "transfer"."LocationEvaluations";

DROP VIEW IF EXISTS "outbound"."CellMaps";
CREATE VIEW "outbound"."CellMaps" AS
SELECT * FROM "transfer"."CellMaps";


SET standard_conforming_strings = ON;


DROP TABLE IF EXISTS "inbound"."OtherVisits" CASCADE;

CREATE TABLE "inbound"."OtherVisits"()
INHERITS ("inbound"."Visits")
;

COMMENT ON TABLE "inbound"."OtherVisits" IS E'remainder of Visits not otherwise classified';

ALTER TABLE "inbound"."OtherVisits" ADD COLUMN othervisit_id int NOT NULL PRIMARY KEY; 
COMMENT ON COLUMN "inbound"."OtherVisits".othervisit_id IS E'technical index (extra, on top of visit_id)';

-- sequence othervisit_id
CREATE SEQUENCE "inbound".seq_othervisit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."OtherVisits".othervisit_id;
ALTER TABLE "inbound"."OtherVisits" ALTER COLUMN othervisit_id
 SET DEFAULT nextval('inbound.seq_othervisit_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_othervisit_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_othervisit_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."OtherVisits" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."OtherVisits" TO user_gwdb;
GRANT UPDATE ON "inbound"."OtherVisits" TO user_gwdb;
GRANT DELETE ON "inbound"."OtherVisits" TO user_gwdb;

INSERT INTO "inbound"."OtherVisits" 
  (
    log_user,
    log_update,
    fieldcalendar_id,
    sampleunit_id,
    location_id,
    sspstapa_id,
    grts_address,
    stratum,
    activity_group_id,
    date_start,
    teammember_id,
    date_visit,
    notes,
    photo,
    issues,
    visit_done,
    archive_version_id
  )
SELECT 
    log_user,
    log_update,
    fieldcalendar_id,
    sampleunit_id,
    location_id,
    sspstapa_id,
    grts_address,
    stratum,
    activity_group_id,
    date_start,
    teammember_id,
    date_visit,
    notes,
    photo,
    issues,
    visit_done,
    archive_version_id
FROM "inbound"."Visits"
;


DROP TRIGGER IF EXISTS log_othervisits ON "inbound"."OtherVisits";
CREATE TRIGGER log_othervisits
BEFORE UPDATE ON "inbound"."OtherVisits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();


DELETE 
-- SELECT * 
FROM ONLY "inbound"."Visits"
WHERE fieldcalendar_id IN (
  SELECT DISTINCT fieldcalendar_id
  FROM ONLY "inbound"."OtherVisits"
);

-- convert columns to primary keys
ALTER TABLE "inbound"."InstallationVisits" ADD CONSTRAINT "InstallationVisits_pkey" PRIMARY KEY (installationvisit_id);
ALTER TABLE "inbound"."SamplingVisits" ADD CONSTRAINT "SamplingVisits_pkey" PRIMARY KEY (samplingvisit_id);
ALTER TABLE "inbound"."PositioningVisits" ADD CONSTRAINT "PositioningVisits_pkey" PRIMARY KEY (positioningvisit_id);
-- othervisit_id

COMMIT;

```
- [ ] move all data from "inbound"."Visits" to "inbound"."OtherVisits"
	- check QGIS project // filters etc

adjust views! (Fw, FwP, LocevalInfo, ...)

Check that (especially #CellMaps and #OtherVisits ) are well-linked in #QGIS 