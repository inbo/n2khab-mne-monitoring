---
aliases:
  - the big renaming todo list
tags:
  - rename
  - alldatabases
  - improvement
started:
finished:
execution:
status: false
---

Historically, databases use different names for the same tables.
These should be corrected.

+ [ ] #loceval: `FieldActivityCalendar` -> #FieldCalendar 
+ [ ] #mnmgwdb: `RandomPoints` -> #RandomPlacementPoints
+ [ ] #mnmgwdb:  use redirection views!
	+ [ ] `SampleLocations` -> #SampleUnits 
	+ [ ] `"outbound"."SampleLocations".strata` -> #stratum
+ [ ] #mnmgwdb: `FieldworkCalendar` -> #FieldCalendar
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