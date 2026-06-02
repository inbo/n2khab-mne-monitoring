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
Therefore, `mnmsyncdb` is started up as a central place to store chronological, common information.

| table | comment |
|:------|-----|
| `LocationInfos`    | persistent infos about specific locations, e.g. accessibility; synced between databases    |
| `LocationJournals` | lifecycle information of a sample unit; chronological, append-only                                   |
| `FreeFieldNotes`   | free notes to be placed on a point on the map, can be related to field visits or prepared in the lab |
| `ReplacementData`  | TODO is there any need for this database to also store the selected `Replacements`? |

For other tables, irregular or indirect sync is sufficient, although they would profit from centralization (e.g. `TeamMembers`, `GroupedActivities`, `Versions`, ...)

# design decisions

> [!important] Limited [[tags/postgis|postGIS]] db:
> There is limited need for the postGIS extension in this table.
> `Locations` can be omitted; everything stays connected by `grts_address`.
> However, some tables (e.g. #FreeFieldNotes) must have a spatial position and therefore require GIS capabilities.

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

- DONE activate #backups

## tooling
- download structure sheet (`_dev`)
- make folders `mnmsyncdb_dev_structure`; add to `.gitignore`
- copy `301_init_mnmsyncdb.py`, adjust, execute
- initial data assembly with 
    - `302f_upload_mnmsyncdb_FreeFieldNotes.R` (noop)
    - `302i_upload_mnmsyncdb_LocationInfos.R`
    - `302j_upload_mnmsyncdb_LocationJournals.R`

# data assembly

## LocationInfos
### one-time assembly of existing data
... was lucky that there were no conflicts at the time of upload.

brief *failure* in attempting to use `categorize_data_update(...)` and `redistribute_calendar_data(...)`
because of the (clumsy) way that #precedence_columns are defined and filtered everywhere by default.
The `precedence_columns` cause issues here: they must be updated in the sync table despite their function as user input (the sync table has no input by itself, and therefore input precedence does not apply).

### continuous update
DONE: [[tooling/review correctness of the sync_mod function application]]; it had to be corrected in order to get the latest info by users.


## LocationJournals
### general
These are just an assembly of the activities which are found in the different databases; they are assembled on-the-fly and immediately distributed to databases by the script `111b_fill_location_journals.R`.
LoJos serve a "double check" function; already now I see that there were [[LoJo activities which are not recovered any more for the new upload]].

### issue: uniqueness
+ There were duplicates due to the `location_id` differences across databases.
+ There were more duplicates because the `loceval_type_absence` column seems to have changed.

[[structure/add nolog columns to LocationJournals]]

## FreeFieldNotes
These were in bad shape and required overhaul; the original Python script was a quick production.
Special foor #FreeFieldNotes, `log_` columns are used for identification (and should work well now).

+ sketched flow chart to make sure I miss no cases
+ existing and novel notes are separated
+ novel notes are uploaded
+ implement removal of deleted notes - will only delete if the origin db deletes it
+ [[datatypes/applied date rounding to FreeFieldNotes log_creation on ALL servers and mirrors]]
+ update updated notes based on `log_update`:
	+ any database can change any note, but only the latest change is kept
+ distribute latest data to user databases
+ [[users/REVOKE - GRANT sync change prevention for FreeFieldNotes]]
+ general testing on `staging` with a special import to qgis
	+ temptable update of spatial table!

# Implications
+ check [[LocationInfos from other schemes require double execution of REP update scripts]]