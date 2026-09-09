---
aliases:
tags:
  - CellMaps
  - rename
  - schema
started:
finished:
execution:
status: false
priority:
---

```sql
ALTER TABLE "outbound"."LocationEvaluations" SET SCHEMA "transfer";
ALTER TABLE "outbound"."CellMaps" SET SCHEMA "transfer";

-- 

```
- [ ] move all data from "inbound"."Visits" to "inbound"."OtherVisits"
	- check QGIS project

adjust views! (Fw, FwP, LocevalInfo, ...)

Check that (especially #CellMaps and #OtherVisits ) are well-linked in #QGIS 