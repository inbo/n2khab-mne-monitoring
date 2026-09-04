---
aliases:
  - random points with empty geometries
tags:
  - bug
  - mnmgwdb
  - randompoints
started: 2026-03-10
finished: 2026-03-10
execution:
  - "#FM"
status: true
---
Observation: some locations received too few random elevation points.
The reason was a bug in `118_random_elevationpoints_mnmgwdb.R` and
`118_random_placementpoints_mnmgwdb.R`:

```R
  if (nrow(points_in_habitat) > n_points) {
    # the sf[1:n, ] syntax will generate `empty` geometries if n<m
      points_in_habitat <- points_in_habitat[seq_len(n_points), ]
  }

```

However, my loop was clumsy and would continue if all points were empty (which happens if there is no cellmap yet for a location);
added pre-cautious check for `length()` of the `cellmaps_sf`|`location_id` subset.