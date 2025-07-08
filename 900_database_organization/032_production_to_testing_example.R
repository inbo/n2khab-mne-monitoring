# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

library("dplyr")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

migrating_table_key <- "LocationAssessments"
migrating_table <- DBI::Id(schema = "outbound", table = migrating_table_key)

source_db_connection <- connect_database_configfile(
  config_filepath = file.path("./inbopostgis_server.conf"),
  profile = "testing",
  database = "loceval_testing"
)

protocols_data <- dplyr::tbl(
    source_db_connection,
    migrating_table
  ) %>%
  collect() # collecting is necessary to modify offline and to re-upload

dplyr::glimpse(protocols_data)

#_______________________________________________________________________________
### ENTER YOUR CODE here to modify the data!

sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
  return(prt)
}
# protocols_data <- sort_protocols(protocols_data)

# protocols_data <- protocols_data %>%
#   select(-protocol_id)
#_______________________________________________________________________________

update_datatable_and_dependent_keys(
  config_filepath = file.path("./inbopostgis_server.conf"),
  working_dbname = "loceval",
  table_key = migrating_table_key,
  new_data = protocols_data,
  profile = "loceval",
  dbstructure_folder = "loceval_db_structure",
  verbose = FALSE
)
