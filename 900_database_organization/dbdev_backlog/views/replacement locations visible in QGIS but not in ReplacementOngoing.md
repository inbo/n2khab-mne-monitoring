---
aliases:
tags:
  - replacements
  - qgis
  - ReplacementOngoing
started: 2026-03-24
finished: 2026-03-25
execution:
  - FM
status: true
---
>  I see dead replacement cells...

We normally do not want to see all replacement candidates of completed visits. 
This is why the #ReplacementOngoing  #view filters for `WHERE UNIT.replacement_ongoing OR [selected]`.
However, when deploying, this view does either NOT show selected replacements, or it still shows all.

example:
```sql
SELECT *
FROM "inbound"."ReplacementOngoing"
WHERE grts_address = 190802
;
```

but: QGIS showed them persistently

The issue was a suboptimal placement of the conditional in the SQL query of [[tags/ReplacementOngoing|ReplacementOngoing]].
Re-working the query: computing the conditions in the nested query and filtering on main query level fixed it; also switched join order for simplicity.