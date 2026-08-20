---
aliases:
  - SAMPLPOINT TargetPoints are represented twice in locevaldb
tags:
  - TargetPoints
  - SamplingPoints
  - SAMPLPOINT
  - locevaldb
started:
finished:
execution:
status: false
---

SAMPLPOINT activities come from the REP and are correctly uploaded to #OtherVisits, because currently there is no special activities table.
As all REP activities, they are linked to the GRTS address, and thus to a raster cell location.

However, the purpose of this activity is to preselect a point for #mnmsurfdb sampling of water for chemical analysis.

Task: find a way to serve both geometries: a reference point (GRTS), and a sampling location.
Subtask: upon transfer to #mnmsurfdb, move the point to the right location so that they only see the sampling point where there is one.