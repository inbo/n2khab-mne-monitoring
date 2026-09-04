---
aliases:
  - array operations in postgreSQL
tags:
  - sql
  - arrays
---


Compare against a list of strings (synonymous)
```sql
WHERE category = ANY(ARRAY['biot', 'loceval'])
  AND category IN ('biot', 'loceval')
```

split string into array column by a separator character
```sql
SELECT ARRAY(SELECT TRIM(UNNEST(STRING_TO_ARRAY(type_subset, ',')))) AS types
    FROM "outbound"."LocationJournals"
WHERE type_subset LIKE '%,%'
;

```