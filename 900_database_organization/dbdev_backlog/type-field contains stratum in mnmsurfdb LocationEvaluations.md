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
SELECT
CAL.grts_address,
CAL.stratum,
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
LEFT JOIN "transfer"."LocationEvaluations" AS EVAL
  ON (EVAL.grts_address = VIS.grts_address)
  AND (EVAL.type = ANY(VIS.stratums))
LEFT JOIN "outbound"."FieldCalendars" AS CAL
  ON VIS.visit_id = CAL.visit_id
WHERE VIS.grts_address IN (222878, 452914, 617774)
;

```