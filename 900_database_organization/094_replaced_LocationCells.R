
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# NOTE: this is not relevant for `loceval`
database_label <- "mnmgwdb"

testing <- FALSE
if (testing) {
  suffix <- "-staging" # "-testing"
} else {
  suffix <- ""
  keyring::key_set("DBPassword", "db_user_password") # <- for source database

}


### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
message(mnmgwdb$shellstring)

### connect to databases
loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)
# message(loceval_connection$shellstring)


# replacements <- mnmgwdb$query_columns(
#   table_label = "ReplacementData",
#   select_columns = c("grts_address", "grts_address_replacement")
#   )

locations_grts <- mnmgwdb$query_columns(
    table_label = "Locations",
    select_columns = c("grts_address", "location_id")
  )

# locations_grts %>% filter(location_id == 527)

## ----poc-data-----------------------------------------------------------------
# re-load POC data
load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())

# ... and code snippets.
snippets_path <- "/data/git/n2khab-mne-monitoring_support"
load_poc_code_snippets(snippets_path)

verify_poc_objects()

## ----location-cells-----------------------------------------------------------------

units_cell_polygon[["grts_address_final"]] <-
  as.integer(units_cell_polygon[["grts_address_final"]])

# unit geometries (cells):
location_cells <-
  units_cell_polygon %>%
  inner_join(
    locations_grts %>% distinct,
    by = join_by(grts_address_final == grts_address),
    relationship = "one-to-many",
    unmatched = "drop"
  ) %>%
  select(-grts_address_final) %>%
  relocate(geometry, .after = last_col())

sf::st_geometry(location_cells) <- "wkb_geometry"
# glimpse(location_cells)
location_cells %>%
  filter(location_id == 527)


message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of metadata.LocationCells"))

mnmgwdb$execute_sql(
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

mnmgwdb$insert_data(
  table_label = "LocationCells",
  upload_data = location_cells
)


extra_cells <- loceval_connection$query_table("ReplacementCells") %>%
  left_join(
    loceval_connection$query_table("Replacements") %>%
      select(-wkb_geometry),
    by = join_by(replacement_id)
  ) %>%
  rename(grts_address = grts_address_replacement) %>%
  inner_join(
    locations_grts,
    by = join_by(grts_address)
  ) %>%
  select(location_id, wkb_geometry) %>%
  distinct

mnmgwdb$insert_data(
  table_label = "LocationCells",
  upload_data = extra_cells
)



# SELECT *
# FROM "outbound"."SampleLocations" AS SLOC
# LEFT JOIN "metadata"."LocationCells" AS CELL
#   ON CELL.location_id = SLOC.location_id
# ;

if (FALSE) {
sample_locations <- mnmgwdb$query_table("SampleLocations")
location_cells <- mnmgwdb$query_table("LocationCells") %>% sf::st_as_sf()

mapview::mapview(
  location_cells %>%
    inner_join(
      sample_locations,
      by = join_by(location_id)
    ),
  zcol = "strata"
)
}
