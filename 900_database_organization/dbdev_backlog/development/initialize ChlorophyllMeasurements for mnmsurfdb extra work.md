---
aliases:
  - init ChlorophyllMeasurements
tags:
  - mnmsurfdb
  - ChlorophyllMeasurements
started: 2026-08-12
finished: 2026-08-12
execution:
  - FM
status: true
priority:
---

There are additional "Chlorophyll measurements", planned ad hoc by @NDT.
I create a map layer for QGIS with simple database table backend.


```sql
ALTER TABLE "inbound"."SamplingPoints" ADD COLUMN purpose_chlorophyll boolean DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."SamplingPoints".purpose_chlorophyll IS E'flag sample points marked for chlorophyll measurements';


SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."ChlorophyllMeasurements" CASCADE;

BEGIN;
CREATE TABLE "inbound"."ChlorophyllMeasurements"();

COMMENT ON TABLE "inbound"."ChlorophyllMeasurements" IS E'extra field experiment obtaining chlorophyll measurements';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN chlorophyllmeasurement_id int NOT NULL PRIMARY KEY; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".chlorophyllmeasurement_id IS E'visit index';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".log_user IS E'(technical) user who modified the entry';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN log_update timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".log_update IS E'(technical) timestamp of last modification';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN location_id int; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".location_id IS E'the technical sequence of all locations, put here for quick join';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0); 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".grts_address IS E'GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN stratum varchar NOT NULL; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".stratum IS E'strata (optional/informative)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN iteration int NOT NULL; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".iteration IS E'counting chlorophyll capturings';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN pool_in_rep boolean; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".pool_in_rep IS E'whether the pool is part of the REP sample';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN date_first_visit date; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".date_first_visit IS E'start of the panel activity sequence (included to keep recurrent visits unique)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN infos text; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".infos IS E'infos about the target location';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN teammember_id smallint; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".teammember_id IS E'link to the user who performed the visit';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN datetime_visit timestamp(0); 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".datetime_visit IS E'date and time of the field activity';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN notes text; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".notes IS E'Free text notes from the previous visits';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN issues boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".issues IS E'highlight issues (use notes to specify)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN photo varchar; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".photo IS E'mandatory photo of the sampling site at target location';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN watertemperature_celsius double precision CHECK (watertemperature_celsius >= -273.15); 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".watertemperature_celsius IS E'water temperature at the sampling spot';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater1_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater1_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater1_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater1_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater1_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater1_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater2_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater2_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater2_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater2_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater2_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater2_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater3_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater3_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater3_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater3_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_freewater3_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_freewater3_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket1_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket1_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket1_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket1_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket1_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket1_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket2_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket2_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket2_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket2_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket2_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket2_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket3_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket3_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket3_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket3_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_bregt_bucket3_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_bregt_bucket3_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket1_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket1_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket1_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket1_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket1_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket1_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket2_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket2_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket2_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket2_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket2_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket2_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket3_totalchl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket3_totalchl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket3_cyano double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket3_cyano IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN torch_kul_bucket3_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".torch_kul_bucket3_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet1_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet1_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet1_pc double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet1_pc IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet1_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet1_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet1_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet1_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet2_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet2_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet2_pc double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet2_pc IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet2_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet2_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet2_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet2_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet3_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet3_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_cuvet3_pc double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_cuvet3_pc IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet3_turb double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet3_turb IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN fluo_ldm_turb_cuvet3_chl double precision; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".fluo_ldm_turb_cuvet3_chl IS E'(repeated measurements)';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN samplingpoint_marked boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".samplingpoint_marked IS E'check that the sampling point was marked on the map';

ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD COLUMN visit_done boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "inbound"."ChlorophyllMeasurements".visit_done IS E'filter column for locations which have already been visited';

COMMIT;

-- sequence chlorophyllmeasurement_id
CREATE SEQUENCE "inbound".seq_chlorophyllmeasurement_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."ChlorophyllMeasurements".chlorophyllmeasurement_id;
ALTER TABLE "inbound"."ChlorophyllMeasurements" ALTER COLUMN chlorophyllmeasurement_id
 SET DEFAULT nextval('inbound.seq_chlorophyllmeasurement_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_chlorophyllmeasurement_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_chlorophyllmeasurement_id" TO viewer_mnmdb;

-- foreign key teammember_id
ALTER TABLE "inbound"."ChlorophyllMeasurements" DROP CONSTRAINT IF EXISTS fk_TeamMembers_ChlorophyllMeasurements CASCADE;
ALTER TABLE "inbound"."ChlorophyllMeasurements" ADD CONSTRAINT fk_TeamMembers_ChlorophyllMeasurements FOREIGN KEY (teammember_id)
REFERENCES "metadata"."TeamMembers" (teammember_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

GRANT SELECT ON "inbound"."ChlorophyllMeasurements" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."ChlorophyllMeasurements" TO user_surfdb;
GRANT UPDATE ON "inbound"."ChlorophyllMeasurements" TO user_surfdb;
GRANT DELETE ON "inbound"."ChlorophyllMeasurements" TO user_surfdb;

-- some bug on first insert
SELECT setval('inbound.seq_chlorophyllmeasurement_id', 1);

\d "inbound"."ChlorophyllMeasurements"

```

```sql
DROP TRIGGER IF EXISTS log_chlorophyllmeasurements ON "inbound"."ChlorophyllMeasurements";
CREATE TRIGGER log_chlorophyllmeasurements
BEFORE UPDATE ON "inbound"."ChlorophyllMeasurements"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

```


create a #view `inbound.Chlorophyll` which joins #ChlorophyllMeasurements with #Locations
and (in theory) copy it to the right [[locations/structure sheets|structure sheet]]


## qgis
draft, style, test, distribute.
[[timeline/2026-08-14|2026-08-14]]