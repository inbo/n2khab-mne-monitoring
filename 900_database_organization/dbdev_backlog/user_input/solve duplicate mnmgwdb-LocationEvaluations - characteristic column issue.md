---
aliases:
  - loceval simultaneous double registration
tags:
  - loceval
  - LocationEvaluations
  - duplicates
  - freeze
started: 2026-04-22
finished:
execution: FM
status: false
---
*(Follow-up of [[user_input/the frozen loceval from the present|the frozen loceval from the present]], because it happened again.)*
Sometimes, duplicates appear in #mnmgwdb `LocationEvaluations` upon transfer via `111a_push_loceval_to_mnmgwdb.R`.

```r
> duplicate_locevals
# A tibble: 2 × 5
  grts_address type    eval_date  eval_source     n
         <int> <chr>   <date>     <chr>       <int>
1      1126121 91E0_vn 2026-04-09 loceval         2
2     29258198 91E0_vm 2026-04-08 loceval         2
```

The issue is a combination of two inaccuracies: 
1. #WD and #WT see two LOCEVAL activities on the same location; one `is_frozen`, one not.
2. Characteristic columns for `mnmgwdb."outbound"."LocationEvaluations"` did not include the planned date, only `eval_date`.

## adding `date_start` column to `LocationEvaluations`
... is a bit tricky because it should be NOT NULL, but only after filling.
- initialized NULLable / even `DEFAULT NULL`
- ~~later set constraint~~ not possible: view `gwTransfer` and `LocationEvaluations` also union the #orthophoto evaluation which has no scheduled date; but then, there is always only exactly one #opho entry by design.

Steps:
1. adjust the view `loceval_gwTransfer.sql`: `++ VISIT.date_start,`
2. add column to `LocationEvaluations`:
	```sql
	ALTER TABLE "outbound"."LocationEvaluations" ADD COLUMN date_start date DEFAULT NULL;
    COMMENT ON COLUMN "outbound"."LocationEvaluations".date_start IS E'start of the scheduled loceval period, NULL for orthophotos';
	```
3. Update table data (`LocationEvaluations` gets `tabula_rasa`, so `date_start` will be overwritten).

## manually fix duplicates

```sql
SELECT 
  grts_address, type, date_start, activity_group_id, 
  teammember_id, date_visit, type_assessed, photo, 
  visit_done, archive_version_id, notes
FROM "inbound"."Visits" 
WHERE TRUE
  AND archive_version_id IS NULL
  AND activity_group_id = 18 
  AND grts_address IN (1126121, 1995222, 29258198);
```


    | grts_address  |                       1995222 |                       1995222 |    1126121 |    1126121 |
    | type          |                       91E0_vm |                       91E0_vm |    91E0_vn |    91E0_vn |
    | date_start    |                    2025-03-15 |                    2026-03-15 | 2025-03-15 | 2026-03-15 |
    | teammember_id |                             7 |                             7 |          7 |          7 |
    | date_visit    |                    2026-04-08 |                    2026-04-08 | 2026-04-09 | 2026-04-09 |
    | type_assessed |                       91E0_vm |                       91E0_vm |         gh |         gh |
    | photo         | loceval_20260408160510984.JPG | loceval_20260408160510984.JPG |            |            |
    | visit_done    |                             t |                             t |          t |          t |

```sql
UPDATE "inbound"."Visits" SET  notes = 'Type niet aanwezig hier'
-- SELECT * FROM "inbound"."Visits" 
WHERE grts_address = 1126121 AND date_start = '2026-03-15';

UPDATE "inbound"."Visits" 
SET visit_done = FALSE, photo = NULL, notes = NULL, type_assessed = NULL 
WHERE grts_address = 1126121  AND date_start = '2025-03-15';

UPDATE "outbound"."FieldActivityCalendar" 
SET no_visit_planned = TRUE
WHERE grts_address = 1126121 AND activity_group_id = 18 AND date_start = '2025-03-15';

```

```sql
UPDATE "inbound"."Visits" 
SET visit_done = FALSE, photo = NULL, notes = NULL, type_assessed = NULL 
WHERE grts_address = 1995222 AND date_start = '2025-03-15';

UPDATE "outbound"."FieldActivityCalendar" 
SET no_visit_planned = TRUE
WHERE grts_address = 1995222 AND activity_group_id = 18 AND date_start = '2025-03-15';

```

## check that other scripts can handle the new column

- [x] `111a_push_loceval_to_mnmgwdb.R` works, obviously 
- [x] `403_precalculate_fresh_snippets.R` completes without errors
- [x] `510_loceval_update_REP.qmd` -> manual adjustments see above
- [ ] `610_mnmgwdb_update_REP.qmd`

-> the issue also applies to the `ReplacementArchive` generation because `Visits` are joined based on `date_visit`.

TODO:
- [x] remove duplicates manually
- [x] continue ReplacementArchives correction