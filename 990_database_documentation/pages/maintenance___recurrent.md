- via scripts:
  + `091_push_loceval_to_mnmgwdb.py`
  + `092_update_facalendar.R`
  + `093_replaced_LocationCells.R`
  + `094_sync_LocationInfos.py`
  + `095_re_link_foreign_keys_optional.R`
  + `096_update_wgs84_coordinates.R`
  + `097loceval_mhq_areas.R`
  + `097mnmgwdb_mhq_areas.R`
  + `098_random_placementpoints_mnmgwdb.R`
  + `099_sync_FreeFieldNotes.py`
- convenience script `090_all_maintenence_menu.sh`
- # current temporary extra tasks
- #### random point export
	- to https://docs.google.com/spreadsheets/d/11_0sACvkvX_teOO_nJmTxYSV4-EzOWtxJYE1QNkStAc/edit
	- #+begin_src sql
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
	  
	  #+end_src
- #### `CSA.fieldwork_id += 10000`
	- #+begin_src sql
	  UPDATE "inbound"."ChemicalSamplingActivities"
	    SET fieldwork_id = fieldwork_id + 10000
	    WHERE fieldwork_id < 9999
	  ;
	  
	  #+end_src