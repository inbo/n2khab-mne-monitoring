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

> [!warning] Pseudo-Duplicates
> These duplicates can differ in geometry, so better not to remove them!
> If in doubt, check with the colleague who created the note.
> Consider slightly shuffling the time as an alternative.

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