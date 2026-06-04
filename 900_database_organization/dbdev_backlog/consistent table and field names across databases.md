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
+ [ ] #mnmgwdb: 
	+ [ ] `SampleLocations` -> #SampleUnits 
	+ [ ] `"outbound"."SampleLocations".strata` -> #stratum
+ [ ] #mnmgwdb: `FieldworkCalendar` -> #FieldCalendar
+ [ ] #mnmgwdb: `Visits` -> #OtherVisits and use #Visits as an interface
+ [ ] #mnmgwdb #ReplacementData:
	+ [ ] `grts_address` -> `grts_address_original`
	+ [ ] `is_replaced` -> `is_chosen_replacement` (mind the #views)
