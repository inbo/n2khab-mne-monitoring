---
aliases:
tags:
  - loceval
  - FieldCalendars
started:
finished:
execution:
status: false
---

chat / #WD on [[timeline/2026-06-24|2026-06-24]]
due to GRTS reset, locevals are visible on places previously visited
added a filter to View `loceval_Fieldwork.sql`:
`  AND ((FAC.no_visit_planned IS NULL) OR NOT (FAC.done_planning AND FAC.no_visit_planned)) `
