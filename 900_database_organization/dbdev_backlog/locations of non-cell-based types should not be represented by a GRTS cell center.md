---
aliases:
tags:
  - Locations
  - GRTS
  - aquatictypes
  - geometries
  - REP
started: 2026-07-09
finished:
execution:
status: false
---

In the `X10_*_update_REP.qmd` refreshment procedures, I determine the location of sample units by the simple function `add_point_coords_grts`.
This links the table entry to a point coordinate via its GRTS.
For terrestrial, cell-based types, this is accurate: we want to use the cell center as a reference.


However, for aquatic, polygon-based sample units, the cell center of the related GRTS address is misleading.
+ Technically, aquatic units get a GRTS, 
+ yet the center of that cell might be out of water
+ and one GRTS cell might contain multiple smaller water bodies
+ in which case a pseudo-GRTS address was used by a sophisticated patching algorithm (such as upsampling GRTS level)

> [!important] primary geometry
> For the non-cell-based types, the **polygon** is the relevant/primary unit geometry.


Issue is that at the moment I do not dare to mix geometries. 
Geometry collections work in R / `sf`; they might be fine in postGIS; but on the user end (QGIS, QField) a geometry type is linked to the manner of visualization and to layer style.
To avoid potentially apocalyptic complication, I will rather abstract polygons to points ( #FV mentioned [`st_point_on_surface`](https://r-spatial.github.io/sf/reference/geos_unary.html)).


# Strategy and Execution

+ correct the point geometry of aquatic locations upon upload
+ introduce an `is_cell_center` flag on #Locations to easily distinguish
```sql
ALTER TABLE "metadata"."Locations" ADD COLUMN is_cell_center boolean NOT NULL DEFAULT TRUE; 
COMMENT ON COLUMN "metadata"."Locations".is_cell_center IS E'indicate wether this location points to the grts cell center';
```
+ add #SampleUnitPolygons to #mnmsurfdb
	+ (with extra polygon_id)
+ hopefully all views with `LOC.*` will continue to work
	+ `116_update_wgs84_coordinates.R` corrected
+ has to apply to all databases


+ [x] #locevaldb [[timeline/2026-07-10|2026-07-10]] 13:56
+ [x] #mnmsurfdb [[timeline/2026-07-10|2026-07-10]] 14:19
+ [ ] #mnmgwdb  NOT executed because for installation they might require the cell center anyways

ALTER TABLE "outbound"."SampleUnitPolygons" ALTER COLUMN polygon_id TYPE varchar(16);