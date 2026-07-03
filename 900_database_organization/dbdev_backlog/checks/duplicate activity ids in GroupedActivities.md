---
aliases:
tags:
  - GroupedActivities
---

```sql
SELECT * 
FROM (
SELECT DISTINCT activity_group, COUNT(DISTINCT activity_group_id) AS N
FROM "metadata"."GroupedActivities"
GROUP BY activity_group
UNION
SELECT DISTINCT activity, COUNT(DISTINCT activity_id) AS N
FROM "metadata"."GroupedActivities"
GROUP BY activity
)
WHERE N > 1;
```


## archive
... fix hiccups on `-testing` and other mirrors

```sql
UPDATE "metadata"."GroupedActivities"
SET activity_id = 33
WHERE activity = 'SURFLENTSECC';
UPDATE "metadata"."GroupedActivities"
SET activity_id = 39
WHERE activity = 'SURFLOTSECC';
```