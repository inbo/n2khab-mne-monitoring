---
aliases:
  - authentication
tags:
  - logins
  - roles
  - users
---

# login
## terminal
via linux terminal:
```
psql -U <readonly_user> -h <host> -p <port> -d mnmgwdb -W
```
tools like `pgAdmin` (not tested) or `pgModeler` could be used with those same credentials

## protections
some extra layers regulate login.
- the [[software/ufw|firewall]] might block access
- the [[server/postgresql|postgresql]] `pg_hba.conf` file must reflect user changes
- password must be correct (case-sensitive)

## on passwords
We favor complicated, high-entropy passwords. Nevertheless, there is an allocation between authentication security (having a strong password) and login convenience (having to type it over and over again).
There are three options to enable "auto-login" / "passwordless" auth:
- The **preferred option** is to use the password prompts built in to [[MNMDatabaseConnection|the custom R MNM database connection]].
	This works out-of-the-box, and facilitates login via R's `keyring` package (cf. [tutorial](https://tutorials.inbo.be/tutorials/r_keyring/)).
- For [[R/R]] and [[usage/python|python]]: better use a [[usage/connection config file|connection config file]]. Though storage of a password is possible, better don't store plain-text passwords here for users with write access. A good option is to store your config file in an encrypted container file (e.g. [[software/tomb|tomb]]) and mount it for interaction.
- Via postgres: [create a `~/.pgpass` file](https://www.postgresql.org/docs/current/libpq-pgpass.html). Better don't use this for users with write access; it is plain text.

# roles

*cf.* [[database/userroles|user roles]]

# user management
ssh to server
su - root
su - postgres
`createuser --interactive --port <port>`
```
psql <database> --port <port>
ALTER USER <user> WITH ENCRYPTED PASSWORD '<password>';
```
analogously, `deleteuser <user>`

## Permissions

- Are handled via [[database/userroles|userroles]] to specific tables/schemes.
- Must be granted and revoked by the database admin.

## Troubleshooting
If a user *cannot logon* to the database (e.g. via [[software/qfield|QField]], there are the following levels of login prevention to be considered faulty:
- `pg_hba.conf` file (*cf.* [[software/postgresql|postgresql]] ) restricts login, e.g. by preventing unknown IPs
	- this throws a quite instructive error message, mentioning `pg_hba`
	- -> [[server/ssh|ssh]] to server, go `root`, and manually configure `/var/lib/postgres/data/pg_hba.conf`
- database login: the role must have permissions on the database
	- usually throws an error after login, or just does not return the expected data
	- -> login as `admin` db user and check table permissions:
		- `\dn+`	-> list schema's and access rights
		- `\z "schema"."Tables"` lists table access rights
		- find all tables to which a user has access:
			- sql ↓
			```sql
				SELECT * FROM information_schema.role_table_grants
				WHERE grantee = '<user>';
		```
- QGIS/QField login: data is in the database, but not visible in [[software/qgis|QGIS]]
	- verify with a manual SELECT whether data really exists
	- -> double check map layer connections via `changeDataSource` plugin
	- -> check auth configuration via `Layer` >> `Data Source Manager` >> `PostgreSQL` >> edit connections
