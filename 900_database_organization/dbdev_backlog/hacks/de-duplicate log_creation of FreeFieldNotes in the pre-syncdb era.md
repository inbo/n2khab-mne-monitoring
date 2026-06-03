---
aliases:
tags:
  - FreeFieldNotes
  - duplicates
started: 2026-05-20
finished: 2026-05-20
execution:
  - FM
status: true
---

During [[structure/draft and implement mnmsyncdb a database for synchronization of interchange data]], one work package was to create a sync script for #FreeFieldNotes. 
Some of the pre-existing fieldnotes were duplicates.
I suspect that this happened if notes were altered by another user in the other database.

```r
> freefieldnotes_userdb %>%
+     count(log_creation) %>%
+     filter(n>1)
# A tibble: 5 × 2
  log_creation            n
  <dttm>              <int>
1 2025-08-07 10:04:31     2
2 2025-08-08 14:54:46     2
3 2025-09-26 13:57:44     2
4 2025-12-19 14:52:18     2
5 2026-04-21 08:12:22    14

```

OR:

```sql
SELECT * FROM (
SELECT DISTINCT log_creation, MAX(log_update), COUNT(*) AS n
FROM "inbound"."FreeFieldNotes"
GROUP BY log_creation
) WHERE n > 1
;
```
|  log_creation               |            max             | n  |
|:----------------------------|----------------------------|:----: |
| 2025-08-07 10:04:30.860841 | 2026-02-19 11:02:25.027186 |  2 |
| 2025-08-08 14:54:46.260688 | 2025-11-17 11:58:29.856321 |  2 |
| 2025-12-19 14:52:17.710931 | 2025-12-19 14:52:17.710931 |  2 |
| 2025-09-26 13:57:43.826691 | 2025-09-26 13:57:43.826691 |  2 |
| 2026-04-21 08:12:22.21249  | 2026-04-21 08:12:22.21249  | 14 |


```sql
SELECT * 
FROM "inbound"."FreeFieldNotes"
WHERE log_creation = '2025-07-17 07:35:49.399632'
;

-- WHERE log_creation = '2025-12-19 14:52:17.710931'
-- WHERE log_creation = '2025-09-26 13:57:43.826691'
-- WHERE log_creation = '2026-04-21 08:12:22.21249'
-- WHERE log_creation = '2025-08-07 10:04:30.860841'

  
  SELECT *
  FROM "inbound"."FreeFieldNotes" AS FFN
  WHERE wkb_geometry = '01010000208A7A00002AFEA3E0CE580D41139ABCCC6D020841'
  -- WHERE wkb_geometry = '01010000208A7A0000436915DBBE3309415FB7FA236BEF0841'

```

Oh, hold back! The fourteen notes on 2026-04-21 are different story.

## Case 1: same creation timestamp, but different location

These are cases where for some (probably technical) reason all notes received the same creation time.
This is solved by slightly shifting creation time.

```sql
SELECT * FROM (
SELECT DISTINCT wkb_geometry, log_creation, MAX(log_update), COUNT(*) AS n
FROM "inbound"."FreeFieldNotes"
GROUP BY log_creation, wkb_geometry
) WHERE n > 1
;
```

|        log_creation        |            max             |  n  |
|:---------------------------|:---------------------------|:---:|
| 2025-12-19 14:52:17.710931 | 2025-12-19 14:52:17.710931 |  2  |
| 2025-08-07 10:04:30.860841 | 2026-02-19 11:02:25.027186 |  2  |
| 2025-08-08 14:54:46.260688 | 2025-11-17 11:58:29.856321 |  2  |

The others are the actually interesting ones.
https://www.postgresql.org/docs/current/functions-datetime.html

Here is an example query to get one observation:
```sql
SELECT wkb_geometry, fieldnote_id, log_creation, log_update
FROM "inbound"."FreeFieldNotes"
WHERE log_creation = '2025-09-26 13:57:43.826691'
;

```

This query gets all of the duplicate, non-co-located notes:
i.e. we get a list of all the notes which have identical creation timestamp, but different location point.
```sql
SELECT * 
FROM "inbound"."FreeFieldNotes"
WHERE wkb_geometry NOT IN (
  -- SELECT wkb_geometry, fieldnote_id, log_creation FROM (
  SELECT wkb_geometry FROM (
    SELECT DISTINCT log_creation, MIN(fieldnote_id) AS first_id
    FROM "inbound"."FreeFieldNotes"
    GROUP BY log_creation
  ) AS REF
  LEFT JOIN (
    SELECT fieldnote_id, wkb_geometry
    FROM "inbound"."FreeFieldNotes"
  ) AS GEO
    ON REF.first_id = GEO.fieldnote_id
)
ORDER BY log_creation
;

```


The following update statement can exploit this:
```sql

UPDATE "inbound"."FreeFieldNotes"
SET log_creation = log_creation + (INTERVAL '1 sec' * fieldnote_id)
WHERE wkb_geometry NOT IN (
  SELECT wkb_geometry FROM (
    SELECT DISTINCT log_creation, MIN(fieldnote_id) AS first_id
    FROM "inbound"."FreeFieldNotes"
    GROUP BY log_creation
  ) AS REF
  LEFT JOIN (
    SELECT fieldnote_id, wkb_geometry
    FROM "inbound"."FreeFieldNotes"
  ) AS GEO
    ON REF.first_id = GEO.fieldnote_id
)
;

```

> [!important] No temporal relevance.
> I just add the `fieldnote_id`, expressed as seconds, to the creation timestamp because it is unique. 
> There is of course no deeper meaning to this operation.


> [!issue] timestamp deviation
> because these exist differently in both databases, the creation times will now deviate.

This was applied to #prod on [[timeline/2026-05-20|2026-05-20]] to both #mnmgwdb and then #locevaldb. 
However, duplicates will appear to all the parking lots marked simultaneously; they should be deleted from gwdb if it was originally posted by a loceval planner.

## Case 2: actual duplicates due to modified note on the same location

Then, there are cases in which a note was modified (usually appended) in the other database.
Instead of simply promoting the modification, the old script^{TM} would generate two notes in the same spot.

```sql
SELECT *
-- DELETE 
FROM "inbound"."FreeFieldNotes" 
WHERE fieldnote_id IN (
  SELECT DISTINCT fieldnote_id
  -- SELECT *
  FROM "inbound"."FreeFieldNotes" AS FFN
  LEFT JOIN 
  (
    SELECT DISTINCT 
      log_creation, 
      wkb_geometry, 
      MAX(log_update) AS last_mod,
      MIN(fieldnote_id) AS first_id
    FROM "inbound"."FreeFieldNotes"
    GROUP BY log_creation, wkb_geometry
  ) AS UPDT
    ON ( 
      UPDT.log_creation = FFN.log_creation 
      AND UPDT.wkb_geometry = FFN.wkb_geometry 
    )
  WHERE (NOT (last_mod = log_update))
    -- OR (last_mod = log_update AND NOT fieldnote_id = first_id)
)  
;
 
```


## Case 3: shifted locations
The previous case can not be identified if geometry is changed upon note modification.
I cannot identify those cases since I rely on geometry as an identifier.

However, these should appear as adjacent duplicates on the actual notes and can be removed manually.

## Final Case: manual deletion
I just do not see the regularity of this case; it is missed by the filters above for rounding inaccuracies.

ATTENTION: each database has a different id.
```sql
SELECT * 
FROM "inbound"."FreeFieldNotes"
WHERE log_creation = '2025-12-19 14:52:17.710931'
;

SELECT *
-- DELETE 
FROM "inbound"."FreeFieldNotes"
WHERE log_creation = '2025-12-19 14:52:17.710931'
AND fieldnote_id NOT IN ()
;
```