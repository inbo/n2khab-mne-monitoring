---
alias:
  - mnm_database_connection.conf
---

`.conf`/`.ini` file to store login credentials
to be accessed from within [[R/R]] or [[software/python]]

Recommended fields required per connection profile (blocks with `[profile_name]`) are:
- host
- port
- user
- database
- folder

All of these can alternatively be provided at runtime via the `connect_mnm_database` function.
A password may be provided either in the config file, or via `~/.pgpass` (in which case submit `password = NA` to suppress prompt), or at runtime.

## example `mnm_database_connection.conf`

```ini
	[dumpall]
	host = <host>
	port = <port>
	user = <readonly_user>
	# folder and database provided at runtime
	
	#### LOCEVAL ####
	
	### (4) production
	# This is the live environment with real data.
	# It is the least volatile, best backed-up of our database mirrors.
	[loceval]
	folder = loceval_db_structure
	host = <host>
	port = <port>
	database = loceval
	user = <db_admin>
	
	### (3) testing
	# The testing mirror is an exact copy of the production database, and
	# regularly re-copied over. Changes to the data on "testing" are non-permanent.
	[loceval-testing]
	folder = loceval_dev_structure
	host = <host>
	port = <port>
	database = loceval_testing
	user = <db_superuser>
	password = ***********
	
	# [...]
```
