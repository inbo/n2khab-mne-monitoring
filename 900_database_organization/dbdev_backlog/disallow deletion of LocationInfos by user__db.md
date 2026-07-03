---
aliases:
tags:
  - LocationInfos
  - userroles
started:
finished:
execution:
status: false
---

checked on #mnmsurfdb
```sql
SELECT * FROM information_schema.role_table_grants
  WHERE grantee = 'user_surfdb' AND privilege_type = 'DELETE';
```
