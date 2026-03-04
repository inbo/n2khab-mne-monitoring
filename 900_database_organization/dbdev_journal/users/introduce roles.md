---
aliases:
tags:
  - roles
  - users
started: 2026-03-04
finished:
execution:
  - "#FM"
status: false
---

*cf.* <https://www.postgresql.org/docs/current/database-roles.html>

- [x] inception [[timeline/2026-03-04|2026-03-04]]

- [x] define and CREATE ROLEs 
```sql
CREATE ROLE tester_mnmdb;
CREATE ROLE viewer_mnmdb;
CREATE ROLE reporter_mnmdb;
GRANT viewer_mnmdb TO reporter_mnmdb;
CREATE ROLE user_loceval;
GRANT viewer_mnmdb TO user_loceval;
CREATE ROLE planner_loceval;
GRANT user_loceval TO planner_loceval;
CREATE ROLE user_gwdb;
GRANT viewer_mnmdb TO user_gwdb;
CREATE ROLE planner_gwdb;
GRANT user_gwdb TO planner_gwdb;
```
- [ ] reflect this in the [[locations/structure sheets]]
	- [x] `mnmgwdb`
	- [ ] `locevaldb`
- [x] assign existing users to roles (they keep direct permissions for the moment)
- [x] give the roles the correct database permissions
	- [x] ... after python update
	- [x] by script-deploying `dev` to dump: `python 601_init_mnmgwdb.py > dump.txt`
	- [x] `cat dump.txt | grep 'GRANT' | grep -v "test*"`
	- [x] paste to sql shell
- [x] create new users and assign them only via roles
	- [x] `postgres` user: create with password
	- [x] adjust [[locations/pg_hba|pg_hba]] -> add new users
