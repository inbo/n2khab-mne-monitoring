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
status: false
---

Historically, databases use different names for the same tables.
These should be corrected.
[[procedures/steps to rename a table and columns|steps to rename a table and columns]]
docs: https://www.postgresql.org/docs/current/ddl-alter.html

+ [x] #loceval: `FieldActivityCalendar` -> #FieldCalendars 
+ [ ] #mnmgwdb:  rename #SampleLocations to #SampleUnits
	+ [[structure/rename SampleLocations to SampleUnits in mnmgwdb]]
	+ [ ] `SampleLocations` -> #SampleUnits 
	+ [ ] `"outbound"."SampleLocations".strata` -> #stratum
+ [ ] #mnmgwdb: `FieldworkCalendar` -> #FieldCalendars
	+ [[rename FieldworkCalendar to FieldCalendars in mnmgwdb]]
+ [ ] #mnmgwdb: `RandomPoints` -> #InstallationPoints
	+ [[rename RandomPoints to InstallationPoints in mnmgwdb]]
+ [ ] #mnmgwdb: move `CellMaps` and `LocationEvaluations` to schema `transfer`
	+ [[redirecting views for tables which moved to schema transfer - LocationEvaluations, CellMaps]]
+ [ ] #mnmgwdb: `Visits` -> #OtherVisits and use #Visits as an interface
	+ [[redirecting views for tables which moved to schema transfer - LocationEvaluations, CellMaps]]
	+ side task: primary key constraints for all Visits derivative tables
+ [x] #mnmgwdb #ReplacementData:
	+ [x] `grts_address` -> `grts_address_original`
	+ [x] `is_replaced` -> `is_chosen_replacement` (mind the #views)

To create a temporary alias, use #views.

*post hoc:* [[timeline/2026-10-09|2026-10-09]] cleanup
