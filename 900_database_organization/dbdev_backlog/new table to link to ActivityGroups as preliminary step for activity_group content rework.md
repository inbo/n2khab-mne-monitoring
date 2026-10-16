---
aliases:
tags:
  - ActivityGroups
  - GroupedActivities
started: 2026-10-16
finished:
execution:
  - FM
status: false
priority:
---


## Views

## Scripts

TODO: `411_update_grouped_activities.qmd`

## Structure

```sql
COMMENT ON COLUMN "metadata"."GroupedActivities".archive_version_id IS E'(technical) flag archived activities';

SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"metadata";

DROP VIEW IF EXISTS "metadata"."ActivityGroups" CASCADE;
DROP TABLE IF EXISTS "metadata"."ActivityGroups" CASCADE;

BEGIN;
CREATE TABLE "metadata"."ActivityGroups"()

;

COMMENT ON TABLE "metadata"."ActivityGroups" IS E'activity groups';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN activity_group_id smallint NOT NULL;
COMMENT ON COLUMN "metadata"."ActivityGroups".activity_group_id IS E'activity group index (technical)';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN activity_group varchar NOT NULL;
COMMENT ON COLUMN "metadata"."ActivityGroups".activity_group IS E'label for a group of activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_datacollection_method boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_datacollection_method IS E'flag: datacollection methods';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_field_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_field_activity IS E'flag: field activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_prep_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_prep_activity IS E'flag: preparative activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_lab_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_lab_activity IS E'flag: laboratory activity';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_loceval_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_loceval_activity IS E'flag: loceval activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_gw_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_gw_activity IS E'flag: groundwater scheme activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN is_surf_activity boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".is_surf_activity IS E'flag: surface water scheme activities';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN fag_is_auxiliary boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".fag_is_auxiliary IS E'FAGs that are not linked one-to-one to the collection of data that apply to a specific point in time (sampling, measuring), but that potentially apply to a time series of data';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN fag_is_preponable boolean;
COMMENT ON COLUMN "metadata"."ActivityGroups".fag_is_preponable IS E'subset of auxiliary FAGs which can be preponed or prepended';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN protocol_id smallint;
COMMENT ON COLUMN "metadata"."ActivityGroups".protocol_id IS E'referencing the protocol table';

ALTER TABLE "metadata"."ActivityGroups" ADD COLUMN archive_version_id smallint;
COMMENT ON COLUMN "metadata"."ActivityGroups".archive_version_id IS E'(technical) flag archived activity groups';

COMMIT;

-- foreign key protocol_id
ALTER TABLE "metadata"."ActivityGroups" DROP CONSTRAINT IF EXISTS fk_Protocols_ActivityGroups CASCADE;
ALTER TABLE "metadata"."ActivityGroups" ADD CONSTRAINT fk_Protocols_ActivityGroups FOREIGN KEY (protocol_id)
REFERENCES "metadata"."Protocols" (protocol_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

-- foreign key archive_version_id
ALTER TABLE "metadata"."ActivityGroups" DROP CONSTRAINT IF EXISTS fk_Versions_ActivityGroups CASCADE;
ALTER TABLE "metadata"."ActivityGroups" ADD CONSTRAINT fk_Versions_ActivityGroups FOREIGN KEY (archive_version_id)
REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

GRANT SELECT ON "metadata"."ActivityGroups" TO viewer_mnmdb;

```


```sql

BEGIN;

INSERT INTO "metadata"."ActivityGroups"
(
  activity_group_id,
  activity_group,
  is_datacollection_method,
  is_field_activity,
  is_prep_activity,
  is_lab_activity,
  is_loceval_activity,
  is_gw_activity,
  is_surf_activity,
  fag_is_auxiliary,
  fag_is_preponable,
  protocol_id,
  archive_version_id
 )
SELECT DISTINCT
  activity_group_id,
  activity_group,
  is_datacollection_method,
  is_field_activity,
  is_prep_activity,
  is_lab_activity,
  is_loceval_activity,
  is_gw_activity,
  is_surf_activity,
  fag_is_auxiliary,
  fag_is_preponable,
  protocol_id,
  archive_version_id
FROM "metadata"."GroupedActivities"
WHERE archive_version_id IS NULL
ORDER BY activity_group_id ASC
;


-- all duplicates were caused by protocol_id inconsistency
-- SELECT * FROM
DELETE FROM
"metadata"."ActivityGroups"
WHERE activity_group IN (
SELECT DISTINCT activity_group
FROM "metadata"."ActivityGroups"
GROUP BY activity_group
HAVING COUNT(*) > 1
)
AND protocol_id IS NULL;


SELECT DISTINCT activity_group_id, activity_group
FROM "metadata"."ActivityGroups"
GROUP BY activity_group_id, activity_group
HAVING COUNT(*) > 1
;

SELECT DISTINCT fieldcalendar_id
FROM "outbound"."FieldCalendars"
WHERE activity_group_id NOT IN
(SELECT activity_group_id
FROM "metadata"."ActivityGroups"
);


ALTER TABLE "metadata"."ActivityGroups" ADD CONSTRAINT constrain_activity_group_id_unique UNIQUE (activity_group_id);
ALTER TABLE "metadata"."ActivityGroups" ADD CONSTRAINT constrain_activity_group_unique UNIQUE (activity_group);

COMMIT;
```


```sql
\d "metadata"."ActivityGroups"
```