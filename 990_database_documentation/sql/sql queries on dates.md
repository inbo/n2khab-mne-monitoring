
https://www.postgresql.org/docs/current/functions-datetime.html

trunc datetime/timestamp
```sql
SELECT fieldnote_id, DATE_TRUNC('millisecond', log_creation) AS log_creation
FROM "inbound"."FreeFieldNotes";
```

extract milliseconds timestamps
```sql
SELECT fieldnote_id, log_creation, EXTRACT(milliseconds FROM log_creation) FROM "inbound"."FreeFieldNotes";
```