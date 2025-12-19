
library("dplyr")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

migrating_table_key <- "LocationAssessments"
migrating_table <- DBI::Id(schema = "outbound", table = migrating_table_key)

source_db_connection <- connect_database_configfile(
  config_filepath = file.path("./inbopostgis_server.conf"),
  profile = "loceval",
  database = "loceval",
  user = "monkey",
  password = NA
)

migtab_data <- dplyr::tbl(
    source_db_connection,
    migrating_table
  ) %>%
  collect() # collecting is necessary to modify offline and to re-upload

dplyr::glimpse(migtab_data)

#_______________________________________________________________________________
### ENTER YOUR CODE here to modify the data!

sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
  return(prt)
}
# protocols_data <- sort_protocols(protocols_data)
#
# protocols_data <- protocols_data %>%
#   select(-protocol_id)

#_______________________________________________________________________________

update_datatable_and_dependent_keys(
  config_filepath = file.path("./inbopostgis_server.conf"),
  working_dbname = "loceval_testing",
  table_key = migrating_table_key,
  new_data = migtab_data,
  profile = "testing",
  dbstructure_folder = "loceval_db_structure",
  verbose = FALSE
)

# SELECT DISTINCT assessment_done, cell_disapproved, count(*) FROM "outbound"."LocationAssessments" GROUP BY assessment_done, cell_disapproved;
