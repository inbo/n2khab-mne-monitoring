Take the following test query:

```sql
WITH test_query AS (
SELECT 
  assessment_done, 
  NOT assessment_done AS bool_test_not, 
  assessment_done IS TRUE AS bool_test_true, 
  assessment_done IS FALSE AS bool_test_false, 
  CASE WHEN assessment_done THEN 1 ELSE 0
  END AS case_test,
  CASE WHEN NOT assessment_done THEN 0 ELSE 1
  END AS case_test_not
FROM "outbound"."FieldworkPlanning"
)
SELECT DISTINCT 
  assessment_done, bool_test_not, bool_test_true, bool_test_false, case_test, case_test_not,
  COUNT(*) AS n
FROM test_query
GROUP BY assessment_done, bool_test_not, bool_test_true, bool_test_false, case_test, case_test_not
;

```

Observations:
+ Basic setting: there are `NULL` values among the booleans.
+ The `NOT` operator retains `NULL` values as `NULL`.
+ The `IS` comparator determines `NULL` values to be non-matching, both for `IS TRUE` and `IS FALSE`.
+ `CASE WHEN` evaluates similar as the `IS` comparator: `NULL` values always end up in the `ELSE` clause.