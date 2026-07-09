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

For the non-cell-based types, the **polygon** is the relevant/primary unit geometry.


Issue is that at the moment I do not dare to mix geometries. 
Geometry collections work in R / `sf`; they might be fine in postGIS; but on the user end (QGIS, QField) a geometry type is linked to the manner of visualization and to layer style.
To avoid potentially apocalyptic complication, I will rather abstract polygons to points ( #FV mentioned [`st_point_on_surface`](https://r-spatial.github.io/sf/reference/geos_unary.html)).


# Strategy

+ correct the point geometry of aquatic locations upon upload
+ introduce an `is_cell_center` flag on #Locations to easily distinguish
+ has to apply to all databases