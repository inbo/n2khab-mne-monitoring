---
aliases:
  - draft mnmsyncdb
tags:
  - mnmsyncdb
  - initialization
  - implementation
started: 2026-05-06
finished:
execution:
  - FM
status: false
---

Some tables require regular synchronization between databases.

| table | comment |
|:------|-----|
| `LocationInfos`    | persistent infos about specific locations, e.g. accessibility; synced between databases    |
| `LocationJournals` | lifecycle information of a sample unit; chronological, append-only                                   |
| `FreeFieldNotes`   | free notes to be placed on a point on the map, can be related to field visits or prepared in the lab |

For others, irregular or indirect sync is sufficient, although they would profit from centralization (e.g. `TeamMembers`, `GroupedActivities`, `Versions`, ...)

Therefore, `mnmsyncdb` is started up as a central place to store chronological, common information.


# design decisions

> [!important] Limited [[tags/postgis|postGIS]] db:
> There is no need for the postGIS extension in this table.
> In consequence, `Locations` can be omitted; everything stays connected by `grts_address`.
> However, some tables (e.g. #FreeFieldNotes) must have a spatial position

- `<table>_id` columns will be independent across databases
- `log_origindb` (varchar(8)) introduced to reference the origin database
- `log_*` columns are static and assemble data from the origin databases (the only user to fill #mnmsyncdb will be maintenance user)

# procedure
## structure
- review [[locations/structure sheets|structure sheets]] (reduced variant)
- create databases with `createdb <database> -O <owner> --port <port>`
- create [[users/users|roles]] only once (login as `postgres` user on one of the databases):
    ```sql
    CREATE ROLE user_syncdb;
    GRANT viewer_mnmdb TO user_syncdb;
    
    GRANT user_syncdb TO <****>;

    ```
- activate #postgis extension ∀ new databases 
```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
```
- add auth conf #authentication (`connection.conf` and `~/.pgpass`)

- TODO activate #backups

## tooling
- download structure sheet (`_dev`)
- make folders `mnmsyncdb_dev_structure`; add to `.gitignore`
- copy `301_init_mnmsyncdb.py`, adjust, execute

## data assembly
### one-time assembly of existing data

**LocationInfos:**
was lucky that there were no conflicts at the time of upload.