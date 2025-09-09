
source("MNMLibraryCollection.R")
load_poc_common_libraries()
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")



config_filepath <- file.path("./inbopostgis_server.conf")
mirror <- "-staging"


mnmgwdb_mirror <- glue::glue("mnmgwdb{mirror}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror
)



# get SampleLocations

strata <- mnmgwdb$query_columns("SampleLocations", c("samplelocation_id", "grts_address", "strata"))

strata %>% distinct(strata) %>% print(n = Inf)
