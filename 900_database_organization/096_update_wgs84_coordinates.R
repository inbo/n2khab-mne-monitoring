
library("dplyr")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password") # <- for source database

db_name <- glue::glue("mnmgwdb_testing")
connection_profile <- glue::glue("mnmgwdb-testing")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")
dbstructure_folder <- glue::glue("{database_label}_dev_structure")

# from source...
source_db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = database_label,
  user = "monkey",
  password = NA
)

# ... to target
db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = connection_profile
)
