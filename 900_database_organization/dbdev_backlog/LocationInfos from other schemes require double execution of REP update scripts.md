---
aliases:
tags:
  - REP
  - update
  - LocationInfos
started:
finished:
execution:
status: false
---

Expectation:
+ after running a [[procedures/REP update|REP update]], all locations and activities should be covered by the database

Observation: 
+ after running the script,
+ then syncing #LocationInfos
+ and then running the script again
+ new locations will appear

those were locations from an entirely different scheme which only passed in via `LocationInfos`.
Solution: 
+ check execution order of the script
+ consider removing filter for `scheme`
+ workaround: run the script twice