---
aliases:
  - daily maintenance scripts
  - sync scripts
---


- via many scripts stored under `900_database_organization/100_MAINTENANCE`
- ~~convenience script `101_all_maintenence_menu.sh`~~ *script is currently not working due to a safety measure that prevents accidentally overwriting [[database/mirrors|production]] data by user prompt*

Currently, I tend to open two terminals and execute the processes in parallel, first on `-staging`, then on `production`.
+ prerequisite: [[database/copy|copy]] data from `production` to `staging` for all databases
+ run `Rscript 1xy_<script>.R -staging` to test a script on `staging`; solve putative errors and sync/test again
+ then, open an `R --silent --no-save --no-restore` console and `source("1xy_<script>.R")` to apply it to `production`

The procedure currently demands about 30 minutes of work time (which is why I do not perform it daily, but rather twice a week).
All this could be automated, and I would actually love to achieve that.
However, I currently lack the time to define and track robust and general start/end states for each script which cleanly exit a failed script, restore prior state, and report back.



# current temporary extra tasks
#### random point export
- to https://docs.google.com/spreadsheets/d/11_0sACvkvX_teOO_nJmTxYSV4-EzOWtxJYE1QNkStAc/edit
- ```sql
	\COPY (
		SELECT samplelocation_id,
		location_id,
		grts_address,
		random_point_rank,
		compass,
		angle,
		angle_look,
		distance_m,
		lambert_lon,
		lambert_lat
		FROM "outbound"."RandomPoints"
		WHERE angle IS NOT NULL
		ORDER BY grts_address ASC, random_point_rank ASC
	) TO '/data/mnm_db_backups/randompoints.csv' With CSV DELIMITER ',' HEADER
	;
	
  ```

