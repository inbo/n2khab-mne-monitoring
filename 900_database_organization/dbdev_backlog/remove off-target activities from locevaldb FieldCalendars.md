---
aliases:
tags:
  - FieldCalendars
  - Visits
  - GroupedActivities
  - archive
started:
finished:
execution:
status: false
---

In some old version of the scripts and REP, activities from other databases were uploaded to #locevaldb. 
Those are irrelevant.
Some are correctly flagged with an `archive_version_id`; others are still open (hopefully filtered in QGIS project).

```sql
SELECT DISTINCT activity_group_id, activity_group
FROM "metadata"."GroupedActivities"
WHERE activity_group_id IN (
  SELECT DISTINCT activity_group_id FROM "inbound"."Visits"
  WHERE archive_version_id IS NULL
)
ORDER BY activity_group_id
;
```

In theory, only the following should remain:
```
17 | LOCEVALAQ
18 | LOCEVALTERR
19 | LSVIAQ
20 | LSVITERR
```

However, check first with the actual data (visit_done?) and with the REP.