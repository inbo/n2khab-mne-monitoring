---
aliases:
tags:
  - matchingoccasions
  - locevaldb
started:
finished:
execution:
status: false
---

New concept: "matching occasions" were introduced during [[data update/20260703 REP update 0.17.0 and SNIP update 0.17.0|REP 0.17.0]] 
As a text string grouping field which "links" future locevals that can be preponed by linking it to the earlier visit at the same side.

I forward that text string to #locevaldb, but otherwise do nothing with it.
It is a bit vague to handle these. 
I might introduce a `date_preponed` which, when present, overrides `date_start`, to display the preponed #Visits on the earlier date.