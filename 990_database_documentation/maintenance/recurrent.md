- via many scripts stored under `900_database_organization/100_MAINTENANCE`
- convenience script `101_all_maintenence_menu.sh`

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

