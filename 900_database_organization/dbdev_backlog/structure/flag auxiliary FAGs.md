---
aliases:
tags:
  - activities
  - fieldwork
started: 2026-03-19
finished: 2026-03-19
execution:
  - "#FM"
status: true
---

*new auxiliary FAG flag tag*

## Definition

> FAGs that are _not_ linked one-to-one to the collection of data that apply to a specific point in time (sampling, measuring), but that potentially apply to a time series of data.

```r
fag_is_auxiliary = str_detect( field_activity_group, "LOCEVAL|INST|SPATPOSIT|SAMPLPOINT|LEVREADDIVER" )
fag_is_preponable = str_detect( field_activity_group, "LOCEVAL|INST|SPATPOSIT|SAMPLPOINT" )
```
*edit [[timeline/2026-06-23|2026-06-23]]: add `*SAMPLPOINT` / confirmed with #FV.*

overview:
```sql
SELECT 
activity_group, activity, is_loceval_activity, is_gw_activity, fag_is_auxiliary, fag_is_preponable 
FROM "metadata"."GroupedActivities"
;
```

## Initialization

```sql
ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN fag_is_auxiliary boolean DEFAULT FALSE; 
COMMENT ON COLUMN "metadata"."GroupedActivities".fag_is_auxiliary IS E'FAGs that are not linked one-to-one to the collection of data that apply to a specific point in time (sampling, measuring), but that potentially apply to a time series of data';

ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN fag_is_preponable boolean DEFAULT FALSE; 
COMMENT ON COLUMN "metadata"."GroupedActivities".fag_is_preponable IS E'subset of auxiliary FAGs which can be preponed or prepended';


SELECT activity_group, activity, is_loceval_activity, is_gw_activity, fag_is_auxiliary, fag_is_preponable FROM "metadata"."GroupedActivities";

```

```sql
UPDATE "metadata"."GroupedActivities"
SET fag_is_auxiliary = TRUE
WHERE FALSE
   OR activity_group LIKE '%LEVREADDIVER%'
;

UPDATE "metadata"."GroupedActivities"
SET fag_is_auxiliary = TRUE, fag_is_preponable = TRUE
WHERE FALSE
   OR activity_group LIKE '%LOCEVAL%'
   OR activity_group LIKE '%INST%'
   OR activity_group LIKE '%SPATPOSIT%'
;



SELECT DISTINCT activity_group, fag_is_auxiliary, fag_is_preponable
FROM "metadata"."GroupedActivities"
GROUP BY fag_is_preponable, fag_is_auxiliary, activity_group
ORDER BY fag_is_preponable, fag_is_auxiliary, activity_group
;

```

## extra

### add complementary flags
*... while we're at it.*

on #gwdb:
```sql

ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN is_loceval_activity boolean DEFAULT FALSE; 
COMMENT ON COLUMN "metadata"."GroupedActivities".is_loceval_activity IS E'convenience flag for loceval activities';


UPDATE "metadata"."GroupedActivities" 
SET is_loceval_activity = TRUE
WHERE activity_group LIKE '%LOCEVAL%'
   OR activity_group LIKE '%LSVI%'
;
SELECT activity_group, activity 
FROM "metadata"."GroupedActivities"
WHERE is_loceval_activity
;

```

on #locevaldb :
```sql

ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN is_gw_activity boolean DEFAULT FALSE; 
COMMENT ON COLUMN "metadata"."GroupedActivities".is_gw_activity IS E'convenience flag for groundwater-scheme activities';


UPDATE "metadata"."GroupedActivities"
SET is_gw_activity = TRUE
WHERE activity_group IN (
 'ADHOCDIVERREPLACE', 'ADHOCPIPEREPLACE', 'GWINSTPIEZNODIVER', 'GWINSTPIEZWELL', 'GWINSTWELLDIVER', 'GWINSTWELLDIVERDEEP', 'GWLEVREADDIVER', 'GWLEVREADDIVERDEEP', 'GWLEVREADDIVERMAN', 'GWSHALLCLEAN', 'GWSHALLSAMP', 'GWSHALLSAMPREADMAN', 'GWSURFLEVREADDIVERMAN', 'GWSURFSHALLSAMPREADMAN', 'SPATPOSITGAUGE', 'SPATPOSITPIPE'
);
SELECT DISTINCT activity_group, is_gw_activity
FROM "metadata"."GroupedActivities"
-- ORDER BY activity_group
ORDER BY is_gw_activity
;
```
