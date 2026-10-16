---
aliases:
tags:
  - Replacements
  - SampleUnits
  - duplicates
started: 2026-10-16
execution:
  - FM
  - FV
  - WD
  - WT
---

## Situation: Two Locations, One Replacement Candidate
- Two sample units of the same type are to be replaced.
- There is only one suitable replacement candidate.

> [!important]
> The first target cell to be *visited* gets effectively replaced by the replacement candidate. "First come, first serve".

If visit timestamps in the database are quasi-identical, the unit with the lower GRTS-address gets the replacement. 
In contrast, the fields `priority` (activity) or the panel number of the unit may not decide which of the two to be replaced.

Note: this only applies for two units with the same type. Two units of different types (one cell-center based, the other not) can theoretically be replaced by the same local replacement cell.

## Example

|type | grts_address_original|loceval_date | grts_address_replacement| replacement_rank|
|:----|---------------------:|:------------|------------------------:|----------------:|
|7210 |                819174|2026-10-16   |                 21790694|                2|
|7210 |               5013478|2026-10-16   |                 21790694|                2|

Note: for location GRTS `5013478`, the replacement was undone and the disapproved unit thereby required global replacement.