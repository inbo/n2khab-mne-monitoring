# compare the content of tables in two databases

source("MNMDatabaseToolbox.R")
config_filepath <- file.path("./inbopostgis_server.conf")


working_dbname <- "loceval_testing"
connection_profile <- "testing"


reference_dbname <- "loceval"
reference_profile <- "inbopostgis"


db_to_check <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)

db_reference <- connect_database_configfile(
  config_filepath,
  database = reference_dbname,
  profile = reference_profile,
  user = "monkey"
)


table_key <- "SampleLocations"
schema <- "outbound"


# compare data
reference_data <- dplyr::tbl(
  db_reference,
  DBI::Id(schema = schema, table = table_key)
  ) %>% collect()

check_data <- dplyr::tbl(
  db_to_check,
  DBI::Id(schema = schema, table = table_key)
  ) %>% collect()


mismatch_rows <- check_data %>%
  anti_join(
    reference_data,
    by = join_by(grts_address, type, location_id)
  ) %>%
  nrow()

print(mismatch_rows)
