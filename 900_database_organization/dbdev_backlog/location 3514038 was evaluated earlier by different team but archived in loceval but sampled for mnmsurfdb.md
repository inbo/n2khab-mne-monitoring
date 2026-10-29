---
aliases:
tags:
started:
finished:
execution:
status: false
priority:
---

two issues:
- Why has this location been partly archived on loceval, but not on #mnmsurfdb?
- How do we retrieve and automatically link positive or negative locevals from other teams?
- Pre-activity-date: this loceval should be due for an earlier revisit than expected.

on loceval:
```sql
SELECT * 
FROM "inbound"."Visits" AS VIS
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group
  FROM "metadata"."GroupedActivities"
  GROUP BY activity_group_id, activity_group
) AS AGRP
  ON AGRP.activity_group_id = VIS.activity_group_id
WHERE grts_address = 3514038 
  AND date_start > '2025-12-31' 
  AND archive_version_id IS NULL
;
```

```
name | log_update | date_visit | activity   | notes
wout | 2026-07-10 | NULL       | SAMPLPOINT | Habitattype niet aanwezig
ward | 2026-09-17 | 2024-09-17 | LOCEVALAQ  | Team zoetwaterhabitat heeft 2 jaar geleden habitat reeds bepaald. 3130_na en 3130_aom

```

```sql
SELECT 
  grts_address,
  stratum,
  activity_group_id,
  date_start,
  wait_any,
  excluded,
  done_planning,
  matching_occasion,
  visit_id
FROM "outbound"."FieldCalendars" AS CAL
WHERE grts_address = 3514038 
  AND date_start > '2025-12-31' 
  AND archive_version_id IS NULL
;

SELECT * 
FROM "inbound"."Visits" AS VIS
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group
  FROM "metadata"."GroupedActivities"
  GROUP BY activity_group_id, activity_group
) AS AGRP
  ON AGRP.activity_group_id = VIS.activity_group_id
WHERE grts_address = 3514038 
  AND date_start > '2025-12-31' 
  AND archive_version_id IS NULL
;
```

Overview/history according to `080_connected_by_GRTS.qmd`:
- This pond was supposed to hold three habitat types: `{3150, 3130_aom, 3130_na}`.
- Two of them were archived in REP 0.17; only `3150` remained for #loceval.
- Loceval was negative for `3150`; in contrast, `3130*` types were both positively assessed earlier by other team.
- Nonetheless, SURFLENTDATACOLL were executed on `2026-07-30` and `2026-09-01`.


initial lead:
```sql
SELECT
  grts_address,
  type,
  eval_date,
  eval_name AS loceval_colleague,
  (  ((LEVA.type_assessed IS NULL)
     OR (LEVA.type_assessed = LEVA.type))
     AND NOT LEVA.type_is_absent
  ) AS loceval_positive,
  photo AS loceval_photo,
  notes AS loceval_notes
FROM "transfer"."LocationEvaluations" AS LEVA
WHERE eval_source = 'loceval'
AND grts_address = 3514038
;
```