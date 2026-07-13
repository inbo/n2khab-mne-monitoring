---
aliases:
tags:
started:
finished:
execution:
status: false
---

currently, #mnmsurfdb does not receive #LocationInfos from other databases.
only #locevaldb and #mnmgwdb are synced; the script has not been touched in a while
-> fix `115_sync_LocationInfos.R`

## process

Brought together a sync script, just like in `FreeFieldNotes` and `Trails`, but simpler
+ "first sync sync then distribute sync" strategy
+ no deletion and creation of entries necessary (fixed GRTS)
+ sync just carries all the columns
+ any change in `log_update` will trigger an update

testing:
```sql
SELECT * FROM "outbound"."LocationInfos" WHERE grts_address = 23238;
UPDATE "outbound"."LocationInfos" SET recovery_hints = 'zie RTK', equipment_recommendations = 'pogo-stick' WHERE grts_address = 23238;
UPDATE "outbound"."LocationInfos" SET recovery_hints = NULL WHERE grts_address = 23238;
```

-> backup and applied to production database

distinct hints seem good on all databases:
```sql
SELECT DISTINCT recovery_hints FROM "outbound"."LocationInfos";
```