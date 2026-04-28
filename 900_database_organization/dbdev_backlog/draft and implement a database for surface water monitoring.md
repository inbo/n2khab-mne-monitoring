---
aliases:
  - draft mnmsurfdb
tags:
  - mnmsurfdb
  - initialization
started: 2026-03-11
finished:
execution:
  - FM
status: false
---

# procedure
## structure
- review [[locations/structure sheets|structure sheets]] (copied reference: mnmgwdb)
- create databases with `createdb <database> -O <owner> --port <port>`
- create [[users/users|roles]] (login as `postgres` user on one of the databases):
    ```sql
    CREATE ROLE user_surfdb;
    GRANT viewer_mnmdb TO user_surfdb;
    CREATE ROLE planner_surfdb;
    GRANT user_surfdb TO planner_surfdb;
    
    GRANT user_surfdb TO <****>;
    GRANT planner_surfdb TO <****>;

    ```
- activate [[postgis]] extension ∀ new databases
    ```sql
    CREATE EXTENSION postgis;
    CREATE EXTENSION postgis_topology;
    CREATE EXTENSION fuzzystrmatch;
    CREATE EXTENSION postgis_tiger_geocoder;
    ```
- add auth conf #authentication (`connection.conf` and `~/.pgpass`)

## tooling
- download structure sheet (`_dev`)
- make folders `mnmsurfdb_dev_structure`; add to `.gitignore`
- copy `701_init_mnmsurfdb.py`, execute, and fix bugs

# major changes
- rename to #FieldCalendar (no more work or activity implied)
- remove write access on #SampleUnits
- use #AllVisits as an interface; #Visits remains as the trivial subclass
	- other subtypes: #InstallationVisits and #SamplingVisits

# relevant other steps
- new user #roles: `planner_surfdb`, `user_surfdb`; granted to the specific users
- new entry in #TeamMembers: `all_surfers`
- adjust `Expost` queries for new table logic
- add cronjob for backups
- adjust #views