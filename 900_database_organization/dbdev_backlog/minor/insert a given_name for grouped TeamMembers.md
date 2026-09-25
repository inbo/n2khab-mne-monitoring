---
aliases:
tags:
  - TeamMembers
started: 2026-06-18
finished: 2026-06-18
execution:
  - FM
status: true
---

In the locevaldb project, value relation was set to `given_name` instead of `username`
which is nice because names are capitalized
however, group users are indifferent blanks then


```sql
UPDATE "metadata"."TeamMembers"
SET given_name = LOWER(username)
WHERE username LIKE 'all_%';
```

