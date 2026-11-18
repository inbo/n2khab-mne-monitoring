---
aliases:
  - revisit and extend checks
tags:
  - checks
started:
finished:
execution:
status: false
priority:
---

There are multiple levels and ways of checking / constraining field form filling.

- in postgreSQL, via `CONSTRAINT` in tables or views
- in QGIS *ex ante*, via field form constraints
- in QGIS *ex post*, via visual indications on the map

Interaction between QGIS or QField and postgreSQL is crucial: if an unhandled postgreSQL constraint error suspends an open field form in mid-air, data might be lost and users disgruntled.

More thoughts:
- If I remember correctly, QGIS does throw an error on the main window but leaves the form popup open. 
- QGIS constraints might be inconvenient to maintain.
- It is not guaranteed that all that works in QGIS will also work in QField -> testing required.
- Are there "incomplete state" use cases where users fill a form and finish up later?

-> to be evaluated


Initial idea via #DDG / chat discussion [[timeline/2026-11-18|2026-11-18]].


## checks in place
- #VisitIncompleteCheck: [[checks/VisitIncompleteCheck - view and map layer to indicate Visits with missing information|VisitIncompleteCheck - view and map layer to indicate Visits with missing information]] 
- #UnplannedVisitCheck: [[checks/why are there Visits which were marked as visit_done but never planned|why are there Visits which were marked as visit_done but never planned]]