---
aliases:
  - is_secret_place
tags:
  - LocationInfos
started:
finished:
execution:
status: false
priority:
---

fieldwork request to mark *non-secret* locations

update #LocationInfos of all four databases:
```sql
ALTER TABLE "outbound"."LocationInfos" ADD COLUMN is_secret_location boolean DEFAULT NULL; 
  COMMENT ON COLUMN "outbound"."LocationInfos".is_secret_location IS E'this location is not really secret, but the flag should remind you of something...';
```

+ update views; also in [[locations/structure sheets|structure sheets]]; re-download and extract structure sheets
+ update qgis; also export styles
+ (nothing to update in sync script `115_sync_LocationInfos.R`


one task done, two new arose:
+ [[loceval ReplacemenOngoing view should also update new LocationInfo fields]]
+ [[think of a way how LocationInfos can be updated during ReplacementOngoing via update rules]]
