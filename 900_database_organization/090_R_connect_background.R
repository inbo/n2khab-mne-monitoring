
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")


### connect to database
###
keyring_label <- 'mnmdb_temp'
# note that you can create two keyrings of the same name! (shadowing)
# avoid stacking keyrings with the same name
if (keyring_label %in% keyring::keyring_list()$keyring) {
  stop(glue::glue("Keyring Conflict: `{keyring_label}` already exists."))
}
# keyring::keyring_delete(keyring = "mnmdb_temp")

# silent, single-prompt creation
suppressWarnings(keyring::keyring_create(keyring_label, password = ""))

# unlock it to schedule lock
unlock_keyring(keyring_label = keyring_label)

while (TRUE) {
   Sys.sleep(5)
}
