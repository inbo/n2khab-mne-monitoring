---
aliases:
tags:
  - mnmsyncdb
  - ReplacementData
  - LocationEvaluations
  - loceval
started:
finished:
execution:
status: false
---

- loceval info should be centrally pushed to #mnmsyncdb and then distributed to copies on user databases.via `111_push_loceval_to_***.R`
- [[consistent table and field names across databases]]
- part I: #ReplacementData 
- part II: #LocationEvaluations 

## Notes
- new schema `transfer` in mnmsyncdb
- removed `is_replaced` (*triv.*)
- add control columns:
	- `loceval_date` for uniqueness in case of repeated visits
	- `is_latest_replacement` as indication of the most relevant replacement

## TODO
- prepare syncdb
	- new schema: transfer
	- new table with permissions
- surgically adjust target db structure
	- rename `{new_}[sample]location_id` in both target databases
	- rename `is_replaced` to `is_latest_replacement` in both target databases
- adjust script `111`
	- columns to add upon distribution: (new_)location_id, (new_)samplelocation_id