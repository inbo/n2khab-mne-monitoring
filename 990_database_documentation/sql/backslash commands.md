"special" command shortcuts to explore database metadata
e.g.
- `\l`	-> list databases
- `\du`	-> list users
- `\dn+`	-> list schema's and access rights
- `\dt+`	-> list tables
- `\ds+`	-> list sequences
- `\z "schema"."Tables"` -> table information
- `\dp "schema"."Tables"` -> permissions
*cf.* <https://medium.com/@jramcloud1/postgresql-17-cheat-sheet-exploring-databases-with-psql-commands-ee3d74cfa5cc> for a more comprehensive overview.

## bonus

To recursively show [[database/userroles|userroles]], this function has proven useful ([ref.](https://www.cybertec-postgresql.com/en/postgresql-get-member-roles-and-permissions/#resolving-users-and-role-membership-in-postgresql)):
```sql
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
