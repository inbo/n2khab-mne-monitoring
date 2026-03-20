---
aliases:
  - remove emty entries from freeze
tags:
  - freeze
  - activities
started:
finished:
execution:
  - "#FM"
status: false
---

Follow-up of [[structure/implement freezing and sideloading historic data|implement freezing and sideloading historic data]].
I clumsily dumped *all* historic entries in `csv` files and tagged them as `is_frozen` on [[timeline/2026-03-19|2026-03-19]] with `405_freeze_calendar.R`.
At some point, outdated activities which never materialized should be removed, given there is no user-side data input.

This requires comparing the database status quo to default values set for empty entries, preserving any changes (potential synergy with [[dynamic implementation of precedence columns|remove precedence columns]]).