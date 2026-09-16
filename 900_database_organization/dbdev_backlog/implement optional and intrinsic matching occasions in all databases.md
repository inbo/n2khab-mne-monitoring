---
aliases:
tags:
  - matching_occasions
  - FieldCalendars
started:
finished:
execution:
status: false
priority:
---

*supersedes [[implement matching occasions for locevals]]*

> [!warning] Concept and Design
> The concept of matching on the levels of #FieldCalendars and/or #Visits required some thorough considerations.
> The main issues are:
> 1. There must be a distinction between "**optional matches**" (to prepone future auxiliary FAGs for efficiency) and "**intrinsic matches**" (same FAG on same date for different Sample Units).
>  2. For intrinsic matches, we will switch to an `n : 1` linkage between FieldCalendars and Visits, thereby deviating from the historic, robust `1:1` linkage they were initiated with (which requires the use of array columns, and careful handling of existing data).
>  3. Views and QGIS field forms on these tables are complex. Although a view-side grouping of e.g. intrinsic matches might be feasible, this would further complicate things and hinder maintenance while at the same time producing data redundancy.
>  4. The distinction of whether an activity group is optionally or intrinsically linkable depends on whether it is an auxiliary FAG. However, mnmgwdb's InstallationVisits would justify *intrinsic* grouping across time, but it will be represented as *optional* for now (reason: we might decide to pass by for an "installation refreshment".
>  5. Speaking of... there are different `*Visits` and thereby many tables | views | map layers which can be affected.

## Optional Matches for #locevaldb 

Prepare the minimum required columns:

```sql
ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN matching_occasion varchar; 
COMMENT ON COLUMN "outbound"."FieldCalendars".matching_occasion IS E'group label of actifity groups which may be combined (optional match)';

ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN date_suggested date; 
COMMENT ON COLUMN "outbound"."FieldCalendars".date_suggested IS E'earliest date of activities in an optional matching group';

UPDATE "outbound"."FieldCalendars"
SET date_suggested = date_start;

```

+ added field upload to `510_loceval_update_REP.qmd`
	+ `matching_occasions` are taken as in the REP
	+ date_suggested is the earlier date of all matching occasions
	+ QGIS simply displays this information

However, there is little to be won here:
```
loceval=> SELECT DISTINCT grts_address, type FROM "outbound"."FieldCalendars" WHERE date_start != date_suggested;
 grts_address | type 
--------------+------
(0 rows)
```

## Intrinsic Matches for #mnmsurfdb

The `SURFLENTDATACOLL` of #mnmsurfdb can co-occur for multiple types on the same location.
However, because we work on one and the same sample, only one row is needed to fill the data.

[[sql_tricks/array data types|array data types]] for `"inbound"."Visits".stratum`:
```sql

BEGIN;

DROP VIEW "inbound"."AllVisits" CASCADE;
DROP VIEW "inbound"."FieldWork" CASCADE;
DROP VIEW "outbound"."FieldworkPlanning" CASCADE;

ALTER TABLE "inbound"."Visits" DROP CONSTRAINT fk_fieldcalendar_visits;

ALTER TABLE "inbound"."Visits"
ALTER COLUMN stratum TYPE varchar ARRAY
USING ARRAY[stratum];

ALTER TABLE "inbound"."Visits"
ALTER COLUMN fieldcalendar_id TYPE int ARRAY
USING ARRAY[fieldcalendar_id];

ALTER TABLE "inbound"."Visits"
ALTER COLUMN sampleunit_id TYPE int ARRAY
USING ARRAY[sampleunit_id];

ALTER TABLE "inbound"."Visits"
ADD COLUMN is_aggregated BOOLEAN NOT NULL DEFAULT FALSE;

```

ISSUE: the foreign key would have to be given up. <https://stackoverflow.com/a/50441059>

Aggregate the data (<https://vrcacademy.com/tutorials/postgresql-distinct-array-elements/>)
```sql

SELECT DISTINCT ON (location_id) 
  (ARRAY_AGG(log_user))[1] AS log_user,
  location_id,
  -- ARRAY_agg(DISTINCT UNNEST(sampleunit_id)) AS sampleunit_id,
  ARRAY_AGG(DISTINCT fc_id ORDER BY fc_id) AS fieldcalendar_id,
  ARRAY_AGG(DISTINCT su_id ORDER BY su_id) AS sampleunit_id,
  ARRAY_AGG(DISTINCT strats ORDER BY strats) AS stratum,
  MAX(log_update) AS log_update,
  STRING_AGG(notes, ', ') AS notes,
  TRUE AS is_aggregated
FROM "inbound"."Visits",
LATERAL 
  UNNEST(fieldcalendar_id) AS fc_id,
  UNNEST(sampleunit_id) AS su_id,
  UNNEST(stratum) AS strats
GROUP BY location_id
;

log_update,
fieldcalendar_id,
sampleunit_id,
location_id,
grts_address,
stratum,
activity_group_id,
date_start,
teammember_id,
date_visit,
datetime_visit,
sampling_done,
notes,
issues,
photo,
visit_done,
link_observation_samplecontext,
link_observation_meteorology,
link_observation_perturbation,
archive_version_id,
```
