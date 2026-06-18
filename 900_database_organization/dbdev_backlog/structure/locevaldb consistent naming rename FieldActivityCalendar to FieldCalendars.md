---
aliases:
  - loceval rename FieldActivityCalendar to FieldCalendars
tags:
  - Visits
  - FieldCalendars
  - locevaldb
  - renaming
started: 2026-06-18
finished:
execution:
status: false
---


[[consistent table and field names across databases]]
Rename `FieldActivityCalendar` to `FieldCalendars`

[[procedures/steps to rename a table and columns|steps to rename a table and columns]] followed

```sql
-- rename table
ALTER TABLE "outbound"."FieldActivityCalendar" RENAME TO "FieldCalendars";

-- rename primary key
ALTER TABLE "outbound"."FieldCalendars" RENAME COLUMN fieldactivitycalendar_id TO fieldcalendar_id;
ALTER SEQUENCE "outbound".seq_fieldactivitycalendar_id RENAME TO seq_fieldcalendar_id;


-- create redirecting view
DROP VIEW IF EXISTS  "outbound"."FieldActivityCalendar" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldActivityCalendar" AS
SELECT fieldcalendar_id AS fieldactivitycalendar_id, *
FROM "outbound"."FieldCalendars"
;

-- create sync_mod trigger
DROP TRIGGER log_fieldactivitycalendar ON "outbound"."FieldCalendars";
CREATE TRIGGER log_fieldcalendars
BEFORE UPDATE ON "outbound"."FieldCalendars"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

-- foreign key in Visits
ALTER TABLE "inbound"."Visits" RENAME COLUMN fieldactivitycalendar_id TO fieldcalendar_id;
ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_FieldActivityCalendar_Visits CASCADE;

ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_FieldCalendars_Visits FOREIGN KEY (fieldcalendar_id)
REFERENCES "outbound"."FieldCalendars" (fieldcalendar_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

-- other views:
--   LocationEvaluation
--   FieldworkPlanning
--   LocevalFieldwork

-- qgis project
```