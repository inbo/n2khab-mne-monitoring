---
aliases:
tags:
  - FreeFieldNotes
  - log_creation
  - timestamps
started: 2026-06-02
finished: 2026-06-02
execution:
  - FM
status: true
---

in the context of [[draft and implement mnmsyncdb a database for synchronization of interchange data|draft mnmsyncdb]]
it turned out that computer accuracy for timestamps is limited
and it makes sense to round off the creation timestamps to milliseconds.

As of [[timeline/2026-06-02|2026-06-02]], this is only applied to the #FreeFieldNotes , other timestamps remain "exact".

```sql
ALTER TABLE "inbound"."FreeFieldNotes" ALTER COLUMN log_creation SET DEFAULT current_timestamp(3); 
UPDATE "inbound"."FreeFieldNotes" AS TRGTAB
  SET log_creation = SRCTAB.log_creation
FROM (
  SELECT fieldnote_id, DATE_TRUNC('millisecond', log_creation) AS log_creation
  FROM "inbound"."FreeFieldNotes" 
) AS SRCTAB WHERE SRCTAB.fieldnote_id = TRGTAB.fieldnote_id
;
```

However, I forgot to alter the data type on the first round.
```sql
ALTER TABLE "inbound"."FreeFieldNotes"
ALTER COLUMN log_creation
TYPE timestamp(3) USING (DATE_TRUNC('millisecond', log_creation));
```

For double-checking:
```sql
SELECT fieldnote_id, log_creation, EXTRACT(milliseconds FROM log_creation) 
FROM "inbound"."FreeFieldNotes" 
WHERE fieldnote_id < 10 
ORDER BY fieldnote_id ASC
;
```

... applied the same to `log_update`