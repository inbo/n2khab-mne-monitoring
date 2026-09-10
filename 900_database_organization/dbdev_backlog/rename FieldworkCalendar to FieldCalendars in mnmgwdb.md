---
aliases:
tags:
  - FieldCalendars
  - rename
started: 2026-09-08
finished: 2026-09-10
execution:
  - FM
status: true
priority:
---

Changing an #mnmgwdb table name ( #FieldCalendars ) for consistency across databases.
part 2 of [[consistent table and field names across databases summer 2026|the big renaming todo list summer 2026]]


```sql
BEGIN;

ALTER TABLE "outbound"."FieldworkCalendar" RENAME TO "FieldCalendars";
ALTER TABLE "outbound"."FieldCalendars" RENAME COLUMN fieldworkcalendar_id TO fieldcalendar_id;


ALTER TABLE "inbound"."Visits" RENAME COLUMN fieldworkcalendar_id TO fieldcalendar_id;



-- comment on Visits
COMMENT ON TABLE "inbound"."Visits" IS E'inbound information about location visits, planned in FieldCalendars, linked to SampleUnits and field activity GROUP';

-- comment on Visits.activity_group_id
COMMENT ON COLUMN "inbound"."Visits".activity_group_id IS E'a link to the activity metadata, and a component of unique identification of each row';


-- ensure trigger stays active
DROP TRIGGER IF EXISTS log_fieldworkcalendar ON "outbound"."FieldCalendars";
DROP TRIGGER IF EXISTS log_fieldcalendar ON "outbound"."FieldCalendars";
DROP TRIGGER IF EXISTS log_fieldcalendars ON "outbound"."FieldCalendars";
CREATE TRIGGER log_fieldcalendars
BEFORE UPDATE ON "outbound"."FieldCalendars"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();

-- reset serial
SELECT setval(pg_get_serial_sequence('"outbound"."FieldCalendars"', 'fieldcalendar_id'), COALESCE(MAX(fieldcalendar_id), 1)) FROM "outbound"."FieldCalendars";


-- create a redirecting view with the old name:
DROP VIEW IF EXISTS  "outbound"."FieldworkCalendar" ;
CREATE VIEW "outbound"."FieldworkCalendar" AS
SELECT
  fieldcalendar_id AS fieldworkcalendar_id,
  -- log_user, log_update
  sampleunit_id, 
  grts_address, 
  stratum, 
  activity_group_id, 
  date_start, 
  date_end, 
  date_interval, 
  sspstapa_id, 
  activity_rank, 
  priority, 
  wait_any, 
  wait_watersurface, 
  wait_3260, 
  wait_7220, 
  wait_floating, 
  wait_obsolete_types, 
  is_sideloaded, 
  is_frozen, 
  excluded, 
  excluded_reason, 
  teammember_assigned, 
  date_visit_planned, 
  no_visit_planned, 
  notes, 
  done_planning, 
  archive_version_id 
FROM "outbound"."FieldCalendars"
;

ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT fk_fieldworkcalendar_visits TO fk_fieldcalendars_visits;

COMMIT;
```

- [x] check explicit foreign key on `Visits.fieldcalendar_id` with `\d+ "inbound"."Visits"`


Views: 
FieldWork
FieldworkPlanning
SampleCells
MissingTeammember