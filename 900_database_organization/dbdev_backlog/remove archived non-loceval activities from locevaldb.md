---
aliases:
tags:
  - archive
  - loceval
started:
finished:
execution:
  - FM
status: false
---
In the early days of the #locevaldb , #FM did not distinguish activities, let alone filter for the relevant ones.
Later, those non-target activities were moved to archive #weneverdeleteanything .
with the [[structure/implement freezing and sideloading historic data|freeze]] and subsequent [[data update/20260313 REP update 0.15.0|REP 0.15.0 update]], it became clear that those activities are still present in the database.
They can be ignored for now; however, at some point, they may be deleted after careful inspection.
(Make sure that Ward never installed wells on his database.)