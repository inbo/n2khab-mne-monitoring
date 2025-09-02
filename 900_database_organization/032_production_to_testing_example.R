# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

migrating_table_label <- "Protocols"

config_filepath <- file.path("./inbopostgis_server.conf")

source_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval-dev"
)

source_data <- source_db$query_table(migrating_table_label)

dplyr::glimpse(source_data)

#_______________________________________________________________________________
### ENTER YOUR CODE here to modify the data!

sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
  return(prt)
}
source_data <- sort_protocols(source_data)

source_data <- source_data %>%
  select(-protocol_id)
#_______________________________________________________________________________

upload_data_and_update_dependencies(
  source_db,
  table_label = migrating_table_label,
  data_replacement = source_data,
  verbose = FALSE
)
