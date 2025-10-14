
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

config_filepath <- file.path("./inbopostgis_server.conf")

# TODO also give coords for FreeFieldNotes


commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}



update_location_coordinates <- function(database_label) {
  # database_label <- "mnmgwdb"

  database_mirror <- glue::glue("{database_label}{suffix}")

  message("________________________________________________________________")
  message(glue::glue("restoring of {database_mirror} Coordinates"))

  # database connection
  mnmdb <- connect_mnm_database(
    config_filepath = config_filepath,
    database_mirror = database_mirror
  )
  # keyring::keyring_delete(keyring = "mnmdb_temp")

  ### load locations
  locations_sf <- mnmdb$query_table("Locations") %>%
    distinct() %>%
    sf::st_as_sf()

  locations_bd72 <- cbind(
      locations_sf,
      sf::st_coordinates(locations_sf)
    ) %>%
    rename(lambert_x = X, lambert_y = Y)

  locations_wgs84 <- sf::st_transform(locations_bd72, "EPSG:4326")

  all_coordinates <- cbind(
      sf::st_drop_geometry(locations_wgs84),
      sf::st_coordinates(locations_wgs84)
    ) %>%
    rename(wgs84_x = X, wgs84_y = Y) %>%
    mutate_at(
      vars(
        lambert_x,
        lambert_y,
      ), function (x) round(x, 2)
    ) %>%
    mutate_at(
      vars(
        wgs84_x,
        wgs84_y,
      ), function (x) round(x, 6)
    ) %>%
    distinct
  # all_coordinates %>% count(location_id) %>% arrange(desc(n)) %>% head

  update_cascade_lookup <- parametrize_cascaded_update(mnmdb)
  invisible(update_cascade_lookup(
    table_label = "Coordinates",
    new_data = all_coordinates,
    index_columns = c("coordinate_id"),
    characteristic_columns = c("location_id"),
    tabula_rasa = TRUE,
    verbose = TRUE
  ))

}


update_location_coordinates(database_label = "mnmgwdb")
update_location_coordinates(database_label = "loceval")

message("________________________________________________________________")
