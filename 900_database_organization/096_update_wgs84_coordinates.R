
library("dplyr")
library("sf")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password") # <- for source database

config_filepath <- file.path("./inbopostgis_server.conf")


update_location_coordinates <- function(database_label, testing = TRUE) {
  # db_name <- glue::glue("{database_label}_testing")

  if (testing) {
    connection_profile <- glue::glue("{database_label}-testing")
  } else {
    connection_profile <- glue::glue("{database_label}")
  }

  # database connection
  db_connection <- connect_database_configfile(
    config_filepath = config_filepath,
    profile = connection_profile
  )

  ### load locations
  locations_sf <- sf::st_read(
    db_connection,
    DBI::Id("metadata", "Locations")
    ) %>%
    select(-ogc_fid) %>%
    collect

  locations_bd72 <- cbind(locations_sf, sf::st_coordinates(locations_sf)) %>%
    rename(lambert_x = X, lambert_y = Y)

  locations_wgs84 <- sf::st_transform(locations_bd72, "EPSG:4326")

  locations <- cbind(
      sf::st_drop_geometry(locations_wgs84),
      sf::st_coordinates(locations_wgs84)
    ) %>%
    rename(wgs84_x = X, wgs84_y = Y)

  append_tabledata(
    db_connection,
    DBI::Id(schema = "metadata", table = "Coordinates"),
    locations,
    reference_columns = "location_id"
  )

}


update_location_coordinates("mnmgwdb", testing = FALSE)
update_location_coordinates("loceval", testing = FALSE)
