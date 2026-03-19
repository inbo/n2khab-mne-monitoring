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

## column to flag calendar
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

### (1) REP update
510_loceval_update_REP.qmd
610_mnmgwdb_update_REP.qmd

### (2) calendar update
112_update_facalendar.R

## alternative backup procedure
besides the characols, ALL input data of the frozen calendar entries should be dumped somewhere in case the db has to be re-installed