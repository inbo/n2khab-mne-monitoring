---
aliases:
  - migrate 119_sync_FreeFieldNotes.R to Python
  - sync FreeFieldNotes against the mnmsyncdb
tags:
  - FreeFieldNotes
  - mnmsyncdb
  - python
started: 2026-05-19
finished:
execution:
  - FM
status: false
---

new script started for this: `119_sync_FreeFieldNotes.py`

+ decided to add an archive column to keep removed entries:
```sql
ALTER TABLE "inbound"."FreeFieldNotes" ADD COLUMN archive_date int; 
COMMENT ON COLUMN "inbound"."FreeFieldNotes".archive_date IS E'the day (YYYYMMDD) when this note was removed';

```
+ only reliable identifier columns are `log_creator` and `log_creation`; all the others might be skipped/changed by user (even the #geometry can be changed by moving the point)

+ ISSUE: log_creation is a `datetime`/`dplyr::dttm` and apparently subject to fluctuation or internal rounding for trailing digits; it must be rounded to seconds for reliable filtering joins.