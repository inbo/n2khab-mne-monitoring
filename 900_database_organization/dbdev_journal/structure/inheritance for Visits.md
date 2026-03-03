---
aliases:
  - visits_inheritance
tags:
  - inheritance
  - visits
started: 2026-01-29
finished: 2026-03-02
status: true
execution:
  - "#FM"
---

# Result
`inbound.Visits` are now a base class for multiple special types of field activities, namely
- `InstallationVisits`
- `SamplingVisits`
- `PositioningVisits`

There is a #tutorial:
- <https://github.com/inbo/tutorials/pull/371>

# Issues
- #R / `dbplyr` cannot handle the `ONLY` relevant keyword
- maintenance scripts needed to be overhauled
	- particular attention for script `111a_push_loceval_to_mnmgwdb.R` (was: #python)
	- logical change: [[procedures/local replacements|local replacements]] now work by `UPDATE` of the `grts_address` in Calendar tables (previously: duplicate/delete)