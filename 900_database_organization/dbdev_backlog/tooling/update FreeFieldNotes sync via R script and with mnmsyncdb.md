---
aliases:
  - migrate 110_sync_FreeFieldNotes from Python to R
  - sync FreeFieldNotes against the mnmsyncdb
tags:
  - FreeFieldNotes
  - mnmsyncdb
  - python
started: 2026-05-19
finished: 2026-06-08
execution:
  - FM
status: true
---

new script started for this: `119_sync_FreeFieldNotes.R`

+ decided to add an archive column to keep removed entries:
```sql
ALTER TABLE "inbound"."FreeFieldNotes" ADD COLUMN archive_date int; 
COMMENT ON COLUMN "inbound"."FreeFieldNotes".archive_date IS E'the day (YYYYMMDD) when this note was removed';

```
+ only reliable identifier columns are `log_creator` and `log_creation`; all the others might be skipped/changed by user (even the #geometry can be changed by moving the point)

## intermediate issues
+ [x] log_creation is a `datetime`/`dplyr::dttm` and apparently subject to fluctuation or internal rounding for trailing digits; it must be rounded to seconds for reliable filtering joins -> converted all timestamps in this table to `timestamp(3)`
+ [x] `teammember_id` does not match! (depends on origin db)
	+ [x] created  the table on `mnmsyncdb` and filled with data
	+ SELECT * FROM "metadata"."TeamMembers";
	 + [x] `INSERT INTO "metadata"."TeamMembers" (username, notes) VALUES ('all_surfers', 'plaatshouder voor veldploeg oppervlaktewatermeetnet')`
	+ [x] adjusted script `110` to convert teammember_id's
	```sql
    SELECT fieldnote_id, FFN.teammember_id, TM.username
    FROM "inbound"."FreeFieldNotes" FFN
	LEFT JOIN "metadata"."TeamMembers" AS TM
	  ON FFN.teammember_id = TM.teammember_id
    WHERE TM.teammember_id IS NOT NULL;	
	```