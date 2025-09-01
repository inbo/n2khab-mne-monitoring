#!/usr/bin/env Rscript

# unit test procedures for the MNM database tooling.

#_______________________________________________________________________________
### load all libraries?

# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


#_______________________________________________________________________________
### connect database?

config_filepath <- file.path("./inbopostgis_server.conf")
# keyring::key_set("DBPassword", "db_user_password") # <- for source database

test_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval-dev"
)


#_______________________________________________________________________________
### basic database connection functions in place?

connection_base_tests <- function(mnmdb) {
  # mnmdb <- test_db

  # execute sql
  mnmdb$execute_sql(
    'SELECT last_value FROM "metadata".seq_protocol_id;',
    verbose = TRUE
  )


  # dump
  dump_file <- tempfile()
  mnmdb$dump_all(
    dump_file,
    exclude_schema = c("tiger", "public")
  )
  file.remove(dump_file)

  # schema
  stopifnot(
    "metadata" == mnmdb$get_schema("GroupedActivities"),
    "inbound" == mnmdb$get_schema("FreeFieldNotes")
  )

  # namestring
  stopifnot(
    '"metadata"."TeamMembers"' == mnmdb$get_namestring("TeamMembers")
  )

  # DBI Id's
  stopifnot(
    toString(DBI::Id("metadata", "LocationCells")) ==
      toString(mnmdb$get_table_id("LocationCells")),
    toString(DBI::Id("metadata", "LocationCells")) ==
      toString(mnmdb$get_table_id_lowercase("locationcells"))
  )

  # get dependencies
  stopifnot(identical(
    c("Protocols", "GroupedActivities"),
    mnmdb$get_dependent_tables("Protocols")
  ), identical(
    "Protocols, GroupedActivities",
    paste(names(mnmdb$get_dependent_table_ids("Protocols")), collapse = ", ")
  ))

  # table infos
  stopifnot(identical(
    "location_id, grts_address, wkb_geometry",
    paste(mnmdb$load_table_info("Locations") %>% pull(column), collapse = ", ")
  ))


    mnmdb$get_characteristic_columns("FreeFieldNotes")


}




update_cascade_loceval <- parametrize_cascaded_update(test_db)
