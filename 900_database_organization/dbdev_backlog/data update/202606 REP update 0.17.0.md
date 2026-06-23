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
> define `archive_version_id` for obsolete activities
> ```sql
> ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN archive_version_id smallint; 
> COMMENT ON COLUMN "metadata"."GroupedActivities".archive_version_id IS E'(technical) flag archived sample units';
> -- ALTER TABLE "metadata"."GroupedActivities" DROP CONSTRAINT IF EXISTS fk_Versions_GroupedActivities CASCADE;
> ALTER TABLE "metadata"."GroupedActivities" ADD CONSTRAINT fk_Versions_GroupedActivities FOREIGN KEY (archive_version_id)
> REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
> ON DELETE SET NULL ON UPDATE CASCADE;
> ```

## Part 1: Activity **Groups**

### store a backup

```sql
\COPY (
  SELECT *
  FROM "metadata"."GroupedActivities"
  ORDER BY activity_group ASC, activity ASC
) TO '<...>/mnm_db_backups/metadata/20260622_GroupedActivities.csv' With CSV DELIMITER ',' HEADER
;

```


### overview
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

### rename
> [!important] (1) Rename Activity Groups
> ```sql
> UPDATE "metadata"."GroupedActivities"
> SET activity_group = 'SURFLENTSAMPLPOINT' WHERE activity_group = 'SURFLENTLOCEVALSAMPLPOINT';
> UPDATE "metadata"."GroupedActivities"
> SET activity_group = 'SURFLOTSAMPLPOINT' WHERE activity_group = 'SURFLOTLOCEVALSAMPLPOINT';
> ```


### archive
```r
# activity composition changes in SURF*SAMPLPOINT 
| grouped_activity_id| activity_group_id|activity_group            | activity_id|activity           |
|-------------------:|-----------------:|:-------------------------|-----------:|:------------------|
|                  43|                33|SURFLENTLOCEVALSAMPLPOINT |          15|LOCEVALAQ          |
|                  44|                33|SURFLENTLOCEVALSAMPLPOINT |          32|SURFLENTSAMPLPOINT |
|                  50|                36|SURFLOTLOCEVALSAMPLPOINT  |          15|LOCEVALAQ          |
|                  51|                36|SURFLOTLOCEVALSAMPLPOINT  |          38|SURFLOTSAMPLPOINT  |


```

> [!important] (2) archive `LOCEVALAQ`s in `*SAMPLPOINT`
> ```sql
> UPDATE "metadata"."GroupedActivities"
> SET archive_version_id = (SELECT MAX(version_id) FROM "metadata"."Versions")
> WHERE (activity_group = 'SURFLENTSAMPLPOINT')
>   AND (activity = 'LOCEVALAQ')
> ;
> UPDATE "metadata"."GroupedActivities"
> SET archive_version_id = (SELECT MAX(version_id) FROM "metadata"."Versions")
> WHERE (activity_group = 'SURFLOTSAMPLPOINT')
>   AND (activity = 'LOCEVALAQ')
> ;
> 
> ```

## Part 2: Activities

> [!warning] Do Not Partially Change Activity Group
> If the composition of an activity group changes, the subsets cannot be saved by renaming.
> Calendar entries in the database are summarized by `activity_group_id`, and re-organization cannot happen without breaking status quo.
> Instead, obsolete activities within a group are archived (setting their `archive_version_id`), and modified versions get added to new activity groups.

```sql
OLD
| SURFLENTDATACOLL | SURFLEVREADGAUGE | 
| SURFLOTDATACOLL  | SURFLEVREADGAUGE |
-> archive gauge

NEW
| SURFLENTDATACOLL | SURFLEVREADGNSS |
| SURFLOTDATACOLL  | SURFLEVREADGNSS |
-> introduce gnss

OLD
| SURFLENTDATACOLL | SURFLENTSECC     |
| SURFLOTDATACOLL  | SURFLOTSECC      |
-> archive datacoll/secc

NEW
| SURFLENTDATACOLL | SURFLENTTURB |
| SURFLOTDATACOLL  | SURFLOTTURB  |
-> introduce turb

NEW
| SURFLOTDATACOLL | SURFFLOWVELOC |
-> introduce flowveloc

NEW
| SURFLENTSECC |  SURFLENTSECC  |
| SURFLOTSECC  |  SURFLOTSECC  |

```

Next steps: 
- set `archive_version_id` in one go
- find `activity_group_id` of datacoll's, and assign
- find `activity_group_id = max+i` for new groups
- find `activity_id max max+j` for new activities

> [!important] archiving of activities (in groups that remain active)
> ```sql
> UPDATE "metadata"."GroupedActivities"
> SET archive_version_id = (SELECT MAX(version_id) FROM "metadata"."Versions")
> -- SELECT * FROM "metadata"."GroupedActivities"
> WHERE FALSE
> OR ((activity_group = 'SURFLENTDATACOLL') AND (activity = 'SURFLEVREADGAUGE') )
> OR ((activity_group = 'SURFLOTDATACOLL' ) AND (activity = 'SURFLEVREADGAUGE') )
> OR ((activity_group = 'SURFLENTDATACOLL') AND (activity = 'SURFLENTSECC'    ) )
> OR ((activity_group = 'SURFLOTDATACOLL' ) AND (activity = 'SURFLOTSECC'     ) )
> ;
> ```


> [!important] inserting new activities, existing and novel groups
> ```sql
>INSERT INTO "metadata"."GroupedActivities"
>(activity_group, activity_group_id, activity, activity_id, activity_name, is_datacollection_method, is_field_activity, is_prep_activity, is_lab_activity, is_loceval_activity, is_gw_activity, is_surf_activity) VALUES 
>('SURFLENTDATACOLL', 32, 'SURFLENTTURB', 42, 'veldmetingen turbiditeit uitvoeren in stromende wateren (met Secchi-schijf en Snellerbuis)', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLENTDATACOLL', 32, 'SURFLEVREADGNSS', 43, 'waterstand bepalen met GNSS-ontvanger', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLOTDATACOLL', 35, 'SURFFLOWVELOC', 44, 'stroomsnelheid bepalen met stroomsnelheidsmeter', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLOTDATACOLL', 35, 'SURFLOTTURB', 42, 'veldmetingen turbiditeit uitvoeren in stromende wateren (met Secchi-schijf en Snellerbuis)', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLOTDATACOLL', 35, 'SURFLEVREADGNSS', 43, 'waterstand bepalen met GNSS-ontvanger', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLENTSECC', 39, 'SURFLENTSECC', 33, 'Secchi-diepte bepalen in stilstaande wateren', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE), 
>('SURFLOTSECC', 40, 'SURFLOTSECC', 39, 'Secchi-diepte bepalen in stromende wateren', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE)
>;
> ```

### check the #freeze 
... yet in this case, changes should have no effect

### prevent duplicates
[[checks/duplicate activity ids in GroupedActivities|duplicate activity ids in GroupedActivities]]

## update `fag_is_auxiliary`, `fag_is_preponable`, and `protocol_id`'s

postponed: not critical for REP update
cf. `fa_protocol` in the #REP #RData for protocol_id
I could not find "auxiliary" and "preponable" in the general rush of things.

# Protocols

... postponed (overhaul required anyways)

# SampleUnits
+ In #SampleUnits, the field `schemes_served_all` (and potentially `scheme_ps_targetpanels`) must be consolidated.

# FieldCalendars
+ no relevant changes in #locevaldb 
+ on #mnmgwdb, there are 291 #startdateupdates which are all (waiting) aquatic types

