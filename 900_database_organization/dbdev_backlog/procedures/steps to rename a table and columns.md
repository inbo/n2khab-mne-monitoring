---
aliases:
tags:
  - renaming
---

all to be tested on staging first
to reduce downtime, assemble code to deploy changes in one go

+ adjust table name; be mindful of hierarchical tables / inheritance (e.g. `*Visits`)
+ table #primarykey: used in table itself and as foreign key in other tables
+ create a view to redirect changes; if necessary define update rules for redirection
+ #expostcode (e.g. `sync_mod`) adjust/apply for new table name
+ adjust other views which refer to the renamed table (or renamed columns)
+ check more constraint and dependency names with `\d+ <table>`
+ adjust #qgis projects
	+ connection info (key: e.g. replace `key=fieldactivitycalendar_id` by `key='fieldcalendar_id'` in `"outbound"."FieldworkPlanning"`)
	+ overhaul attribute forms
	+ if unavoidable: re-distribute the project files (was better announced beforehand)
+ download and re-extract the [[locations/structure sheets|structure sheets]]
+ adjust all scripts! (init; dailies; inspection; ...)

## Examples
+ [[structure/locevaldb consistent naming rename FieldActivityCalendar to FieldCalendars|locevaldb rename FieldActivityCalendar to FieldCalendars]]