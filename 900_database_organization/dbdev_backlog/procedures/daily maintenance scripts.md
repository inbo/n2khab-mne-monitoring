---
aliases:
  - daily maintenance scripts
tags:
  - maintenance
---
*(assembly of scripts which keep the databases in sync and order.)*

> [!note] YAD menu
> Try `101_all_maintenence_menu.sh` - a [yad](https://github.com/v1cont/yad) script to launch the different tasks.


```
103_count_dbcontent.R
110_sync_FreeFieldNotes.R
111_push_loceval_to_mnmgwdb.R
112_fill_location_journals.R
113_update_facalendar.R
114_replaced_LocationCells.R
115_sync_LocationInfos.R
116_update_wgs84_coordinates.R
117loceval_mhq_areas.R
117mnmgwdb_mhq_areas.R
118_random_elevationpoints_mnmgwdb.R
118_random_placementpoints_mnmgwdb.R
```

tested on `-staging` prior to application (usually)