---
aliases:
tags:
  - FreeFieldNotes
  - QGIS
  - symbology
started:
finished:
execution:
status: false
priority: 7
---

[[timeline/2026-10-27|2026-10-27]] an `svg` symbol, embedded, gave the map layer for #RequireTotalStation a beautiful look.
However, newly added features (which came in server-side) did not get that symbol; instead, they just got an empty, invisible placeholder icon.
This was temporarily rectified by setting a default symbol on the map layer.


However, for #FreeFieldNotes, the same might happen. Worst case: it might happen without us being aware.

-> double check that novel fieldnotes with the non-standard symbol are displayed correctly.