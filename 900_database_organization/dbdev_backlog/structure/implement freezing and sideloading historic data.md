---
aliases:
tags:
  - REP
  - calendar
started: 2026-03-19
finished: 
execution:
  - "#FM"
status: false
---
*Preparations to allow retention of data which is not in temporal scope of the REP any more.*

## export and store
create a script to export data
   -> 405_freeze_calendar.R

plan: store characteristic columns in a csv
execution: generously dumped everything on the SampleUnits - Calendar - Visits axis.

## add column to flag frozen entries, in calendar
-> should be updated by the calendar update script (part of the user entry column? part of the [[dynamic implementation of precedence columns|precedence columns]] ?)

```sql

-- loceval:
ALTER TABLE "outbound"."FieldActivityCalendar" ADD COLUMN is_frozen boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."FieldActivityCalendar".is_frozen IS E'tag calendar entries which are retained from before the current REP temporal scope';

-- mnmgwdb:
ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN is_frozen boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".is_frozen IS E'tag calendar entries which are retained from before the current REP temporal scope';

```

## adjust update scripts
... to get the csv and retain existing data
finished during [[data update/20260313 REP update 0.15.0|REP 0.15.0]] on [[timeline/2026-03-24|2026-03-24]]

### (1) REP update
- [x] `510_loceval_update_REP.qmd`
- [x] `610_mnmgwdb_update_REP.qmd`

### (2) calendar update
- [ ] `112_update_facalendar.R`

## alternative backup procedure
besides the characols, ALL input data of the frozen calendar entries should be dumped somewhere in case the db has to be re-installed

## Practical implications #QGIS 
Generally, `is_frozen` is an attribute of the calendar.
It can be reproduced at any time by a date filter on `date_start`, e.g. `WHERE date_start <= '2025-12-31'`.

For QGIS visibility, I imagine the following convention:
- Frozen activities are NOT visible for #calendar planning
- however, on the #Visits side (e.g. actual installations), they may stay visible.