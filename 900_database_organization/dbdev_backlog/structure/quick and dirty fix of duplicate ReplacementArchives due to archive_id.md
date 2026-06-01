---
aliases:
tags:
  - duplicates
  - ReplacementArchives
  - sql
  - characteristic_columns
started: 2026-06-01
finished: 2026-06-01
execution:
  - FM
status: true
---

There seems to be a double replacements which bounces on our strict join rules:

```r
processing 22 / 22: "archive"."ReplacementArchives"
DELETE FROM ONLY "archive"."ReplacementArchives";
done.
Error in `left_join()`:
! Each row in `x` must match at most 1 row in `y`.
ℹ Row 1 of `x` matches multiple rows in `y`.
```

Turns out there are many; maybe the issue was changing the join restrictions in the first place:
```sql
SELECT *
FROM (
  SELECT DISTINCT grts_address, type, grts_address_replacement, version_id, COUNT(*) AS n
  FROM "archive"."ReplacementArchives"
  GROUP BY grts_address, type, grts_address_replacement, version_id
)
WHERE n > 1
```

```sql
SELECT grts_address, type, replacement_rank, *
FROM "archive"."ReplacementArchives"
WHERE grts_address = 7145 AND type = '9160' 
ORDER BY grts_address, type, replacement_rank
;
```

or, in R:
```r
new_data %>%
  select(-replacementarchive_id) %>%
  arrange(!!!rlang::syms(characteristic_columns)) %>%
  distinct() %>%
  filter(grts_address == 7145, type == '9160') %>%
  t() %>% knitr::kable()

```

```example
|  grts | type | rank | *ve_id | replacement | type_is_absent | is_inappropriate | is_selected | version_id | date_visit |
|  7145 | 9160 |    9 |   6901 |    16784361 | f              | t                | f           |          7 | 2026-04-10 |
|  7145 | 9160 |    9 |   6902 |    16784361 | f              | t                | f           |          8 | 2026-04-10 |
|  7145 | 9160 |   23 |   6903 |    46144489 | f              | f                | t           |          7 | 2026-04-10 |
|  7145 | 9160 |   23 |   6904 |    46144489 | f              | f                | t           |          8 | 2026-04-10 |
```

dirty-fix by `if (table_label == "ReplacementArchives") {...}`

