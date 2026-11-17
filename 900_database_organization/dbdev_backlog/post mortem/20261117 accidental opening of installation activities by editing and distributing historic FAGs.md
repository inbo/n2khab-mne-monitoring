---
aliases:
tags:
  - FieldworkPlanning
  - mnmgwdb
started: 2026-11-17
finished: 2026-11-17
execution:
  - FM
  - TDD
status: true
priority: 1
---

reported by #YDC / via #TDD
there were prior installations on which information was missing
editing them in #FieldworkPlanning caused new activities to appear in #FieldWork view

be filtered by checking all which are now planned (via #FieldCalendars `done_planning`) but which already have an installation (via #LocationJournals)

- cross check: 52 locations (plus one on GRTS `5422` actually planned but not adjusted)
- took pre- and post-intervention backup; stored diff
- tested on #staging first

```sql
SELECT *
FROM
  "outbound"."FieldCalendars" CAL,
  "inbound"."Visits" VIS
WHERE VIS.visit_id = CAL.visit_id
  AND CAL.done_planning
  AND NOT visit_done
  AND CAL.activity_group_id = 4
  AND NOT excluded
AND CAL.grts_address IN (
  SELECT DISTINCT grts_address
  FROM "outbound"."LocationJournals"
  WHERE activity_group_id = 4
  AND NOT (grts_address = 5422)
)
;



UPDATE
  "outbound"."FieldCalendars"
SET excluded = TRUE,
excluded_reason = CASE WHEN excluded_reason IS NULL THEN '' ELSE excluded_reason || ', ' END || '[FM 20261117 was previously installed]',
date_visit_planned = NULL
WHERE fieldcalendar_id IN (
  SELECT DISTINCT CAL.fieldcalendar_id
  FROM
    "outbound"."FieldCalendars" CAL,
    "inbound"."Visits" VIS
  WHERE VIS.visit_id = CAL.visit_id
    AND CAL.done_planning
    AND NOT visit_done
    AND CAL.activity_group_id = 4
    AND NOT excluded
  AND CAL.grts_address IN (
    SELECT DISTINCT grts_address
    FROM "outbound"."LocationJournals"
    WHERE activity_group_id = 4
    AND NOT (grts_address = 5422)
  )
)
;

```

