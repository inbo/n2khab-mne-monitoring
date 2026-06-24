---
aliases:
  - manually one-time link prior freeze Visits to due FieldCalendars flag them as no_visit_planned
tags:
started: 2026-06-24
finished: 2026-06-24
execution:
  - FM
status: true
---

The #loceval #QGIS project helps to keep overview of locations which are due for loceval.
However, since previously visited #SampleUnits appear again after [[data update/20260313 REP update 0.15.0|GRTS reset]], but no durability period of locevals are implemented, those false-due activities pop up all over the map.

Discussed steps:
- remove priority of freeze (because prio's are dynamic and the frozen ones are outdated)
- manually one-time link prior freeze #Visits to due #FieldCalendars and flag them as `no_visit_planned` + `planning_done`
- (adjust data filter in #View and replace it by QGIS filter or symbology)


## Linking prior Visits to open FieldCalendar

### inspection and backup
backup existing Calendar entries

```sql
-- SELECT DISTINCT NEWCAL.date_start, NEWCAL.date_start, NEWCAL.done_planning

\COPY (
SELECT *
  FROM "outbound"."FieldCalendars" AS NEWCAL
LEFT JOIN (
  SELECT
    VISIT.sampleunit_id,
    VISIT.grts_address,
    VISIT.type,
    VISIT.date_start,
    VISIT.activity_group_id,
    VISIT.date_visit,
    VISIT.visit_done
  FROM "inbound"."Visits" AS VISIT
  LEFT JOIN "outbound"."FieldCalendars" AS FAC
    ON FAC.fieldcalendar_id = VISIT.fieldcalendar_id
  WHERE TRUE
    AND FAC.is_frozen
    AND visit_done
) AS PRECAL
ON (
    (PRECAL.sampleunit_id = NEWCAL.sampleunit_id)
AND (PRECAL.activity_group_id = NEWCAL.activity_group_id)
)
WHERE TRUE
AND NEWCAL.fieldcalendar_id NOT IN (
  SELECT DISTINCT fieldcalendar_id FROM "inbound"."Visits"
  WHERE visit_done
     OR date_visit IS NOT NULL
)
AND NOT NEWCAL.done_planning
AND NOT NEWCAL.is_frozen
AND NEWCAL.date_start < '2027-01-01'
AND PRECAL.visit_done IS NOT NULL
) TO '20260624_backup_fieldcalendars.csv' DELIMITER ',' CSV HEADER;

```
(132 rows)

### Execution

```sql
UPDATE "outbound"."FieldCalendars" 
SET 
  no_visit_planned = TRUE,
  notes = '[FM] batch update 20260624 freeze duplicates ' || notes,
  done_planning = TRUE
WHERE fieldcalendar_id IN (
SELECT DISTINCT NEWCAL.fieldcalendar_id
  FROM "outbound"."FieldCalendars" AS NEWCAL
LEFT JOIN (
  SELECT
    VISIT.sampleunit_id,
    VISIT.grts_address,
    VISIT.type,
    VISIT.date_start,
    VISIT.activity_group_id,
    VISIT.date_visit,
    VISIT.visit_done
  FROM "inbound"."Visits" AS VISIT
  LEFT JOIN "outbound"."FieldCalendars" AS FAC
    ON FAC.fieldcalendar_id = VISIT.fieldcalendar_id
  WHERE TRUE
    AND FAC.is_frozen
    AND visit_done
) AS PRECAL
ON (
    (PRECAL.sampleunit_id = NEWCAL.sampleunit_id)
AND (PRECAL.activity_group_id = NEWCAL.activity_group_id)
)
WHERE TRUE
AND NEWCAL.fieldcalendar_id NOT IN (
  SELECT DISTINCT fieldcalendar_id FROM "inbound"."Visits"
  WHERE visit_done
     OR date_visit IS NOT NULL
)
AND NOT NEWCAL.done_planning
AND NOT NEWCAL.is_frozen
AND NEWCAL.date_start < '2027-01-01'
AND PRECAL.visit_done IS NOT NULL
)
;
```

## Remove Freeze Priority

```sql
UPDATE "outbound"."FieldCalendars"
SET priority = NULL
WHERE is_frozen
;
```

(1459 affected)

## adjust FieldWork view
(done)