# DO NOT MODIFY
# this file is "tangled" automatically from `930_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

table_label <- "Protocols" #"LocationCells"# "Protocols"

config_filepath <- file.path("./mnm_database_connection.conf")

source_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval"
)

target_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval-testing"
)

source_data <- source_db$query_table(table_label)

dplyr::glimpse(source_data)

#_______________________________________________________________________________
### ENTER YOUR CODE here to modify the data!
new_data <- source_data

sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol_code))
  return(prt)
}
new_data <- sort_protocols(new_data)

# further modification are possible
if ("protocol_id" %in% names(source_data)) {
  source_data <- source_data %>%
    select(-protocol_id)
}
#_______________________________________________________________________________

characteristic_columns <- target_db$get_characteristic_columns(table_label)

if (is.scalar.na(characteristic_columns)) {
  # just take all columns
  characteristic_columns <- names(new_data)
}

# if all else fails (e.g. LocationCells), use the target columns
if (length(characteristic_columns) == 0) {
  # pk <- target_db$get_primary_key(table_label)
  # characteristic_columns <- c(pk)
  characteristic_columns <-
    target_db$load_table_info(table_label) %>%
      pull(column)
  print(characteristic_columns)

  if (target_db$is_spatial(table_label)) {
    new_data <- new_data %>% sf::st_as_sf(crs = 31370)

    sf::st_crs(new_data) <- 31370
    sf::st_geometry(new_data) <- "wkb_geometry"
  }
}


upload_data_and_update_dependencies(
  target_db,
  table_label = table_label,
  data_replacement = new_data,
  characteristic_columns = characteristic_columns,
  verbose = FALSE
)
