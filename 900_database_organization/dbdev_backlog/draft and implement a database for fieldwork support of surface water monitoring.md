---
aliases:
  - draft mnmsurfdb
  - draft and implement mnmsurfdb
tags:
  - mnmsurfdb
  - initialization
  - implementation
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
- append `102_re_link_foreign_keys.R` as other scripts depend on it
	- added #InstallationRemovals to `102_re_link_foreign_keys.R`
	- added #MHQPolygons to `102_re_link_foreign_keys.R`
	- not added #Coordinates to `102_re_link_foreign_keys.R`
- work on `702_upload_mnmsurfdb.R` (following `610_mnmgwdb_update_REP.qmd`)
	- #Protocols: cf. `410_update_protocols.qmd` [[Visits need to be linked or tagged with Protocols versions]]
	- #GroupedActivities: 
		- added `is_surf_activity` for #alldatabases 
		- pulled in status quo from #loceval due to [[structure/flag auxiliary FAGs|fag flag tag]]
	- open [[N2kHabStrata table is inconsistently used across databases]]; in this scheme's database, #N2kHabStrata are used for the more extensive meta table
	- #Replacements: queried directly from `gwTransfer`; [[distribute loceval information via mnmsyncdb]]
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
		- TODO: priority is not defined yet for part of the calendar; set to zero
	- #Visits:
		- changed to visits interface and #OtherVisits
	 - #LocationInfos, #LocationJournals and #FreeFieldNotes queried from #mnmsyncdb

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
- removed `SSPSTaPas` and references via `sspstapa_id`, which [[overhaul or remove SSPSTaPas and FieldCalendar sspstapa_id from mnmgwdb|are bound for overhaul anyways]]
- realized that the cascade_upload functions in `702_upload_mnmsurfdb.R` already trigger `102_re_link_foreign_keys.R`, which therefore must be adjusted with priority

# relevant other steps
- [x] TODO [[distribute loceval information via mnmsyncdb]]
- [x] new user #roles: `planner_surfdb`, `user_surfdb`; granted to the specific users
- [x] new entry in #TeamMembers: `all_surfers`
- [x] also add columns in #GroupedActivities to all other databases: `is_surf_activity`
- [x] `SampleLocations` are more usefully labeled #SampleUnits / *cf.* [[consistent table and field names across databases]]
- [x] adjust `Expost` queries for new table logic
- [x] add cronjob for backups
- [x] does #MHQPolygons need to link to `sampleunit_id` #mnmgwdb ?
	- this is used in the respective #view 
	- limiting displayed MHQPolygons to #SampleUnits which appear in #LocationEvaluations
	- for testing: linked it to #Locations via  `location_id` as they appear in #InstallationVisits 
- [x] [[structure/add nolog columns to LocationJournals|add nolog columns to LocationJournals]]
- [x] adjust #views
	- [x] `surf_FieldWork.sql`
	- [x] `surf_FieldworkPlanning.sql`
	- [x] `surf_LocevalInfo.sql`
	- [x] `surf_MHQSafety.sql`
	- [x] `surf_SampleCells.sql`
	- [x] `view_coordinates.sql`
- [x] review and adjust all scripts in categories `000_DOCUMENTATION` and `100_MAINTENANCE`
	- [x] 080
	- [x] 047
	- [x] Coordinates
	- [x] MHQAreas
- [ ] `update_landuse_in_locationinfos` -> works for new locations?
