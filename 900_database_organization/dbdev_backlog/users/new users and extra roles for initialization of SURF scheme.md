---
aliases:
tags:
  - userroles
  - mnmsurfdb
started: 2026-06-30
finished: 2026-06-30
execution:
  - FM
status: true
---

via user `postgres` on database #mnmsurfdb 

```sql
CREATE USER <username> WITH ENCRYPTED PASSWORD '***';
```

as database admin:

```sql
GRANT user_surfdb TO <users>;
```

add them to `data_TeamMembers.csv` and thereby to #TeamMembers
-> via INSERT column spreadsheet concatenation