---
aliases:
tags:
  - Replacements
  - LocationInfos
started: 2026-05-21
finished:
execution:
status: false
---

- `recovery_hints` capture notes on how to find back the marking which loceval leave on a sample unit reference point (usualy cell center).
- Oddly, those were chosen to be associated with #Locations, and even more persistently became part of #LocationInfos.
- However, #LocationInfos are agnostic to replacement: they relate to a specific point in space, a location where we went for some reason.
- For efficiency reasons, #Replacements locations are not added to #Locations and #LocationInfos.
- However, if a local replacement happens, the info on `recovery_hints` refers to a marking in the *new* cel, i.e. after replacement. Falsely, the views and qgis projects associate them with the original target cell.

As a quick workaround, I added a new field: `replacement_recovery_notes` / "terugvindhulp (vervangcel)". 
This one is linked to #Visits, which is only slightly less incorrect.


A nice solution would be to have a #storedprocedure to create a new entry in #Locations and #LocationInfos whenever a replacement grts is chosen.