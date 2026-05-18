---
aliases:
  - nolog columns
tags:
  - LocationJournals
  - LoJos
  - logging
  - nolog
started: 2026-05-18
finished: 2026-05-18
execution:
  - FM
status: true
---

The following columns were added to #LocationJournals across databases:
```
nolog_user
nolog_update
```

These will contain the latest available #logging information from the source database for change tracking.


```sql
ALTER TABLE "outbound"."LocationJournals" ADD COLUMN nolog_user varchar; 
COMMENT ON COLUMN "outbound"."LocationJournals".nolog_user IS E'(technical) user who modified the entry as noted in source table';

ALTER TABLE "outbound"."LocationJournals" ADD COLUMN nolog_update timestamp; 
COMMENT ON COLUMN "outbound"."LocationJournals".nolog_update IS E'(technical) timestamp of last modification as noted in source table';
```