---
aliases:
  - re-use `type_assessed` to save location evaluation on novel sample units
tags:
  - loceval
  - REP
  - dataupdate
  - Visits
  - SampleUnits
started:
finished:
execution:
status: false
priority:
---

Imagine the following case (`grts_address == 1012434`):
- A location is selected for two types and thus two #SampleUnits: e.g. `3130_aom` and `3140`. (In the present case, there was also an archived unit with `3130_na`, but that was not visible any more during fieldwork.)
- #loceval is executed, and the pond is assessed to be of a different type: `3130_na` (and negative for both intended types).
- On a later #REP update, a novel sample unit enters the sample for that same location, but with the previously positively assessed type.
	- This would not be too unlikely if we would update our sampling frame with prior loceval info.

>[!conclusion] 
> If there is not too much time between loceval and REP update, the positive prior assessment of the novel unit should be taken into consideration.
