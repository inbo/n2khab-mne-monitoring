---
aliases:
tags:
  - ReplacementOngoing
  - views
  - Visits
started:
finished:
execution:
status: false
priority:
---

Filling fields which are supposed to link back to the #Visits while performing a #localreplacement via the #locevaldb #ReplacementOngoing #view will lead to multiple visits being filled.
The reason is that `replacement_ongoing` is stored on the level of #SampleUnits; it thereby links back to all planned Visits.

- check whether multiple features appear in the "replacement" map layer
- design a way to also mark a specific visit/occasion as `replacement_ongoing`, e.g. by trivially adding a field, or by moving the field from SampleUnits to Visits
- But also: make sure to unset that field in #Visits once the visit is done.
- Handle situations where none of the visits has ongoing replacement.