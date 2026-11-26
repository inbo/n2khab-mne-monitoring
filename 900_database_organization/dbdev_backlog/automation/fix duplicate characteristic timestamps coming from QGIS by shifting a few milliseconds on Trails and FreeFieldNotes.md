---
aliases:
tags:
  - duplicates
  - log_creation
  - FreeFieldNotes
  - Trails
  - dailies
started: 2026-11-18
finished: 2026-11-18
execution:
  - FM
status: true
priority:
---

#QGIS updates against the server only on manual interaction:
after the "Save Layer Edits" button is pressed will it generate one or multiple `INSERT`s.
This can lead to totally unrelated features receiving the exact same timestamp.

Because the only identifiers we have here are `log_creator` and `log_creation`, those duplicates lead to erroneous joins and feature duplication upon sync.

I had hand-fixed duplicate timestamps in #FreeFieldNotes and #Trails once or twice before,
but there were particularly many on some [[timeline/2026-11-16|2026-11-16]] inserts by #WT.

SOLUTION: wiggle `log_creation` by a few milliseconds.


A general query to find `log_creation` duplicates:
```sql
SELECT DISTINCT
  log_creator,
  log_creation,
  count(*) AS n
FROM "inbound"."Trails"
GROUP BY
  log_creator,
  log_creation
HAVING count(*) > 1
;
```

building a query to shift the creation date:

```sql
WITH rectify AS
(
  SELECT DISTINCT
    log_creation,
    MIN(trail_id) AS millishiftback
  FROM "inbound"."Trails"
  GROUP BY log_creation
)
SELECT
  trail_id,
  TR.log_creation,
  TR.log_creation + ((trail_id - millishiftback) * interval '1  ms') AS shifted
FROM "inbound"."Trails" TR
LEFT JOIN rectify RE
  ON TR.log_creation = RE.log_creation
WHERE DATE(TR.log_creation) = '2026-11-16'
;
```


And generalize it to an `UPDATE... FROM` query.

```sql
WITH rectify AS
(
  SELECT DISTINCT
    log_creation,
    MIN(trail_id) AS millishiftback
  FROM "inbound"."Trails"
  GROUP BY log_creation
)
UPDATE "inbound"."Trails" TR
SET
  log_creation = TR.log_creation + ((TR.trail_id - RE.millishiftback) * interval '1  ms')
FROM rectify RE
WHERE TR.log_creation = RE.log_creation
;
```

This was integrated to `110_sync_FreeFieldNotes.R` and `110_sync_Trails.R`.