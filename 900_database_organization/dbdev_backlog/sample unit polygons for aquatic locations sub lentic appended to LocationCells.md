---
aliases:
tags:
  - AquaticTypesVisits
  - locevaldb
  - LocationCells
started: 2026-07-08
finished:
execution:
status: false
---


+ add a `is_cell` field to distinguish cell-based types
```sql
BEGIN;
ALTER TABLE "metadata"."LocationCells" ADD COLUMN is_cell boolean DEFAULT TRUE; 
COMMENT ON COLUMN "metadata"."LocationCells".is_cell IS E'flag those polygons which are just cells';

-- <<< also update `SampleCells` view !

COMMIT;
```

+ ... and then REMOVE IT AGAIN
```sql
BEGIN;
ALTER TABLE "metadata"."LocationCells" DROP COLUMN is_cell CASCADE;

-- <<< also update `SampleCells` view !

COMMIT;
```

+ add the `polygon_id` to #SampleUnitPolygons
```sql
ALTER TABLE "outbound"."SampleUnitPolygons" ADD COLUMN polygon_id varchar(10); 
COMMENT ON COLUMN "outbound"."SampleUnitPolygons".polygon_id IS E'identifier - link to zenodo data sources';

--- ALTER TABLE "outbound"."SampleUnitPolygons" ALTER COLUMN polygon_id TYPE varchar(10); 
```

+ addendum to `510_loceval_update_REP.qmd`?

> [!issue] there are no aquatic types
> Seems no aquatic #SampleUnits are in the database by now.
> There should be.
> Confusion...
> ...
> Solution: they were uploaded as `stratum` instead of `type`


```sql
SELECT DISTINCT type FROM "outbound"."SampleUnits" ORDER BY type ASC;
```

... this should be solved by an `UPDATE... FROM` with #N2kHabStrata
just check for #SampleUnits uniqueness.
```sql
SELECT 
  CASE WHEN stratum IS NULL THEN type ELSE stratum END AS stratum, 
  type 
FROM "metadata"."N2kHabTypes" AS T
LEFT JOIN "metadata"."N2kHabStrata" AS S
  ON T.n2khabtype_id = S.n2khabtype_id
WHERE NOT (stratum = type)
;
```