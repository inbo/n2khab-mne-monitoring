---
aliases:
  - the big renaming todo list summer 2026
tags:
  - rename
  - alldatabases
  - improvement
started: 2026-06-11
finished: 
execution:
  - FM
status: true
---

Historically, databases use different names for the same tables.
These should be corrected.
[[procedures/steps to rename a table and columns|steps to rename a table and columns]]
docs: https://www.postgresql.org/docs/current/ddl-alter.html

+ [x] #loceval: `FieldActivityCalendar` -> #FieldCalendars 
+ [x] #mnmgwdb:  rename #SampleLocations to #SampleUnits
	+ [[structure/rename SampleLocations to SampleUnits in mnmgwdb]]
	+ [x] `SampleLocations` -> #SampleUnits 
	+ [x] `"outbound"."SampleLocations".strata` -> #stratum
+ [x] #mnmgwdb: `FieldworkCalendar` -> #FieldCalendars
	+ [[rename FieldworkCalendar to FieldCalendars in mnmgwdb]]
+ [x] #mnmgwdb: `RandomPoints` -> #InstallationPoints
	+ [[rename RandomPoints to InstallationPoints in mnmgwdb]]
+ [x] #mnmgwdb: move `CellMaps` and `LocationEvaluations` to schema `transfer`
	+ [[redirecting views for tables which moved to schema transfer - LocationEvaluations, CellMaps]]
+ [x] #mnmgwdb: `Visits` -> #OtherVisits and use #Visits as an interface
	+ [[redirecting views for tables which moved to schema transfer - LocationEvaluations, CellMaps]]
	+ side task: primary key constraints for all Visits derivative tables
+ [x] #mnmgwdb #ReplacementData:
	+ [x] `grts_address` -> `grts_address_original`
	+ [x] `is_replaced` -> `is_chosen_replacement` (mind the #views)

To create a temporary alias, use #views.

**Showtime!**
- [x] [[timeline/2026-09-09|2026-09-09]] 10:15 applied to production (after final test and backups)
- [x] re-applied all views
- [x] restore #staging and test dump-restore
	- [[constraint renames caused staging-production inconsistencies after The Great Rename summer 2026]]
- [x] QGIS projects
	- some layers were not working: mostly due to obsolete primary keys / missing aliases and table names / view permissions in the layer definitions
- [x] test old QField projects
	- [x] issue with permissions for redirecting views -> solved
- [x] adjusted version number for QField projects (new)
- [x] finish distribution and announcement

- [ ] test all maintenance and data update scripts
- [ ] *post hoc:* [[timeline/2026-10-09|2026-10-09]] cleanup
