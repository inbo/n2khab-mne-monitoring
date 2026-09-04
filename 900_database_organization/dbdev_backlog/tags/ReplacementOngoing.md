---
aliases:
tags:
  - ReplacementOngoing
  - Replacements
  - view
---
This view is an operative tool to show only a subset of #Replacements which is currently under evaluation and potential selection.

In an *inner* query, only the relevant replacements/units are found.
Here is a slightly modified, minimal example for debugging:

```sql
SELECT
  UNIT.grts_address,
  UNIT.type,
  UNIT.is_replaced,
  UNIT.type_is_absent AS absent,
  UNIT.replacement_ongoing,
  REP.is_selected AS sel,
  REP.replacement_rank AS nr,
  ( UNIT.replacement_ongoing
  AND NOT (UNIT.is_replaced OR UNIT.type_is_absent)
  ) AS vis_by_ongoing,
  ( REP.is_selected
  ) AS vis_by_selection
FROM "outbound"."Replacements" AS REP
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = REP.sampleunit_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON UNIT.location_id = INFO.location_id
WHERE
  UNIT.grts_address = 23238
  AND REP.replacement_rank IN (2, 2, 3, 13)
;
```

#Visits are joined to these replacement candidates to enable filling of Visit-level information on the map layer of replacement unit.