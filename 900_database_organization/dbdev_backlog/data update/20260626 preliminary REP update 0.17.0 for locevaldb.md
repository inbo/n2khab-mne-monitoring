---
aliases:
  - loceval guerilla data update prior to 0.17
tags:
started: 2026-06-26
finished:
execution:
  - FM
status: false
---

+ [x] download new RData and checksums
+ [x] merge `snippets_activate_surf`
+ [x] meld `401_snippet_selection.R`
+ [x] sync `-staging`
+ [x] insert a new version id
+ [x] update #GroupedActivities  from [[data update/20260619 REP preview 0.17.0|REP 0.17.0]]
+ [x] update structure sheets for all mirrors


some checksums differed, but I will double check what changes come to the calendar

|name                                                  |xxh64sum_ref     |xxh64sum_current |
|:-----------------------------------------------------|:----------------|:----------------|
|fieldwork_shortterm_dates_prioritization_count        |77be40d46a39d2da |f6e8ab0d28e6c79c |
|fieldwork_shortterm_targetpanels_prioritization_count |73a2e22583b0d54e |44288a99f14e9961 |
|units_7220                                            |e82a3b800dd18d9b |1f6b0b5bad0ab505 |
|versions_required                                     |c8b9e14d0b262517 |a9be49d6c313ed6f |


+ [x] test on `-staging`
+ [x] backup
+ [x] apply to #production
+ [x] check fieldwork view to let through LOCEVALAQ
+ [x] QGIS project update and upload
