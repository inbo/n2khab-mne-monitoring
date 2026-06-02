---
aliases:
tags:
  - FreeFieldNotes
  - log_creation
  - timestamps
started:
finished:
execution:
status: false
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