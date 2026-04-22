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
- ~~later set constraint~~ not possible: view `gwTransfer` and `LocationEvaluations` also union the #orthophoto evaluation which has no scheduled date; but then, there is always only exactly one ofo entry by design.

Steps:
1. adjust the view `loceval_gwTransfer.sql`: `++ VISIT.date_start,`
2. add column to `LocationEvaluations`:
	```sql
	ALTER TABLE "outbound"."LocationEvaluations" ADD COLUMN date_start date DEFAULT NULL;
    COMMENT ON COLUMN "outbound"."LocationEvaluations".date_start IS E'start of the scheduled loceval period, NULL for orthophotos';
	```
3. Update table data (`LocationEvaluations` gets `tabula_rasa`, so `date_start` will be overwritten).

TODO check that other scripts can handle the new column.