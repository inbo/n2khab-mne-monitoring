---
aliases:
tags:
  - locevaldb
  - view
  - LocevalFieldwork
started: 2026-05-21
finished: 2026-05-21
execution:
  - FM
status: true
---

Observation: projects are cluttered, hard to tell for colleagues where to start with loceval.
Issue: #FieldCalendar and #Visits are separate, which does not reflect *their* workflow.

Solution: combined #view which holds info on planning and execution of activities.
Adjusted layer syle file.
Added some new requested columns.

```sql
CREATE OR REPLACE VIEW "inbound"."LocevalFieldwork" AS
[...]
```