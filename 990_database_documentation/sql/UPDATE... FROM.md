---
aliases:
  - UPDATE FROM
tags:
  - sql
  - update
---
Update one table with data from another.

*example usage:*
```sql
UPDATE "outbound"."FieldworkCalendar" AS TRGTAB
  SET
   date_interval = SRCTAB.date_interval
  FROM temp_upd_fieldworkcalendar AS SRCTAB
  WHERE
   (TRGTAB.date_start = SRCTAB.date_start) AND (TRGTAB.date_end = SRCTAB.date_end)
;

```

See also: [[sql/temporary tables|temporary tables]]