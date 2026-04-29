# DO NOT MODIFY
# this file is "tangled" automatically from `930_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

migrating_table_label <- "Protocols"

config_filepath <- file.path("./mnm_database_connection.conf")

source_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval-dev"
)

source_data <- source_db$query_table(migrating_table_label)

dplyr::glimpse(source_data)

#_______________________________________________________________________________
### ENTER YOUR CODE here to modify the data!

sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol_version))
  return(prt)
}
source_data <- sort_protocols(source_data)

# further modification are possible
if ("protocol_id" %in% names(source_data)) {
  source_data <- source_data %>%
    select(-protocol_id)
}
#_______________________________________________________________________________

upload_additional_data(
  source_db,
  table_label = migrating_table_label,
  new_data = source_data,
  tabula_rasa = FALSE,
  verbose = FALSE
)
