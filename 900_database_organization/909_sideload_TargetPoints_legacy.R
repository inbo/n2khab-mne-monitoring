#!/usr/bin/env Rscript

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

todays_date <- strftime(as.POSIXct(Sys.time()), "%Y%m%d%H%M%S")

message("________________________________________________________________")
message("<<<<< Syncing TargetPoints Legacy [all]. ")
message("________________________________________________________________")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
suffix <- "-staging"


database <- "loceval"

locevaldb <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("{database}{suffix}")
)

message(glue::glue("\tconnected: psql {locevaldb$shellstring}"))

update_cascade_lookup <- parametrize_cascaded_update(locevaldb)

#_______________________________________________________________________________
### load legacy points

gpkg_dev_filepath <- file.path("data", "fieldwork_shortterm_dev.gpkg")

# layers_available <- sf::st_layers(gpkg_dev_filepath)
sideload_gpkg <- sf::st_read(
  gpkg_dev_filepath,
  layer = "legacywatsamppoints_shortterm_lentictypes_POINTS"
)

sideload_gpkg %>% glimpse()

to_timestring <- function (ts, fmt = "%Y-%m-%d %H:%M:%OS0") {
  return(strftime(ts, format = fmt, tz = "UTC"))
}

targetpoints_upload <- sideload_gpkg %>%
  rename(
    try_first = legacy_try_first,
    notes = annotation
  ) %>%
  mutate(
    # date_selection = to_timestring(lastdate_legacysampling_polygon, "%Y-%m-%d"),
    date_selection = as.Date(lastdate_legacysampling_polygon),
    log_creator = "legacy",
    log_creation = to_timestring(active_in_db_from),
    log_user = "legacy",
    log_update = convert_timestamp_to_ms_character(Sys.time()),
    is_legacypoint = TRUE
  ) %>%
  select(
    log_creator,
    log_creation,
    log_user,
    log_update,
    date_selection,
    notes,
    is_legacypoint,
    try_first
  ) %>%
  sf::st_set_crs(31370)

sf::st_geometry(targetpoints_upload) <- "wkb_geometry"

# mapview::mapview(targetpoints_upload)

targetpoints_upload %>% head(3) %>% t() %>% knitr::kable()


tpts_namestring <- locevaldb$get_namestring("TargetPoints")
# SELECT FROM "inbound"."TargetPoints" WHERE is_legacypoint;
locevaldb$execute_sql(
  glue::glue('DELETE FROM {tpts_namestring} WHERE is_legacypoint;'),
  verbose = TRUE
)


locevaldb$insert_data(
  table_label = "TargetPoints",
  upload_data = targetpoints_upload
)


# $ grts_address_final              -> NA [!]
# $ polygon_id                      -> NA
# $ lastdate_legacysampling_polygon -> date_selection
# $ legacy_try_first                -> try_first
# $ x                               -> NA
# $ y                               -> NA
# $ annotation                      -> notes
# $ ranknr                          -> NA
# $ active_in_db_from               -> log_creation
# $ active_in_db_till               -> NA
# $ geom                            -> [triv.]
