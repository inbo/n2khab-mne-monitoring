---
aliases:
  - init
tags:
  - Visits
  - FieldworkPlanning
  - UnplannedVisitCheck
  - checks
started: 2026-11-18
finished: 2026-11-18
execution:
  - FM
status: true
priority: 8
---

[[timeline/2026-11-18|2026-11-18]] found #Visits which did not get opened via #FieldworkPlanning
(or de-activated *ex post*).

```sql
SELECT
  VIS.grts_address,
  VIS.stratum,
  ACT.activity_group,
  VIS.date_start,
  VIS.log_user,
  VIS.log_update,
  VIS.date_visit,
  TEAM.username
FROM "inbound"."Visits" VIS
LEFT JOIN "outbound"."FieldCalendars" CAL
  ON VIS.visit_id = CAL.visit_id
LEFT JOIN "metadata"."ActivityGroups" ACT
  ON ACT.activity_group_id = VIS.activity_group_id
LEFT JOIN "metadata"."TeamMembers" TEAM
  ON TEAM.teammember_id = VIS.teammember_id
WHERE NOT done_planning
  AND visit_done
;
``` 

```
 grts_address | stratum  |   activity_group   | date_start |  log_user   |         log_update         | date_visit | username 
--------------+----------+--------------------+------------+-------------+----------------------------+------------+----------
      1176286 | 4010     | SPATPOSITPIPE      | 2025-10-01 | maintenance | 2026-02-27 06:47:29.53163  | 2026-01-12 | y
      1902553 | 9130_end | GWSHALLSAMPREADMAN | 2025-07-01 | maintenance | 2026-02-27 06:47:29.230095 | 2025-07-29 | w
     51431410 | 6230_hmo | GWSHALLSAMPREADMAN | 2025-07-01 | maintenance | 2026-02-27 06:47:29.230095 |            | 
      1818369 | 6230_hmo | GWSHALLCLEAN       | 2025-10-01 | maintenance | 2026-05-18 07:21:11.496616 | 2025-09-23 | y
       187382 | 91E0_vo  | GWLEVREADDIVERMAN  | 2026-07-01 | maintenance | 2026-05-18 07:21:11.496616 | 2026-03-09 | w
      1902553 | 9130_end | GWSHALLCLEAN       | 2025-07-01 | maintenance | 2026-05-18 07:21:11.496616 | 2025-07-29 | w
(6 rows)
```


## Solution

All were handled manually; those were either weird (old) cases as the original one, or just a missing check (presumably).

> [!note] Follow-up
> A new map layer was introduced to visually indicate unplanned visits #UnplannedVisitCheck. 
> Ideally, there will never be any.