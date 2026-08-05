---
aliases:
  - GRTS
  - grts_address
  - generalized random tessellation stratified sampling
  - spatially balanced sampling
tags:
  - grts
  - spatiallybalanced
---
GRTS stands for "generalized random tessellation stratified" sampling of locations, a method for generating spatially balanced sets of [[glossary/sample unit|sample units]].
During the GRTS procedure, 2D areas are assigned into quadratic polygons of a given size, and addressed by quarternary address system.
The random tesselation procedure generates series of addresses which, when sampled in consecutive order, are spatially balanced.
In our database, the field `grts_address` is common to many tables, as it is a logical and basic [[glossary/characteristic columns|characteristic column]].

Attention must be paid on the contextual details of the use of the GRTS:
+ In the #REP, there is the original GRTS address as it was sampled from the sampling frame.
+ However, in the case of a [[procedures/local replacement|local replacement]], a different GRTS cell co-located in the same [[glossary/habitat type and stratum|habitat]] polygon will be a stand-in replacement of the original address (which sometimes is referred as `grts_original`). The replacement itself is then stored as `grts_address_final`, although it might be replaced again (would still be connected back to the original original).
+ However, in the [[database/database|databases]], only the `grts_address_final` matters and therefore the suffix `_final` is dropped; the `grts_address` from the databases is thus matching the `grts_address_final` from the REP.