---
aliases:
  - the big renaming todo list
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

+ [x] #loceval: `FieldActivityCalendar` -> #FieldCalendars 
+ [ ] #mnmgwdb: `RandomPoints` -> #RandomPlacementPoints
+ [ ] #mnmgwdb:  use redirection views!
	+ [ ] `SampleLocations` -> #SampleUnits 
	+ [ ] `"outbound"."SampleLocations".strata` -> #stratum
+ [ ] #mnmgwdb: `FieldworkCalendar` -> #FieldCalendars
+ [ ] #mnmgwdb: `Visits` -> #OtherVisits and use #Visits as an interface
+ [ ] #mnmgwdb: move `CellMaps` and `LocationEvaluations` to schema `transfer`
	+ ```sql
     ALTER TABLE "outbound"."LocationEvaluations" SET SCHEMA "transfer";
     ALTER TABLE "outbound"."CellMaps" SET SCHEMA "transfer";
     -- adjust views! (Fw, FwP, LocevalInfo)
     ```

+ [x] #mnmgwdb #ReplacementData:
	+ [x] `grts_address` -> `grts_address_original`
	+ [x] `is_replaced` -> `is_chosen_replacement` (mind the #views)

docs: https://www.postgresql.org/docs/current/ddl-alter.html

There seems to be no simple way to create a permanent alias, except with #views.