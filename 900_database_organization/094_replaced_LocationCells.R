
library("dplyr")
library("tidyr")
library("stringr")
library("purrr")
library("lubridate")
library("sf")
library("terra")
library("n2khab")
library("googledrive")
library("readr")
library("glue")
library("rprojroot")
library("keyring")

source("MNMDatabaseToolbox.R")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")

testing <- FALSE
if (testing) {
  working_dbname <- "mnmgwdb_testing"
  connection_profile <- "mnmgwdb-testing"
  dbstructure_folder <- "./mnmgwdb_db_structure"
} else {
  # source("094_replaced_LocationCells.R")
  keyring::key_set("DBPassword", "db_user_password") # <- for source database
  working_dbname <- "mnmgwdb"
  connection_profile <- "mnmgwdb"
  dbstructure_folder <- "./mnmgwdb_db_structure"
}

db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


loceval_connection <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  user = "monkey",
  password = NA
)



# replacements <- dplyr::tbl(
#     db_connection,
#     DBI::Id("archive", "ReplacementData")
#   ) %>%
#   select(grts_address, grts_address_replacement) %>%
#   collect

locations_grts <- dplyr::tbl(
    db_connection,
    DBI::Id("metadata", "Locations")
  ) %>%
  select(grts_address, location_id) %>%
  collect

locations_grts %>% filter(location_id == 527)

# re-load POC data
poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)

# re-run code
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R")
invisible(capture.output(source("050_snippet_selection.R")))



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

execute_sql(
  db_connection,
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

append_tabledata(
  db_connection,
  DBI::Id(schema = "metadata", table = "LocationCells"),
  location_cells,
  reference_columns = "location_id"
)


extra_cells <- sf::st_read(
    loceval_connection,
    DBI::Id("outbound", "ReplacementCells")
  ) %>%
  collect %>%
  left_join(
    dplyr::tbl(
        loceval_connection,
        DBI::Id("outbound", "Replacements")
      ) %>% collect %>% select(-ogc_fid, -wkb_geometry),
    by = join_by(replacement_id)
  ) %>%
  rename(grts_address = grts_address_replacement) %>%
  inner_join(
    locations_grts,
    by = join_by(grts_address)
  ) %>%
  select(location_id) %>%
  distinct

append_tabledata(
  db_connection,
  DBI::Id(schema = "metadata", table = "LocationCells"),
  extra_cells,
  reference_columns = "location_id"
)



# SELECT *
# FROM "outbound"."SampleLocations" AS SLOC
# LEFT JOIN "metadata"."LocationCells" AS CELL
#   ON CELL.location_id = SLOC.location_id
# ;

if (FALSE) {
sample_locations <- dplyr::tbl(
    db_connection,
    DBI::Id("outbound", "SampleLocations")
  ) %>%
  collect

location_cells <- sf::st_read(
    db_connection,
    DBI::Id("metadata", "LocationCells")
  ) %>%
  select(-ogc_fid) %>%
  collect

mapview::mapview(
  location_cells %>%
    inner_join(
      sample_locations,
      by = join_by(location_id)
    ),
  zcol = "strata"
)
}
