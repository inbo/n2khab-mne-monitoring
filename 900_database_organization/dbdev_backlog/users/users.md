---
aliases:
  - authentication
  - permissions
  - roles
tags:
  - users
  - roles
  - authentication
  - permissions
---
In this folder, tasks regarding user management (e.g. authentication, permissions, ...) are collected.


# Tricks

overview of all user roles ([ref](https://stackoverflow.com/a/22319589)):
```
WITH RECURSIVE x AS
(
  SELECT member::regrole,
         roleid::regrole AS role,
         member::regrole || ' -> ' || roleid::regrole AS path
  FROM pg_auth_members AS m
  WHERE roleid > 16384
  UNION ALL
  SELECT x.member::regrole,
         m.roleid::regrole,
         x.path || ' -> ' || m.roleid::regrole
 FROM pg_auth_members AS m
    JOIN x ON m.member = x.role
)
SELECT member, role, path
FROM x
ORDER BY member::text, role::text
;
```