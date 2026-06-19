---
aliases:
  - REP 0.17.0
tags:
  - REP
  - dataupdate
started: 2026-06-19
finished:
execution:
  - FM
status: false
---

anticipatory work thanks to preparations by #FV

# Re-Organized Grouped Activities

- `411_update_grouped_activities.qmd`

## (0) structure

> [!important] Add Column to #GroupedActivities
> TODO `archive_version_id` for obsolete activities

## Part 1: Activity **Groups**
```r
> novel_groups %>% knitr::kable()
|activity_group     |
|:------------------|
|SURFLENTSAMPLPOINT |
|SURFLENTSECC       |
|SURFLOTSAMPLPOINT  |
|SURFLOTSECC        |


> obsolete_groups %>% knitr::kable()
|activity_group            | activity_group_id|
|:-------------------------|-----------------:|
|SURFLENTLOCEVALSAMPLPOINT |                33|
|SURFLOTLOCEVALSAMPLPOINT  |                36|
```

> [!important] (1) Rename Activity Groups
> ```sql
> UPDATE "metadata"."GroupedActivities"
> SET (activity_group = 'SURFLENTSAMPLPOINT') WHERE activity_group = 'SURFLENTLOCEVALSAMPLPOINT';
> UPDATE "metadata"."GroupedActivities"
> SET (activity_group = 'SURFLOTSAMPLPOINT') WHERE activity_group = 'SURFLOTLOCEVALSAMPLPOINT';
> ```



```r
# activity composition changes in SURF*SAMPLPOINT 
| grouped_activity_id| activity_group_id|activity_group            | activity_id|activity           |
|-------------------:|-----------------:|:-------------------------|-----------:|:------------------|
|                  43|                33|SURFLENTLOCEVALSAMPLPOINT |          15|LOCEVALAQ          |
|                  44|                33|SURFLENTLOCEVALSAMPLPOINT |          32|SURFLENTSAMPLPOINT |
|                  50|                36|SURFLOTLOCEVALSAMPLPOINT  |          15|LOCEVALAQ          |
|                  51|                36|SURFLOTLOCEVALSAMPLPOINT  |          38|SURFLOTSAMPLPOINT  |


```

