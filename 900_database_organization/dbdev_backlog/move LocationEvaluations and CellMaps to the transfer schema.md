---
aliases:
tags:
  - LocationEvaluations
  - CellMaps
started:
finished:
execution:
status: false
---

with [[distribute loceval information via mnmsyncdb]], the `transfer` schema was introduced
the other #loceval  information would also fit there

## plan
> [!note] it is that simple...
> I can just `ALTER TABLE "outbound"."LocationEvaluations" SET SCHEMA "transfer"; ` 

```sql
ALTER TABLE "outbound"."LocationEvaluations" SET SCHEMA "transfer"; 
ALTER TABLE "outbound"."CellMaps" SET SCHEMA "transfer"; 
```
Just make sure to adjust the views, RScripts and QGIS layers in one go
and temporarily create a view with the same name which just redirects SELECTs to catch QField queries


## obsolete
strategy: in one go...
- create an identical twin on the new schema
- copy over the data
- (optional: set temporary update redirection rule)
- adjust views
- compare data again
- disable redirection and delete old table

note that the redirection is cumbersome and not required for these particular tables

create documentation about this procedure for future reference
especially the temporary update redirection