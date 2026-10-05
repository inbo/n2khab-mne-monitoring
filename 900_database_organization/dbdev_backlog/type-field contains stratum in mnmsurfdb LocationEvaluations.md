---
aliases:
tags:
started:
finished:
execution:
status: false
priority:
---


```sql
WITH unnested_types AS (
    SELECT
    locationevaluation_id AS le_id,
    STRING_TO_ARRAY(type, '_') AS stratum_arr
    FROM "transfer"."LocationEvaluations"
    ORDER BY locationevaluation_id ASC
  )
  UPDATE "transfer"."LocationEvaluations" AS TRGTAB
    SET type = SRCTAB.type
  FROM
  (
    SELECT
      le_id,
      stratum_arr,
      ARRAY_TO_STRING(
        CASE WHEN CARDINALITY(stratum_arr) = 3
        THEN stratum_arr[1:1]
        ELSE
          CASE WHEN CARDINALITY(stratum_arr) > 3
          THEN stratum_arr[1:2]
          ELSE stratum_arr
          END
        END, 
        '_') AS type
    FROM unnested_types
  ) AS SRCTAB
  WHERE
   (TRGTAB.locationevaluation_id = SRCTAB.le_id)
  ;
```


```sql
SELECT
  CAL.grts_address,
  CAL.stratum,
  CAL.date_start,
  CAL.date_visit_planned,
  CAL.excluded,
  CAL.excluded_reason,
  VIS.stratums,
  VIS.visit_done,
  EVAL.type,
  EVAL.type_assessed,
  (EVAL.type_assessed IS NOT NULL) AND (EVAL.type_assessed = EVAL.type) AS loceval_positive,
  EVAL.type_is_absent,
  EVAL.eval_date
FROM "inbound"."LenticVisits" AS VIS
LEFT JOIN "outbound"."FieldCalendars" AS CAL
  ON VIS.visit_id = CAL.visit_id
LEFT JOIN (
  SELECT DISTINCT type, stratum
  FROM "metadata"."N2kHabStrata"
  GROUP BY type, stratum
  ) AS STRAT
  ON CAL.stratum = STRAT.stratum
LEFT JOIN "transfer"."LocationEvaluations" AS EVAL
  ON (EVAL.grts_address = VIS.grts_address)
  AND (EVAL.type = STRAT.type)
WHERE VIS.grts_address IN (222878, 452914, 617774)
ORDER BY CAL.grts_address, CAL.date_start, CAL.stratum
;

```