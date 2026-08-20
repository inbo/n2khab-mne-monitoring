---
aliases:
  - missing photos
tags:
  - photos
started:
finished:
execution:
status: false
priority:
---

[[timeline/2026-08-20|2026-08-20]] created a script for photo distribution and sharing
However, some photo files are not submitted as they were stored in the database.

```sql
SELECT * FROM "inbound"."Visits" WHERE photo LIKE '%loceval_20260713162820191%';
```

See `900_database_organization/data/photos_missing.csv`
and script `940_sort_photos_for_sharing.py` 
check examples and find patterns
