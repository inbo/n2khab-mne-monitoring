---
aliases:
  - daily maintenance scripts
tags:
  - maintenance
---
*(assembly of scripts which keep the databases in sync and order.)*

> [!note] YAD menu
> Try `101_all_maintenence_menu.sh` - a [yad](https://github.com/v1cont/yad) script to launch the different tasks.
*(edit 06/2026: YAD script on hold due to extra safety prompt for work on production; currently, I am using `Rscript <file.R> -staging` for a test, and then `R --silent --no-save --no-restore` >> `source("<file.R>")` for application on production.)*

```
102_re_link_foreign_keys.R
110_sync_FreeFieldNotes.R
111_distribute_loceval_via_mnmsyncdb.R
112_fill_location_journals.R
113_update_facalendar.R
114_replaced_LocationCells.R
115_sync_LocationInfos.R
116_update_wgs84_coordinates.R
117loceval_mhq_areas.R
117mnmgwdb_mhq_areas.R
117surfdb_mhq_areas.R
118_random_placementpoints_mnmgwdb.R
119_random_elevationpoints_mnmgwdb.R
```

tested on `-staging` prior to application (usually)