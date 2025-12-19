
-- there is a problem with grts_address = 871030
-- it disappeared, except from LocationInfos, Coordinates, and Locations
SELECT * FROM "metadata"."Coordinates" WHERE grts_address = 871030;
SELECT * FROM "outbound"."LocationInfos" WHERE grts_address = 871030;
SELECT * FROM "metadata"."Locations" WHERE grts_address = 871030;
-- temporarily deleted on "staging"

--------------------------------------------------------------------------------
-- DECISION (I): remove 993 and keep 992.

```{r}
source("MNMLibraryCollection.R")
load_database_interaction_libraries()
source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

config_filepath <- file.path("./inbopostgis_server.conf")

database_mirror <- "loceval-staging"

mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = database_mirror,
  user = "monkey",
  password = NA
)
# mnmdb$shellstring

deptabs <- mnmdb$get_dependent_tables("Locations")

for (dt in deptabs) {
  print(glue::glue("
    UPDATE {mnmdb$get_namestring(dt)}
    SET location_id = 992 WHERE location_id = 993
    ;"))
}

```

-- [1] "Locations"           "LocationCells"       "Coordinates"
-- [4] "LocationInfos"       "SampleUnits"         "MHQPolygons"
-- [7] "LocationAssessments" "Visits"

UPDATE "metadata"."LocationCells"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "metadata"."Coordinates"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "outbound"."LocationInfos"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "outbound"."SampleUnits"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "outbound"."MHQPolygons"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "outbound"."LocationAssessments"
SET location_id = 992 WHERE location_id = 993
;
UPDATE "inbound"."Visits"
SET location_id = 992 WHERE location_id = 993
;

SELECT * FROM "metadata"."Locations" WHERE location_id = 993;


--------------------------------------------------------------------------------
-- BUT: where is the rest of the data?
-- suspicion: lost it on ./20250827_another_duplicate_SampleLocation.sql
--
-- luckily I kept /data/mnm_db_backups/foefelen/mnmgwdb_latest.sql

εὕρηκα!

mnmgwdb_staging=# SELECT * FROM "archive"."ReplacementData" WHERE grts_address_replacement = 871030;
 replacementdata_id |   type    | grts_address | grts_address_replacement | replacement_rank | is_replaced | new_location_id | new_samplelocation_id
--------------------+-----------+--------------+--------------------------+------------------+-------------+-----------------+-----------------------
                623 | 4010      |        84598 |                   871030 |                1 | t           |             698 |                   857
                627 | 7150      |        84598 |                   871030 |                1 | t           |             698 |                   858

This is feedback from `mnmgwdb`;
I must double-check 095 to un-replace the grts.
(or at least avoid duplicates)
