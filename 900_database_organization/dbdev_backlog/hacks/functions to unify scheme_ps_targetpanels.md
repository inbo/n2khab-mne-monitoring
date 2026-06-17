---
aliases:
tags:
---

## example implementation
assumptions: 
- all other columns are commonly/uniquely associated with the whole set of schemes and targetpanels
- `schemes` are contained in `scheme_ps_targetpanels`

```r
sample_units_upload <- sample_units %>%
  select(
    # assumption: schemes are contained in scheme_ps_targetpanels
    -schemes
  ) %>%
  mutate(
    # split the content of `scheme_ps_targetpanels` into a list column
    scheme_ps_targetpanels = stringr::str_split(scheme_ps_targetpanels, "\\|")
  ) %>%
  unnest(
    # unnest the list column: 
    # multiplicates rows if multiple entries in list, i.e. if entry was split at the "|"
    scheme_ps_targetpanels 
  ) %>%
  mutate(
    # trim leading and trailing whitespace
    scheme_ps_targetpanels = stringr::str_trim(scheme_ps_targetpanels, side = "both")
  ) %>%
  tidyr::separate_wider_delim(
    # separate schemes and ps_targetpanels, but also keep the combined column
    scheme_ps_targetpanels,
    delim = ":",
    names = c("schemes", "ps_targetpanels"),
    cols_remove = FALSE
  ) %>%
  select(
    # (optionally remove one of the split columns)
    -ps_targetpanels
  ) %>%
  group_by(
    # old-school manual group-summarize-ungroup (because `across` does not work in `.by`)
    across(c(-schemes, -scheme_ps_targetpanels))
  ) %>%
  summarize(
    # sort and collapse all unique schemes and scheme/targetpanel combinations
    schemes = paste0(sort(unique(schemes)), collapse = "|"),
    scheme_ps_targetpanels = paste0(sort(unique(scheme_ps_targetpanels)), collapse = "|"),
    .groups = "drop_last"
  ) %>%
  ungroup() %>%
  arrange(grts_address, stratum, schemes)

```