
# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


freeze_date <- as.Date("2025-12-31")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### connect databases
#///////////////////////////////////////////////////////////////////////////////

config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"
suffix <- "-staging"

# connect loceval
locevaldb_mirror <- glue::glue("loceval{suffix}")

locevaldb <- connect_mnm_database(
  config_filepath,
  database_mirror = locevaldb_mirror,
  user = "monkey",
  password = NA
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {locevaldb$shellstring}"))


# connect mnmgwdb
mnmgwdb_mirror <- glue::glue("mnmgwdb{suffix}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror,
  user = "monkey",
  password = NA
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {mnmgwdb$shellstring}"))


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### export characteristic columns
#///////////////////////////////////////////////////////////////////////////////
