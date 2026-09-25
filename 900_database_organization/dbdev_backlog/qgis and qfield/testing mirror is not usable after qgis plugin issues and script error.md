---
aliases:
  - revive QGIS testing project for testing mnmsurfdb
tags:
  - testing
  - mirrors
  - qgis
started: 2026-05-21
finished: 2026-06-16
execution:
  - FM
status: true
---

I cannot re-establish the #locevaldb #testing mirror, neither for other databases #mnmsurfdb.
+ QField plugin `ChangeDataSource` is outdated/obsolete? -> [contributed](https://github.com/enricofer/changeDataSource/issues/23), awaiting update
+ `933_populate_testing_db.R` throws errors -> fixed [[timeline/2026-06-16|2026-06-16]]
+ copied the master qgis project, changing its connection to `-testing`