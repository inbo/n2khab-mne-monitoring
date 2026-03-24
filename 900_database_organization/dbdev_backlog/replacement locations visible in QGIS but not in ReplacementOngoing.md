---
aliases:
tags:
  - replacements
  - qgis
  - ReplacementOngoing
started: 2026-03-24
finished:
execution:
  - FM
status: false
---
>  I see dead replacement cells...

example:
```sql
SELECT *
FROM "inbound"."ReplacementOngoing"
WHERE grts_address = 190802
;
```

but: QGIS shows them persistently