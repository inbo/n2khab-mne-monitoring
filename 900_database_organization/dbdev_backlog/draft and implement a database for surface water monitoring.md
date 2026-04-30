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
- work on `702_upload_mnmsurfdb.R`
	- #Protocols: cf. `410_update_protocols.qmd`
	- #GroupedActivities: added `is_surf_activity` for all databases
	- #N2kHabStrata: found that this is confusingly used with different meaning in #locevaldb (lookup types -> strata which makes some sense but the naming is subideal); in this scheme's database, this is used for the more extensive meta table
	- #Replacements: queried directly from `gwTransfer`
	- #Locations: worked almost as expected
	- #SampleUnits: `scheme_ps_targetpanel` is doubled; must make [[hacks/functions to unify scheme_ps_targetpanels]]
	- #FieldCalendar: 
		- an activity served for two panels simultaneously -> introduced a `distinct` to the calendar creation pipe
		   ```r
           fieldwork_shortterm_prioritization_by_stratum %>%
             filter( grts_address_final == 1675858, stratum == "3110_1_5", date_start == as.Date("2026-07-01") )
             # filter( grts_address_final == 22021842, stratum == "3110_0_1", date_start == as.Date("2026-10-01") )
             # filter( grts_address_final == 22021842, stratum == "3110_0_1", date_start == as.Date("2026-04-01") )
	       ```
		- TODO: priority is not defined for part of the calendar; set to zero

# major changes
- rename to #FieldCalendar (no more work or activity implied)
- remove write access on #SampleUnits
- use #Visits as an interface; #OtherVisits remains as the trivial subclass; #AllVisits can be a view.
	- other subtypes: #InstallationVisits and #SamplingVisits
- new column for #GroupedActivities: `is_surf_activity` to flag scheme-specific activities
    ```sql
    UPDATE "metadata"."GroupedActivities"
    SET is_surf_activity = TRUE
    WHERE activity_group IN (
      'ADHOCDIVERREPLACE', 'ADHOCPIPEREPLACE', 'GWSURFINSTALLMAT', 'GWSURFLEVREADDIVERMAN',
      'GWSURFSHALLSAMPREADMAN', 'SPATPOSITGAUGE', 'SPATPOSITPIPE', 'SURFADHOCGAUGEREPLACE',
      'SURFINSTGAUGE', 'SURFINSTWELLDIVER', 'SURFLENTDATACOLL', 'SURFLENTLOCEVALSAMPLPOINT',
      'SURFLEVREADDIVER', 'SURFLOTDATACOLL', 'SURFLOTLOCEVALSAMPLPOINT'
    );
    ```
- removed `SSPSTaPas` and references via `sspstapa_id`, which are bound for overhaul anyways

# relevant other steps
- new user #roles: `planner_surfdb`, `user_surfdb`; granted to the specific users
- new entry in #TeamMembers: `all_surfers`
- also add columns in #GroupedActivities to all other databases: `is_surf_activity`
- `SampleLocations` are more usefully labeled #SampleUnits
- adjust `Expost` queries for new table logic
- add cronjob for backups
- adjust #views
- rename `gwTransfer` to `LocevalTransfer`
