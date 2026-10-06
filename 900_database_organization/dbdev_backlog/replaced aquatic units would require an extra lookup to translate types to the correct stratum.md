---
aliases:
tags:
  - 111_distribute_loceval_via_mnmsyncdb
  - type
  - stratum
  - aquatic
started:
finished:
execution:
status: false
priority:
---


In `111_distribute_loceval_via_mnmsyncdb.R`:

```r
sampleunits_upload <- new_sampleunits %>%
    # TODO: this is an issue - simply renaming the field is
    #       only accidentally valid for terrestrial units.
    dplyr::rename(stratum = type) %>% # [...]
```

This is almost a valid approach, under the given circumstances,
but must be changed if ever we get aquatic units replaced.

Similar issue for `112_fill_location_journals.R`, but less practical relevance (because the joined tables can be converted stratum -> type)
```r
local_replacement_lookup <- mnmgwdb$query_columns(
    "ReplacementData",
    c("grts_address_original", "type", "grts_address_replacement")
  ) %>%
  distinct()
```