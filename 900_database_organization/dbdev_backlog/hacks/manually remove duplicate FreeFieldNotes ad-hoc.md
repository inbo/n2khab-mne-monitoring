---
aliases:
  - ad-hoc FreeFieldNotes removal
tags:
  - FreeFieldNotes
  - duplicates
  - log_creation
  - logging
---

(It seems that mobile endpoints occasionally send duplicates of a given new entry.)

```sql
DELETE FROM "inbound"."FreeFieldNotes" 
WHERE fieldnote_id IN ( 
  SELECT DISTINCT fieldnote_id 
  FROM "inbound"."FreeFieldNotes" 
  WHERE log_creator = '<creator>' 
  AND note_date = '2026-xx-xx' 
  AND log_creation = '2026-xx-xx 11:11:11.xxx' 
  ORDER BY fieldnote_id DESC LIMIT 0 -- this limit must be N - 1 
);
-- DELETE 2
```