---
aliases:
tags:
  - LocationJournals
  - LoJos
  - type_is_absent
started: 2026-05-18
finished: 2026-05-18
execution:
  - FM
status: true
---

There seem to be ambiguities in the #LoJos due to 
+ `loceval_type_absence` (differing within #locevaldb )
+ `is_latest` (differing across databases)

```r
locationjournals_consolidated %>%
  count(
    grts_address,
    date,
    source,
    type_subset,
    activity_group_id
  ) %>%
  filter(n > 1) %>%
  head(1) %>%
  inner_join(locationjournals_statusquo) %>%
  knitr::kable()

```

| no     |  grts   |   date     | source  | type     |
|-------:|--------:|-----------:|:-------:|---------:|
|  1     |   23238 | 2025-07-17 | loceval | 9160     |
|  3     |   84598 | 2025-08-20 | loceval | 7150     |
|  5     |  219694 | 2025-09-05 | loceval | 91E0_vo  |
|  7     |  382254 | 2025-11-06 | loceval | 7150     |
|  9     |  826486 | 2025-08-01 | loceval | 6230_hmo |
| 12     | 1205598 | 2025-09-01 | loceval | 6510_hus |

```sql
SELECT * FROM "outbound"."LocationJournals"
WHERE grts_address = 826486
;
```

At first glance, this looks like an erroneous cross join over types.
Just resetting should be fine.

```sql
-- DELETE 
SELECT *
FROM "outbound"."LocationJournals"
WHERE source = 'loceval'
AND ((grts_address =   23238 AND type_subset = '9160')
  OR (grts_address =   84598 AND type_subset = '7150')
  OR (grts_address =  219694 AND type_subset = '91E0_vo')
  OR (grts_address =  382254 AND type_subset = '7150')
  OR (grts_address =  826486 AND type_subset = '6230_hmo')
  OR (grts_address = 1205598 AND type_subset = '6510_hus')
)
;
```