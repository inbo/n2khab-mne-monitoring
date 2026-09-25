---
aliases:
tags:
  - AquaticTypesVisits
  - locevaldb
  - SampleUnitPolygons
started: 2026-07-08
finished: 2026-08-05
execution:
  - FM
status: true
---


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
> Reason: they were uploaded as `stratum` instead of `type` in the `type` column.

[[aquatic habitat types entered locevaldb as stratum instead of type and thereby created SampleUnits duplicates]]


## initial / erroneous attempt: add these to #LocationCells
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

## post hoc
*A month later, I forgot what the problem here was, but think it is related to the stratum/type confusion (linked above) -> case closed.*