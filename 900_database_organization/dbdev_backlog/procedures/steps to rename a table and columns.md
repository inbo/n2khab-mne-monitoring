---
aliases:
tags:
  - renaming
  - rename
---

all to be tested on staging first
to reduce downtime, assemble code to deploy changes in one go: 
+ use `BEGIN; <...> COMMIT;`
+ consider to `REVOKE` user access during maintenance, `GRANT` it again afterwards


Phased rollout!
+ preparation (in secret)
+ polymorphism (old and new names active)
+ production (old objects and aliases removed)

> [!note] Customer Relations
> Consider timely announcement and communication with fieldwork
> (QField project release management).

Staging:
+ [[locations/structure sheets|structure sheet]] situation: `_dev_` sheets contain updates; `_db_` production sheets are still on *status quo*
+ use Python re-creation script to re-initialize #staging server(s): they refer to the production structure and will be reset (empty) to *status quo*
+ then, clone data from production server with "dump-restore" (`pg_dump ... psql`; see documentation)
+ sequentially apply changes to `-staging` and test extensively
+ if all lights are green, roll out to production


**Things to consider:**
+ go through the [[locations/structure sheets|structure sheets]]
+ download and re-extract the [[locations/structure sheets|structure sheets]]; apply to #dev mirror for testing
+ adjust table name; be mindful of hierarchical tables / inheritance (e.g. `*Visits`)
+ rename the table, of course
	+ e.g. `ALTER TABLE "outbound"."SampleLocations" RENAME TO "SampleUnits";`
+ table #primarykey: used in table itself and as foreign key in other tables
	+ e.g. `ALTER TABLE "outbound"."SampleUnits" RENAME COLUMN samplelocation_id TO sampleunit_id;`
	+ rename the pk
	+ rename fk's in other tables
	+ rename constraints, e.g. `ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT fk_fieldworkcalendar_visits TO fk_fieldcalendars_visits;`
	+ reset sequence, e.g. `SELECT setval(pg_get_serial_sequence('"outbound"."FieldCalendars"', 'fieldcalendar_id'), COALESCE(MAX(fieldcalendar_id), 1)) FROM "outbound"."FieldCalendars";`
+ create a view to redirect changes; if necessary define update rules for redirection
	+ e.g. 
	+ ```sql
        DROP VIEW IF EXISTS  "outbound"."SampleLocations" ;
        CREATE VIEW "outbound"."SampleLocations" AS
        SELECT
          sampleunit_id AS samplelocation_id,
          location_id,
          -- <list all columns here; with optional aliasing>
        FROM "outbound"."SampleUnits";
	  ```
+ #expostcode (e.g. `sync_mod`) adjust/apply for new table name
	+ ```sql
        DROP TRIGGER IF EXISTS log_fieldworkcalendar ON "outbound"."FieldCalendars";
        DROP TRIGGER IF EXISTS log_fieldcalendars ON "outbound"."FieldCalendars";
        CREATE TRIGGER log_fieldcalendars
        BEFORE UPDATE ON "outbound"."FieldCalendars"
        FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();
	  ```
+ adjust other views which refer to the renamed table (or renamed columns)
	+ go through views manually; may be via "find" in structure sheets
	+ keep [[locations/views|Views folder]] and structure sheets in sync, as always 
	+ consider keeping an alias column for renamed columns, e.g.
	+ ```sql
	-- SELECT [...],
	   UNIT.stratum, -- new name
       UNIT.stratum AS strata, -- old name stays available (e.g. for QGIS) 
	  ```
+ check more constraint and dependency names with `\d+ <table>`
+ adjust all scripts! (init; dailies; inspection; ...)
+ update all `COMMENT`s on tables and columns (via find-replace in structure sheet; then manual intervention)
	+ e.g. `COMMENT ON TABLE "inbound"."Visits" IS E'inbound information about location visits, planned in FieldCalendars, linked to SampleUnits and field activity GROUP';`
+ on table renames, make sure to remove the table structure `.csv` files in structure folders; they do not get removed automatically
	+ this is a bonus to expose dead links to old tables in the maintenance scripts
+ restore #staging from structure sheets and test dump-restore
	+ this will expose obsolete keys on production, which must be manually corrected
	+ e.g. [[constraint renames caused staging-production inconsistencies after The Great Rename summer 2026]]
+ adjust #qgis projects
	+ connection info (key: e.g. replace `key=fieldactivitycalendar_id` by `key='fieldcalendar_id'` in `"outbound"."FieldworkPlanning"`)
	+ overhaul attribute forms
	+ if unavoidable: re-distribute the project files (was better announced beforehand)
+ carefully execute maintenance scripts (on `-staging` first) to confirm successful migration
+ check documentation and backlog for mentions of the old table names


## Examples
+ [[structure/locevaldb consistent naming rename FieldActivityCalendar to FieldCalendars|locevaldb rename FieldActivityCalendar to FieldCalendars]]

```query
tag: #rename
path: structure/
["status":true]
```


*advanced:*
+ [[structure/introduce table inheritance to locevaldb Visits for LOCEVALAQ|introduce table inheritance to locevaldb Visits for LOCEVALAQ]]