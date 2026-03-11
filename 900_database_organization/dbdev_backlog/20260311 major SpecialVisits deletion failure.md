---
aliases:
  - deleted visits 20260311
tags:
  - fail
  - postmortem
started: 2026-03-11
finished:
execution:
  - "#FM"
status: false
---


## follow-up

re-running maintenance scripts while monitoring visit tables
```sql
SELECT DISTINCT 'i' AS tbl, visit_done, COUNT(*) FROM "inbound"."InstallationVisits" GROUP BY visit_done
UNION
SELECT DISTINCT 'p' AS tbl, visit_done, COUNT(*) FROM "inbound"."PositioningVisits" GROUP BY visit_done
UNION
SELECT DISTINCT 's' AS tbl, visit_done, COUNT(*) FROM "inbound"."SamplingVisits" GROUP BY visit_done
;
```

     tbl | visit_done | count 
    -----+------------+-------
     i   | f          |  2003
     i   | t          |   138
     p   | f          |  2027
     p   | t          |   126
     s   | f          |   891
     s   | t          |    29
    (6 rows)

The issue is caused by `900_database_organization/112_update_facalendar.R`
    -> probably a missing `ONLY` somewhere down the `update_cascade` function.

- sorted backup files and compared differences
- go through script linewise


## timeline

[[timeline/2026-03-11|2026-03-11]]
- <11:12> made a manual backup
- <11:15>-<12:10> executed maintenance script
- <13:45> issues observed first by Yglinga
- <13:49> investigation started: 
	- affects `**Visits`, those were moved to plain `Visits` with loss of data
	- reverse [[backup patching]] to restore 11:12 backup
- <14:20> restore backup, green light for changes
- <14:53> confirmation: the issue is caused by `900_database_organization/112_update_facalendar.R`