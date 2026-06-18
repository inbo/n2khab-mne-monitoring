---
aliases:
  - loceval rename FieldActivityCalendar to FieldCalendars
tags:
  - Visits
  - FieldCalendars
  - locevaldb
  - renaming
started: 2026-06-18
finished: 2026-06-18
execution:
  - FM
status: true
---


[[consistent table and field names across databases]]
Rename `FieldActivityCalendar` to `FieldCalendars`

[[procedures/steps to rename a table and columns|steps to rename a table and columns]] 

## deployment script

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

## ex post errors
When restoring #staging afterwards, some errors appeared.

```sql
-- type 1 / potential cause: fk constaint names
ERROR:  constraint "fk_versions_fieldactivitycalendar" of relation "FieldCalendars" does not exist
ERROR:  constraint "fk_teammembers_fieldactivitycalendar" of relation "FieldCalendars" does not exist
ERROR:  constraint "fk_sampleunits_fieldactivitycalendar" of relation "FieldCalendars" does not exist

-- type 2 / potential cause: missing pk
ERROR:  constraint "FieldActivityCalendar_pkey" of relation "FieldCalendars" does not exist

-- type 3: cascading dependencies
ERROR:  cannot drop constraint SampleUnits_pkey on table outbound."SampleUnits" because other objects depend on it
DETAIL:  constraint fk_sampleunits_fieldcalendars on table outbound."FieldCalendars" depends on index outbound."SampleUnits_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop constraint Versions_pkey on table metadata."Versions" because other objects depend on it
DETAIL:  constraint fk_versions_fieldcalendars on table outbound."FieldCalendars" depends on index metadata."Versions_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop constraint TeamMembers_pkey on table metadata."TeamMembers" because other objects depend on it
DETAIL:  constraint fk_teammembers_fieldcalendars on table outbound."FieldCalendars" depends on index metadata."TeamMembers_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop table metadata."Versions" because other objects depend on it
DETAIL:  constraint fk_versions_fieldcalendars on table outbound."FieldCalendars" depends on table metadata."Versions"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop table metadata."TeamMembers" because other objects depend on it
DETAIL:  constraint fk_teammembers_fieldcalendars on table outbound."FieldCalendars" depends on table metadata."TeamMembers"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop table outbound."SampleUnits" because other objects depend on it
DETAIL:  constraint fk_sampleunits_fieldcalendars on table outbound."FieldCalendars" depends on table outbound."SampleUnits"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

-- type 4: non-empty schema's
ERROR:  cannot drop schema outbound because other objects depend on it
DETAIL:  table outbound."SampleUnits" depends on schema outbound
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
ERROR:  cannot drop schema metadata because other objects depend on it
DETAIL:  table metadata."Versions" depends on schema metadata
table metadata."TeamMembers" depends on schema metadata
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

Output of `\d+ "outbound"."FieldCalendars";`
```sql
[...]
Indexes:
    "FieldActivityCalendar_pkey" PRIMARY KEY, btree (fieldcalendar_id)
Check constraints:
    "FieldActivityCalendar_activity_rank_check" CHECK (activity_rank > 0)
    "FieldActivityCalendar_grts_address_check" CHECK (grts_address > 0)
Foreign-key constraints:
    "fk_sampleunits_fieldactivitycalendar" FOREIGN KEY (sampleunit_id) REFERENCES outbound."SampleUnits"(sampleunit_id) ON UPDATE CASCADE ON DELET
E SET NULL
    "fk_teammembers_fieldactivitycalendar" FOREIGN KEY (teammember_assigned) REFERENCES metadata."TeamMembers"(teammember_id) ON UPDATE CASCADE ON
 DELETE SET NULL
    "fk_versions_fieldactivitycalendar" FOREIGN KEY (archive_version_id) REFERENCES metadata."Versions"(version_id) ON UPDATE CASCADE ON DELETE SE
T NULL
Referenced by:
    TABLE "inbound."Visits"" CONSTRAINT "fk_fieldcalendars_visits" FOREIGN KEY (fieldcalendar_id) REFERENCES outbound."FieldCalendars"(fieldcalend
ar_id) ON UPDATE CASCADE ON DELETE SET NULL
Not-null constraints:
    "FieldActivityCalendar_fieldactivitycalendar_id_not_null" NOT NULL "fieldcalendar_id"
    "FieldActivityCalendar_log_user_not_null" NOT NULL "log_user"
    "FieldActivityCalendar_log_update_not_null" NOT NULL "log_update"
    "FieldActivityCalendar_type_not_null" NOT NULL "type"
    "FieldActivityCalendar_grts_address_not_null" NOT NULL "grts_address"
    "FieldActivityCalendar_date_start_not_null" NOT NULL "date_start"
    "FieldActivityCalendar_date_end_not_null" NOT NULL "date_end"
    "FieldActivityCalendar_activity_group_id_not_null" NOT NULL "activity_group_id"
    "FieldActivityCalendar_excluded_not_null" NOT NULL "excluded"
    "FieldActivityCalendar_no_visit_planned_not_null" NOT NULL "no_visit_planned"
    "FieldActivityCalendar_done_planning_not_null" NOT NULL "done_planning"
    "FieldActivityCalendar_is_frozen_not_null" NOT NULL "is_frozen"
Triggers:
    log_fieldcalendars BEFORE UPDATE ON outbound."FieldCalendars" FOR EACH ROW EXECUTE FUNCTION metadata.sync_mod()
Access method: heap
```

Fix:

``` sql

ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_pkey" TO "FieldCalendar_pkey";

ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_activity_rank_check" TO "FieldCalendars_activity_rank_check";
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_grts_address_check" TO "FieldCalendar_grts_address_check";

ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT fk_sampleunits_fieldactivitycalendar TO "fk_sampleunits_fieldcalendars";
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT fk_teammembers_fieldactivitycalendar TO "fk_teammembers_fieldcalendars";
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT fk_versions_fieldactivitycalendar TO "fk_versions_fieldcalendars";

ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_fieldactivitycalendar_id_not_null" TO  "FieldCalendars_fieldactivitycalendar_id_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_log_user_not_null" TO  "FieldCalendars_log_user_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_log_update_not_null" TO  "FieldCalendars_log_update_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_type_not_null" TO  "FieldCalendars_type_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_grts_address_not_null" TO  "FieldCalendars_grts_address_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_date_start_not_null" TO  "FieldCalendars_date_start_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_date_end_not_null" TO  "FieldCalendars_date_end_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_activity_group_id_not_null" TO  "FieldCalendars_activity_group_id_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_excluded_not_null" TO  "FieldCalendars_excluded_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_no_visit_planned_not_null" TO  "FieldCalendars_no_visit_planned_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_done_planning_not_null" TO  "FieldCalendars_done_planning_not_null" ;
ALTER TABLE "outbound"."FieldCalendars" RENAME CONSTRAINT "FieldActivityCalendar_is_frozen_not_null" TO  "FieldCalendars_is_frozen_not_null" ;

-- ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT fk_fieldcalendars_visits TO fk_fieldcalendars_visits
```