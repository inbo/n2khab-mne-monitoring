---
aliases:
  - deleted visits 20260311
tags:
  - fail
  - postmortem
started: 2026-03-11
finished: 2026-03-13
execution:
  - "#FM"
status: true
---

## future prevention
- [[locations/MNMDatabaseConnection.R|DatabaseConnection]] updated to allow `ONLY` queries (which had repercussions, but works)
- automatic dump prior to update; also in YAD GUI
- count table rows pre/post in `112_update_facalendar.R` to see issues

## follow-up

re-running maintenance scripts while monitoring visit tables
```sql
SELECT DISTINCT 'i' AS tbl, visit_done, COUNT(*) FROM "inbound"."InstallationVisits" GROUP BY visit_done
UNION
SELECT DISTINCT 'p' AS tbl, visit_done, COUNT(*) FROM "inbound"."PositioningVisits" GROUP BY visit_done
UNION
SELECT DISTINCT 's' AS tbl, visit_done, COUNT(*) FROM "inbound"."SamplingVisits" GROUP BY visit_done
UNION
SELECT DISTINCT 'v' AS tbl, visit_done, COUNT(*) FROM ONLY "inbound"."Visits" GROUP BY visit_done
;
```

     tbl | visit_done | count 
    -----+------------+-------
     i   | f          |  2002
     i   | t          |   139
     p   | f          |  2027
     p   | t          |   126
     s   | f          |   891
     s   | t          |    29
     v   | f          |  3701
     v   | t          |    36
    (8 rows)

The issue is caused by `900_database_organization/112_update_facalendar.R`
    -> probably a missing `ONLY` somewhere down the `update_cascade` function.

- sorted backup files and compared differences
- go through script line-wise (repeatedly)

Narrowing it down:
- issue was indeed caused by `Visits` update
- [[timeline/2026-03-13|2026-03-13]] attempt to re-factor `query_table`, `query_columns` and derivatives in [[locations/MNMDatabaseConnection.R|MNMDatabaseConnection.R]]
- new issue: the `ONLY Visits` do not match, some get deleted
	- reason were #duplicates in the `visit_id`
	- which in turn were caused by a #sequence reset issue with the inheritance chain
	- problem temporarily approached by setting `seq_visit_id` to `max` prior to cascaded update of `Visits` 
	 - also: [[hacks/resetting primary key column|pk hard reset]] of `Visits` and `Rscript 102_re_link_foreign_keys.R`

However, there must be a place in the 

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
- afterwards: various update attempts and testing

[[timeline/2026-03-13|2026-03-13]]
- refactoring of `query_table` and derivatives lead to some trickle-down issues
- <13:30> solved and successfully updated