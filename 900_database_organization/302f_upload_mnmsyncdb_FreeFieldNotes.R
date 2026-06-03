## libraries -------------------------------------------------------------------
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


# THIS SCRIPT DOES NOTHING.
# I keep it for basic, ad hoc connection to SYNCDB.


## data consolidation functions ------------------------------------------------
# some general functions to enable data aggregation further down

non_na <- function(x){
  if (all(is.na(x))) {
    return(invisible(NA))
  } else {
    return(x[!is.na(x)])
  }
}

unique_non_na <- \(x) unique(non_na(x))



## database connection ---------------------------------------------------------
config_filepath <- file.path("./mnm_database_connection.conf")

suffix <- "-dev"
suffix <- ""

mnmsyncdb_mirror <- glue::glue("mnmsyncdb{suffix}")

mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsyncdb_mirror
)

message(glue::glue("connected: psql {mnmsyncdb$shellstring}"))
syncdb_update_cascade_lookup <- parametrize_cascaded_update(mnmsyncdb)


sourcedb_labels <- c("loceval", "mnmgwdb") #, mnmsurfdb)
sourcedb_connections <- list()

for (sdb in sourcedb_labels) {
  sourcedb_connections[[sdb]] <- connect_mnm_database(
    config_filepath = config_filepath,
    database = sdb,
    user = "monkey",
    password = NA
  )

}



## FreeFieldNotes -----------------------------------------------------------
# use distinct union set
# but based on source_db delete if one note gets deleted
# so this might always be the union of all sourcedb's
# TODO unclear whether deletion works;
#      maybe some kind of transfer to sync is necessary



## Done! -----------------------------------------------------------------------
message("")
message("________________________________________________________________")
message(" >>>>> Nothing happened to SYNCDB. ")
message("________________________________________________________________")
