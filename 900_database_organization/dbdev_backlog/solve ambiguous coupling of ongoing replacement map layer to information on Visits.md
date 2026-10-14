---
aliases:
tags:
  - ReplacementOngoing
  - views
  - Visits
started:
finished:
execution:
status: false
priority:
---

Filling fields which are supposed to link back to the #Visits while performing a #localreplacement via the #locevaldb #ReplacementOngoing #view will lead to multiple visits being filled.
The reason is that `replacement_ongoing` is stored on the level of #SampleUnits; it thereby links back to all planned Visits.

- check whether multiple features appear in the "replacement" map layer
- design a way to also mark a specific visit/occasion as `replacement_ongoing`, e.g. by trivially adding a field, or by moving the field from SampleUnits to Visits
- But also: make sure to unset that field in #Visits once the visit is done.
- Handle situations where none of the visits has ongoing replacement.

Note [[timeline/2026-10-14|2026-10-14]]:
+ four new cases
+ #WT was planning, but could not remember changing visit status
+ one was inverse (old FAG erroneously set to `visit_done`)

temp-fixed:
```sql
WITH find_visits AS (
  SELECT
    terrestrialtypesvisit_id,
    visit_id,
    grts_address,
    type,
    date_start,
    teammember_id,
    date_visit
  FROM "inbound"."TerrestrialTypesVisits"
  WHERE grts_address::VARCHAR || ':' || type IN ('23238:91E0_vm', '53662:9190', '190802:91E0_sf', '4390190:6410_ve')
    AND visit_done
    -- AND date_visit IS NULL
  ORDER BY grts_address, date_start
) -- ...
-- ...
-- UPDATE "outbound"."FieldCalendars"
-- SET excluded = TRUE, excluded_reason = '[20261014 FM: locevals on other visits]'
-- WHERE visit_id IN (SELECT visit_id FROM find_visits)
-- ;
-- ...
-- UPDATE "inbound"."Visits"
-- SET visit_done = FALSE
-- WHERE visit_id IN (SELECT visit_id FROM find_visits)
-- ;

```