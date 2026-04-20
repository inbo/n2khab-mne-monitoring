---
aliases:
  - double loceval anticipation
tags:
  - loceval
  - freeze
started: 2026-04-10
finished: 2026-04-10
execution:
  - FM
status: true
---
*I was actually planning to busy myself with something totally different,
but then the maintenance scripts crashed for a new case.*

> [!note] **Summary:**
> #WD had tagged a loceval from previous year, but incompletely worked it off.
> This initially seemed to be our very first case of [[Have I been here before - return to a previous loceval location for a second time]]. 
> However, the photo timestamp revealed that this was alteration of a frozen record - whether intentional or unintentional.

evidence:
```sql
loceval_staging=> SELECT grts_address, type, date_start, activity_group_id, teammember_id, date_visit, type_assessed, photo, visit_done, archive_version_id FROM "inbound"."Visits" WHERE grts_address = 6110;
 | grts_address       |                               6110 |                               6110 |
 | type               |                               9120 |                               9120 |
 | date_start         |                         2025-04-01 |                         2026-04-01 |
 | activity_group_id  |                                 18 |                                 18 |
 | teammember_id      |                                    |                                 13 |
 | date_visit         |                                    |                         2026-03-25 |
 | type_assessed      |                               9120 |                               9120 |
 | photo              | DCIM/loceval_20260403103115300.jpg | DCIM/loceval_20260403103115300.jpg |
 | visit_done         |                                  t |                                  t |
 | archive_version_id |                                    |                                    |
(2 rows)
```

this is the only case:
```sql
SELECT * FROM "inbound"."Visits" WHERE date_visit IS NULL AND visit_done;
| visit_id                  |                                 1528 |
| log_user                  |                           salamandra |
| log_update                |           2026-04-10 07:07:19.182517 |
| sampleunit_id             |                                   47 |
| location_id               |                                 2793 |
| grts_address              |                                 6110 |
| type                      |                                 9120 |
| teammember_id             |                                      |
| date_visit                |                                      |
| type_assessed             |                                 9120 |
| notes                     | Nauwkeurigheid: 2.5cm. Vervangcel 1. |
| photo                     |   DCIM/loceval_20260403103115300.jpg |
| visit_done                |                                    t |
| activity_group_id         |                                   18 |
| date_start                |                           2025-04-01 |
| fieldactivitycalen dar_id |                                 1528 |
| archive_version_id        |                                      |
| is_well_developed_type    |                                      |
(1 row)
```

Solved pragmatically by:
```sql
loceval=# UPDATE "inbound"."Visits" SET visit_done = FALSE, photo = NULL, notes = NULL, type_assessed = NULL WHERE date_visit IS NULL AND visit_done AND grts_address = 6110;
UPDATE 1
```


Another one appeared; slightly different because the frozen visit is better filled (this month, retrospectively):
```sql
SELECT * FROM "inbound"."Visits" WHERE grts_address = 18986217 AND visit_done;
 | visit_id           |       3556 |       3555 |
 | log_user           | salamandra | salamandra |
 | sampleunit_id      |       2387 |       2387 |
 | location_id        |       2287 |       2287 |
 | grts_address       |   18986217 |   18986217 |
 | teammember_id      |          7 |          7 |
 | date_visit         | 2026-04-09 | 2026-04-09 |
 | type_assessed      |    91E0_sf |    91E0_sf |
 | visit_done         |          t |          t |
 | type               |    91E0_sf |    91E0_sf |
 | activity_group_id  |         18 |         18 |
 | date_start         | 2026-03-15 | 2025-03-15 |
 | facalendar_id      |       3556 |       3555 |
 | archive_version_id |            |            |
 | is_wdt             |            |            |
 
-- photo = 'loceval_20260409131037097.JPG', notes = 'Naiwkeurigheid 2 cm, wilgenbos uiteen gevallen
 
(2 rows)
```

solved:
```sql
-- SELECT * FROM "inbound"."Visits"
UPDATE "inbound"."Visits" SET
notes = 'Naiwkeurigheid 2 cm, wilgenbos uiteen gevallen'
WHERE grts_address = 18986217 AND date_start = '2026-03-15';

-- SELECT * FROM "inbound"."Visits"
UPDATE "inbound"."Visits" SET 
  teammember_id = NULL,
  date_visit = NULL,
  type_assessed = NULL,
  visit_done = FALSE,
  photo = NULL,
  notes = NULL
WHERE visit_done AND grts_address = 18986217 AND date_start = '2025-03-15';
```
