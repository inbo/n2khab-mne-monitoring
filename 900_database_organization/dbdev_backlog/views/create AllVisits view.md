---
aliases:
  - AllVisits view
tags:
  - views
  - gwdb
started: 2026-03-19
finished: 2026-03-19
execution:
  - "#FM"
status: true
---

[[procedures/create view]]

This view simply assembles all info from Visits, as if it was one big table.
*cf.* <https://github.com/inbo/tutorials/tree/sql_inheritance>

```
SELECT *
FROM ONLY "inbound"."Visits"
NATURAL FULL JOIN "inbound"."InstallationVisits"
NATURAL FULL JOIN "inbound"."SamplingVisits"
NATURAL FULL JOIN "inbound"."PositioningVisits"
ORDER BY visit_id ASC
;
```

The view is **read-only**, i.e. it shall not be used to update rows.
```sql
CREATE RULE AllVisits_upd0 AS
ON UPDATE TO "inbound"."AllVisits"
DO INSTEAD NOTHING;
```

Any db viewer has read permissions.
```sql
GRANT SELECT ON "inbound"."AllVisits" TO viewer_mnmdb;
```