---
aliases:
tags:
  - mnmgwdb
  - rename
  - redirection
started:
finished:
execution:
status: false
priority:
---

*cf.* [[consistent table and field names across databases]]

+ `DROP VIEW IF EXISTS "outbound"."SampleLocations";`
+ remove alias column `strata` from `gw_FieldWork.sql` and `gw_FieldworkPlanning.sql`
+ `DROP VIEW IF EXISTS  "outbound"."FieldworkCalendar";`
+ `DROP VIEW IF EXISTS "outbound"."RandomPoints";`
+ `DROP VIEW IF EXISTS "outbound"."CellMaps";`
+ `DROP VIEW IF EXISTS "outbound"."LocationEvaluations";`


While at it, also check:
```
GeoObservations
TerraBioObservations
AquaBioObservations
LanduseObservations
```