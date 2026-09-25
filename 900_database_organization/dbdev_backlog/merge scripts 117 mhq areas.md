---
aliases:
tags:
started:
finished:
execution:
status: false
---

prerequisite: [[consistent table and field names across databases]] for #mnmgwdb

- `117loceval_mhq_areas.R`
- `117mnmgwdb_mhq_areas.R`
- `117surfdb_mhq_areas.R`
These are three separate files for a relatively simple script which updates #MHQPolygons; those can be merged.
They contain a single function, which is easily parametrized to serve all databases (but only after mnmgwdb names have been brought to line).