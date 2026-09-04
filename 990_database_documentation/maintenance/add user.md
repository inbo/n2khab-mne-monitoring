---
tags:
  - example
  - sql
aliases:
  - create user
---
Below the necessary steps for creation of a new user.
## system-side
*on the [[server/ssh|server]]:*
(via `postgres` user)
+ create the user
```sql
CREATE USER <username> WITH ENCRYPTED PASSWORD '<password>';
```
+ add [[database/authentication|pg_hba]] entry

## via database
*on each [[database/database|database]]:*
+ grant [[database/userroles|user roles]]
```sql
GRANT viewer_mnmdb TO monkey;
```
+ fill `TeamMembers` table
```sql
INSERT INTO "metadata"."TeamMembers" (username, family_name, given_name) VALUES ('<User>', 'Lastname', 'Firstname');
```