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

> [!note] Decision Summary
> - #FieldCalendars and #Visits will remain the central tables of storage of #REP plans and #fieldwork results. However, the crucial news is that **Visits will be aggregated**, i.e. there can be a single visit to serve multiple (matching) REP FAG occasions = #matching_occasions.
> - I am reluctant to have a physical table for connection (e.g. `FieldCalendars n--n Occasions n--1 Visits` ) because this table does not quite match any fieldwork concept, it is purely technical; it would complicate all queries by one whole extra join.
> 	- Upon first inspection, [[sql_tricks/array data types|array data types]] seem to work fine and there is no reason to avoid that, except some [ancient dogma](https://en.wikipedia.org/wiki/First_normal_form).
> 	- Crucial trick to still follow that dogma is to switch hierarchy: instead of hanging #Visits onto #FieldCalendars, each entry in the calendars should have at most one `visit_id` (or none).
> 	- There will be a view #OccasionMatching which optionally provides a way to link, alike to "physical" tables.
> - #FieldCalendars should not be aggregated: all #SampleUnits come from the REP, and some might be disapproved by #loceval, thus #FieldworkPlanning must deselect the ones which are not eligible. As a consequence, **`exclude` becomes more important!** The new `visit_id` column in `FieldCalendars` should be nullable to allow disconnection of rejected units. Conversely, `fieldcalendar_ids` must be adjusted by removing excluded ones from the array.
> - #inheritance: the monarchy of #Visits should not be affected (all aggregated columns are in the parent table interface), just that there will be fewer rows.
> - Temporal continuity (unit rejection by loceval after the visit) is no issue, because the calendar is fixed on a time point.
> - Performance should not be an issue; however, I must ensure that the major #views ( #FieldworkPlanning, #FieldWork ) stay efficient and performant.
> - There must be complementary views: `FieldCalendarsNested` and `ViewsUnnested`, to facilitate queries of either logic.
> - Although this applies only to #mnmsurfdb, it will be implemented for **all databases alike** to retain consistency.


### Exploration 1: Actually Grouped Data / Array in Tables

#### Structure
The `SURFLENTDATACOLL` of #mnmsurfdb can co-occur for multiple types on the same location.
However, because we work on one and the same sample, only one row is needed to fill the data.

--> We require [[sql_tricks/array data types|array data types]] for `"inbound"."Visits".stratum` and others.


```sql

BEGIN;

-- views must temporarily be removed, they otherwise block the changes below
DROP VIEW "inbound"."AllVisits" CASCADE;
DROP VIEW "inbound"."FieldWork" CASCADE;
DROP VIEW "outbound"."FieldworkPlanning" CASCADE;

-- constraints will be reworked
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT fk_fieldcalendar_visits;
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT fk_FieldCalendars_Visits;
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT fk_SampleUnits_Visits


-- STRUCTURE PREPARATION
-- columns for matching occasions
ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN matching_occasion varchar;
COMMENT ON COLUMN "outbound"."FieldCalendars".matching_occasion IS E'group label of actifity groups which may be combined (optional match)';

ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN date_suggested date;
COMMENT ON COLUMN "outbound"."FieldCalendars".date_suggested IS E'earliest date of activities in an optional matching group';

UPDATE "outbound"."FieldCalendars"
SET date_suggested = date_start;


-- visit_id as fk to FieldCalendars
ALTER TABLE "inbound"."FieldCalendars" ADD COLUMN visit_id int DEFAULT NULL;
COMMENT ON COLUMN "inbound"."FieldCalendars".visit_id IS E'link to the visit which serves this calendar entry';

ALTER TABLE "outbound"."FieldCalendars" DROP CONSTRAINT IF EXISTS fk_Visits_FieldCalendars CASCADE;
ALTER TABLE "outbound"."FieldCalendars" ADD CONSTRAINT fk_Visits_FieldCalendars FOREIGN KEY (visit_id)
REFERENCES "inbound"."Visits" (visit_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;


-- Visits.stratums
ALTER TABLE "inbound"."Visits"
ALTER COLUMN stratum TYPE varchar ARRAY
USING ARRAY[stratum];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN stratum TO stratums;
COMMENT ON COLUMN "inbound"."Visits".stratums IS E'strata for which this visit can provide data';


-- Visits.fieldcalendar_ids
ALTER TABLE "inbound"."Visits"
ALTER COLUMN fieldcalendar_id TYPE int ARRAY
USING ARRAY[fieldcalendar_id];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN fieldcalendar_id TO fieldcalendar_ids;
COMMENT ON COLUMN "inbound"."Visits".fieldcalendar_ids IS E'optional shortcut: collection of all FieldCalendars entries which are served by this visit';

-- Visits.sampleunit_ids
ALTER TABLE "inbound"."Visits"
ALTER COLUMN sampleunit_id TYPE int ARRAY
USING ARRAY[sampleunit_id];

ALTER TABLE "inbound"."Visits"
RENAME COLUMN sampleunit_id TO sampleunit_ids;
COMMENT ON COLUMN "inbound"."Visits".sampleunit_ids IS E'array of sample unit indices (technical) or NULL for obsolete visits';

```


ISSUE: the foreign key would have to be given up. <https://stackoverflow.com/a/50441059>
SOLUTION: ... or not: just switching the dependency between #FieldCalendars and #Visits by giving the `visit_id` to FieldCalendars (fk) and keeping `fieldcalendar_ids` as array column

Structure is in place - data has to be aggregated.


#### Data Aggregation

First, a backup copy is stored to `"archive"."LenticVisits"` via [CREATE TABLE ... AS ...](https://www.tutorialkart.com/postgresql/postgresql-create-table-from-another-table/)

```sql
-- create a copy of the existing Visits
CREATE TABLE "archive"."UnaggregatedVisits" AS
SELECT *
FROM ONLY "inbound"."Visits"
NATURAL FULL JOIN "inbound"."LenticVisits"
NATURAL FULL JOIN "inbound"."LoticVisits"
NATURAL FULL JOIN "inbound"."OtherVisits"
ORDER BY visit_id ASC
;

```

While at it, drop some excess columns (which nevertheless have data; someone was working with an outdated project version).

```sql
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN latest_calibration;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN water_clarity;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN turbidity;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN open_water;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN waterdepth_samplingpoint_m;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN float_layer;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN phytoplankton;
ALTER TABLE "inbound"."LenticVisits" DROP COLUMN ice_layer_cm;

```


Aggregate the data (<https://vrcacademy.com/tutorials/postgresql-distinct-array-elements/>).
This only needs to apply for #LenticVisits, the others have none with `visit_done`.

```sql

-- DATA AGGREGATION
-- temporary helper column to identify the aggregated rows
ALTER TABLE "inbound"."Visits"
ADD COLUMN is_aggregated BOOLEAN NOT NULL DEFAULT FALSE;

-- has to happen separately per *Visit class; here, `LenticVisits` is the only one used so far

SELECT DISTINCT ON (location_id, grts_address, date_start, date_visit, activity_group_id)
  COALESCE(
    (STRING_AGG(DISTINCT log_user, ',' )
     FILTER (WHERE log_user NOT IN ('maintenance'))
    ),
    'maintenance'
    ) AS log_user,
  MAX(log_update) AS log_update,
  location_id,
  ARRAY_AGG(DISTINCT fc_id ORDER BY fc_id) AS fieldcalendar_ids,
  ARRAY_AGG(DISTINCT su_id ORDER BY su_id) AS sampleunit_ids,
  ARRAY_AGG(DISTINCT strats ORDER BY strats) AS stratums,
  location_id,
  grts_address,
  activity_group_id,
  date_start,
  MAX(teammember_id),
  date_visit,
  MAX(datetime_visit) AS datetime_visit,
  BOOL_OR(sampling_done) AS sampling_done,
  STRING_AGG(notes, ', ') AS notes,
  STRING_AGG(photo, ', ') AS photo,
  BOOL_OR(issues) AS issues,
  BOOL_OR(visit_done) AS visit_done,
  BOOL_OR(link_observation_samplecontext) AS link_observation_samplecontext,
  BOOL_OR(link_observation_meteorology) AS link_observation_meteorology,
  BOOL_OR(link_observation_perturbation) AS link_observation_perturbation,
  CASE WHEN BOOL_OR(archive_version_id IS NULL)
    THEN NULL
    ELSE (SELECT DISTINCT MAX(version_id) FROM "metadata"."Versions")
    END AS archive_version_id,
  TRUE AS is_aggregated,
  STRING_AGG(DISTINCT equipment, ', ') AS equipment,
  BOOL_OR(chlorophytae_presence) AS chlorophytae_presence,
  STRING_AGG(DISTINCT chlorophytae_specification, ', ') AS chlorophytae_specification,
  AVG(waterdepth_samplingpoint_cm) AS waterdepth_samplingpoint_cm,
  AVG(secchi_depth_cm) AS secchi_depth_cm,
  BOOL_OR(clear_to_bottom),
  AVG(sludge_thickness) AS sludge_thickness,
  AVG(waterlevel_elevation_mtaw) AS waterlevel_elevation_mtaw,
  STRING_AGG(DISTINCT project_code, ', ') AS project_code,
  STRING_AGG(DISTINCT recipient_code, ', ') AS recipient_code,
  AVG(watertemperature_celsius) AS watertemperature_celsius,
  AVG(sample_ph) AS sample_ph,
  AVG(electric_conductivity_mus_cm) AS electric_conductivity_mus_cm,
  AVG(dissolved_oxygen_mg_l) AS dissolved_oxygen_mg_l,
  AVG(dissolved_oxygen_percent) AS dissolved_oxygen_percent,
  STRING_AGG(DISTINCT sample_notes, ', ') AS sample_notes,
  BOOL_OR(sample_contamination) AS sample_contamination,
  STRING_AGG(DISTINCT sample_contamination_reason, ', ') AS sample_contamination_reason,
  AVG(sneller_cm) AS sneller_cm,
  STRING_AGG(DISTINCT color, ', ') AS color,
  STRING_AGG(DISTINCT smell, ', ') AS smell,
  STRING_AGG(DISTINCT zooplankton, ', ') AS zooplankton,
  STRING_AGG(DISTINCT macroinvertebrates, ', ') AS macroinvertebrates,
  STRING_AGG(DISTINCT xphoto_sample, ', ') AS xphoto_sample
FROM "inbound"."LenticVisits",
LATERAL
  UNNEST(fieldcalendar_ids) AS fc_id,
  UNNEST(sampleunit_ids) AS su_id,
  UNNEST(stratums) AS strats
GROUP BY location_id, grts_address, date_start, date_visit, activity_group_id
;

-- clean up
DELETE FROM "inbound"."LenticVisits" WHERE NOT is_aggregated;
ALTER TABLE "inbound"."Visits" DROP COLUMN is_aggregated;


COMMIT;

```

Compare pre/post to find issues
```sql
\COPY (SELECT * FROM "inbound"."LenticVisits" WHERE visit_done)  TO '~/20260917_lentic_visits_preaggregated.csv' With CSV DELIMITER ',' HEADER;
\COPY (SELECT * FROM "inbound"."LenticVisits" WHERE visit_done)  TO '~/20260917_lentic_visits_postaggregated.csv' With CSV DELIMITER ',' HEADER;

```

Then run the MODIFIED `102_re_link_foreign_keys.R` script to re-link tables.


#### Views for Convenience and Backwards Compatibility

```sql
```

### Exploration 2: Virtually Grouped Data / Array in Views (*idea discarded*)

- array data types are somewhat discouraged because they violate some obscure principle of "[first normal form](https://en.wikipedia.org/wiki/First_normal_form)" (Codd).
- However, in our case, arrays will only only be added for convenience; the central relation stays straight forward.
- concrete issues with the foreign key in `fieldwork_id`: fk's may not be defined "element-wise" on arrays
- some data ambiguity hard to solve systematically (`log_user` can have multiple valid values but I do not want to array it)
- leaving comfort zone with `LATERAL`, `_AGG`/`UNNEST`, etc. -> more complex queries await

BUT: array data types might be fine for Views!
- we have a view anyways
- inversion of aggregating is straight forward via #updaterules

HOWEVER,
- That query is already heavy.
	- integrating #FieldCalendars and #Visits might be good
	- #Observations are linked to Visits; a visit group might be better?

VARIANT
- have a `VisitGroups` table which links `visit_id` to `visitgroup`
- or another column in Visits
- or some way of defining "`Occasions`" (as in "`matching_occasions`") as a group of FieldCalendar entries?