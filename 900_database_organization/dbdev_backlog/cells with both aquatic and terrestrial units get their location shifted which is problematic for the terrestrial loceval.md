---
aliases:
tags:
started:
finished:
execution:
status: false
priority:
---

## Problem Description / Observations
[[timeline/2026-10-08|2026-10-08]]
GRTS-address 144561 was drawn for a terrestrial and aquatic type (`2190_mp` and `2190_a`, respectively).

According to procedure for the *aquatic* #Locations, the location geometry was adjusted to a `point_on_surface`.
[[memos/locations of non-cell-based types should not be represented by a GRTS cell center|locations of non-cell-based types should not be represented by a GRTS cell center]]

For this particular cell, the polygon might not be up to date, which is not on us to judge:
![[attachments/dual_unit_aquatic_and_terrestrial_20261008113930.webp]]

While this might work for the aquatic type #loceval, the position is off for LOCEVALTERR and there is no way to retrieve the original cell center.

This probably concerns just a few corner cases; it might even be wrong (the cell center is in an aquatic polygon; doubtful whether we want to exclude this from the sampling frame based on prior watersurface information).


## Solution Outline (suggestion)

On the location shifting procedure during REP update, consider identifying those which are drawn for terrestrial and aquatic types and
	a) prohibit shifting or
	b) leave a `FreeFieldNote` flag for the original cell center

Scripts affected:
+ `510_loceval_update_REP.qmd`
+ `710_mnmsurfdb_update_REP.qmd`