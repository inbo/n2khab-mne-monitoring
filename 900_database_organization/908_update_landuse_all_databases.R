#!/usr/bin/env Rscript

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

todays_date <- strftime(as.POSIXct(Sys.time()), "%Y%m%d%H%M%S")

message("________________________________________________________________")
message("<<<<< Syncing LocationInfos LandUse [all]. ")
message("________________________________________________________________")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"



## connect source databases
db_labels <- c("mnmsyncdb", "loceval", "mnmgwdb", "mnmsurfdb")
db_connections <- list()

for (sdb in db_labels) {
  db_connection <- connect_mnm_database(
    config_filepath = config_filepath,
    database = glue::glue("{sdb}{suffix}")
  )
  message(glue::glue("\tconnected: psql {db_connection$shellstring}"))

  update_landuse_in_locationinfos(db_connection)

}


message("________________________________________________________________")
message(" >>>>> Finished syncing landuse infos [all]. ")
message("________________________________________________________________")
