
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")


### connect to database
###
init_keyring(keyring_label = "mnmdb_temp")
unlock_keyring(keyring_label = "mnmdb_temp")
get_mnm_password(
  username = "falk",
  keyring_label = "mnmdb_temp"
)
