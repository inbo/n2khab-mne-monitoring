alias:: authentication
tags:: logins, roles, users

- # login
- ## terminal
- via linux terminal:
  ```
  psql -U <readonly_user> -h <host> -p <port> -d mnmgwdb -W
  ```
- tools like `pgAdmin` (not tested) or `pgModeler` could be used with those same credentials
- ## on passwords
- We favor complicated, high-entropy passwords. Nevertheless, there is an allocation between authentication security (having a strong password) and login convenience (having to type it over and over again).
  There are three options to enable "auto-login" / "passwordless" auth:
	- The **preferred option** is to use the password prompts built in to [the custom R MNM database connection]([[usage/R/MNMDatabaseConnection]]).
	  This works out-of-the-box, and facilitates login via R's `keyring` package (cf. [tutorial](https://github.com/inbo/tutorials/pull/365)).
	- For [[usage/R]] and [[usage/python]]: better use a [[usage/connection config file]]. Though storage of a password is possible, better don't store plain-text passwords here for users with write access. A good option is to store your config file in an encrypted container file (e.g. [[software/tomb]]) and mount it for interaction.
	- Via postgres: [create a `~/.pgpass` file](https://www.postgresql.org/docs/current/libpq-pgpass.html). Better don't use this for users with write access; it is plain text.
- # roles
- `<db_superuser>`: superuser on `_dev` and `_testing`
- `<db_admin>`: superuser on production
  :LOGBOOK:
  CLOCK: [2025-11-04 Tue 12:33:24]--[2025-11-04 Tue 12:33:26] =>  00:00:02
  CLOCK: [2025-11-04 Tue 12:33:26]
  :END:
- `<readonly_user>`: read-only user, used for database sync, certain views, ad-hoc queries to avoid breaking things
- # user management
- ssh to server
- su - root
- su - postgres
- `createuser --interactive --port <port>`
  ```
  psql <database> --port <port>
  ALTER USER <user> WITH ENCRYPTED PASSWORD '<password>';
  ```
- analogously, `deleteuser <user>`
- ## Permissions
- ... must be granted and revoked by the database admin, like so:
  ```sql
  GRANT SELECT ON "outbound"."MHQSafety" TO tester;
  REVOKE ALL PRIVILEGES ON "outbound"."MHQSafety" FROM tester;
  ```
- ## Troubleshooting
- If a user *cannot logon* to the database (e.g. via [QField]([[usage/qfield]])), there are the following levels of login prevention to be considered faulty:
	- `pg_hba.conf` file (*cf.* [[server/postgresql]] ) restricts login, e.g. by preventing unknown IPs
		- this throws a quite instructive error message, mentioning `pg_hba`
		- -> [ssh]([[server/ssh]]) to server, go `root`, and manually configure `/var/lib/postgres/data/pg_hba.conf`
	- database login: the role must have permissions on the database
		- usually throws an error after login, or just does not return the expected data
		- -> login as `admin` db user and check table permissions:
			- `\dn+`  -> list schema's and access rights
			- `\z "schema"."Tables"` lists table access rights
			- find all tables to which a user has access:
				- ```sql
				  SELECT * FROM information_schema.role_table_grants
				   WHERE grantee = '<user>';
				  ```
	- QGIS/QField login: data is in the database, but not visible in [QGIS]([[usage/qgis]])
		- verify with a manual SELECT whether data really exists
		- -> double check map layer connections via `changeDataSource` plugin
		- -> check auth configuration via `Layer` >> `Data Source Manager` >> `PostgreSQL` >> edit connections