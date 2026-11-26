---
aliases:
tags:
  - Visits
  - QGIS
started: 2026-11-18
finished: 2026-11-18
execution:
  - FM
status: true
priority:
---

Visually identified a location
where we registered execution of a `READDIVER` / diver readout without any prior installation.

> [!note] Location
> ```
> | GRTS address |      48950 |
> | stratum      |       9160 |
> | date_visit   | 2026-03-11 |
> | teammember   |       #YDC |
> ```

There was a photo which also is associated with a visit further north.

Logging columns were not functional back then; #YDC could not find notes on it.
We assume that this was an erroneous entry.


```sql
SELECT * FROM "inbound"."Visits" WHERE visit_done AND date_visit = '2026-03-11';
 visit_id |  log_user   |         log_update         | fieldcalendar_id | sampleunit_id | location_id | grts_address | activity_group_id | date_st
art | teammember_id | date_visit | notes |                photo                 | issues | visit_done | stratum  | archive_version_id | protocol_i
d 
----------+-------------+----------------------------+------------------+---------------+-------------+--------------+-------------------+--------
----+---------------+------------+-------+--------------------------------------+--------+------------+----------+--------------------+-----------
--
     6609 | maintenance | 2026-02-27 06:47:28.925935 |           106054 |         84418 |      113800 |      9424086 |                 4 | 2028-07
-01 |             1 | 2026-03-11 |       | DCIM/fieldwork_20260311143525640.jpg | f      | t          | 6230_hmo |                    |           
 
    15506 | maintenance | 2026-05-18 07:21:11.496616 |            97385 |         82995 |      112246 |        48950 |                 9 | 2026-10
-01 |             1 | 2026-03-11 |       | DCIM/fieldwork_20260311143525640.jpg | f      | t          | 9160     |                    |           
 
(2 rows)
```


## Solution

manually removed the information in QGIS