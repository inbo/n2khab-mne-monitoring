---
aliases:
  - kick-off loceval of aquatic habitat types
tags:
  - locevaldb
  - aquatictypes
  - TargetPoints
  - SamplingPoints
  - YOLO
started: 2026-06-26
finished:
execution:
  - FM
status: false
---

goals:
- recent (intermediate) #REP data deployed on #locevaldb
- LOCEVALAQ in database and in #QGIS project -> #AquaticTypesVisits 
	+ `crassula_was_here`
- SAMPLPOINT activity / #TargetPoints implemented
- extracurricular locevals - location-independent but structurally identical to real terrestrial/aquatic #loceval

# prep
+ merge latest [`snippets_activate_surf`](https://github.com/inbo/n2khab-mne-monitoring/tree/snippets_activate_surf)
+ load latest RData from `rep_exports/dev/20260625_01_rep_8354c14a_snippets_60e19da`

# LOCEVALAQ database layout
much was prepared [[timeline/2026-06-18#Major Structural Adjustments on locevaldb|2026-06-18]]

+ restore/sync `-staging` mirror (was still containing a live backup before structural adjustments)


+ #locevaldb and #mnmgwdb rename `scheme_ps_targetpanels` to `scheme_ps_targetpanels_served` but keep the old name in #views
```sql
ALTER TABLE "metadata"."SampleUnits" 
RENAME scheme_ps_targetpanels TO scheme_ps_targetpanels_served
;
```

+ move `replacement_recovery_notes` to #TerrestrialTypesVisits
```sql
SELECT DISTINCT replacement_recovery_notes, count(*) AS N
FROM "inbound"."TerrestrialTypesVisits" 
GROUP BY replacement_recovery_notes;

BEGIN;
ALTER TABLE "inbound"."Visits" 
RENAME replacement_recovery_notes TO replacement_recovery_notes_obsolete
;

ALTER TABLE "inbound"."TerrestrialTypesVisits" 
ADD COLUMN replacement_recovery_notes varchar; 
COMMENT ON COLUMN "inbound"."TerrestrialTypesVisits".replacement_recovery_notes IS E'extra recovery notes for local replacements';

UPDATE "inbound"."TerrestrialTypesVisits"
  SET replacement_recovery_notes = replacement_recovery_notes_obsolete;

SELECT DISTINCT replacement_recovery_notes, count(*) AS N
FROM "inbound"."TerrestrialTypesVisits" 
GROUP BY replacement_recovery_notes;

COMMIT;


SELECT DISTINCT replacement_recovery_notes, count(*) AS N
FROM "inbound"."TerrestrialTypesVisits" 
GROUP BY replacement_recovery_notes;
```


+ new table #TargetPoints
```sql
SET standard_conforming_strings = ON;

DROP TABLE IF EXISTS "inbound"."TargetPoints" CASCADE;

BEGIN;
CREATE TABLE "inbound"."TargetPoints"();
COMMENT ON TABLE "inbound"."TargetPoints" IS E'points selected as target for subsequent activities (e.g. chemical sampling of aquatic habitat types)';

ALTER TABLE "inbound"."TargetPoints" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_targetpoints_fid" PRIMARY KEY;
SELECT AddGeometryColumn('inbound', 'TargetPoints', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "targetpoints_wkb_geometry_geom_idx" ON "inbound"."TargetPoints" USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE "inbound"."TargetPoints_ogc_fid_seq" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."TargetPoints_ogc_fid_seq" TO viewer_mnmdb;

ALTER TABLE "inbound"."TargetPoints" ADD COLUMN targetpoint_id int NOT NULL UNIQUE; 
COMMENT ON COLUMN "inbound"."TargetPoints".targetpoint_id IS E'target point technical index';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN log_creator varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."TargetPoints".log_creator IS E'(technical) user who created the entry';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN log_creation timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."TargetPoints".log_creation IS E'(technical) timestamp of creation';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user; 
COMMENT ON COLUMN "inbound"."TargetPoints".log_user IS E'(technical) user who modified the entry';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN log_update timestamp(3) NOT NULL DEFAULT current_timestamp(3); 
COMMENT ON COLUMN "inbound"."TargetPoints".log_update IS E'(technical) timestamp of last modification';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN date_selection date; 
COMMENT ON COLUMN "inbound"."TargetPoints".date_selection IS E'the date of sampling point selection (preference for the newest)';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN type varchar(16); 
COMMENT ON COLUMN "inbound"."TargetPoints".type IS E'habitat type';
ALTER TABLE "inbound"."TargetPoints" ADD COLUMN notes text; 
COMMENT ON COLUMN "inbound"."TargetPoints".notes IS E'extra notes about the sampling point';

COMMIT;

-- sequence targetpoint_id
CREATE SEQUENCE "inbound".seq_targetpoint_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."TargetPoints".targetpoint_id;
ALTER TABLE "inbound"."TargetPoints" ALTER COLUMN targetpoint_id
 SET DEFAULT nextval('inbound.seq_targetpoint_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_targetpoint_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_targetpoint_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."TargetPoints" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."TargetPoints" TO user_loceval;
GRANT UPDATE ON "inbound"."TargetPoints" TO user_loceval;
GRANT DELETE ON "inbound"."TargetPoints" TO user_loceval;


```


+ update views accordingly
	+ `loceval_OrthophotoAssessment.sql`
	+ `loceval_FieldworkPlanning.sql`
	+ `loceval_LocationEvaluation.sql`
	+ `loceval_ReplacementOngoing.sql` (only apply to #TerrestrialTypesVisits )


+ post processing
```sql
ALTER TABLE "inbound"."Visits" 
DROP COLUMN replacement_recovery_notes_obsolete CASCADE
;

```