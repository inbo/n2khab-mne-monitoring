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
  database_mirror = "loceval-staging"
)
print(test_db$shellstring)

update_cascade_testing <- parametrize_cascaded_update(test_db)


# SELECT * FROM "metadata"."Locations" WHERE grts_address = 871030;
# SELECT * FROM "outbound"."SampleUnits" WHERE grts_address = 871030;
# SELECT * FROM "outbound"."FieldActivityCalendar" WHERE grts_address = 871030;

#_______________________________________________________________________________
### basic database connection functions in place?

connection_base_tests <- function(mnmdb) {
  # mnmdb <- test_db

  # execute sql
  mnmdb$execute_sql(
    'SELECT last_value FROM "metadata".seq_protocol_id;',
    verbose = FALSE
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

  # characteristic columns
  stopifnot(identical(
    "location_id, grts_address, lambert_x, lambert_y, wgs84_x, wgs84_y",
    paste(mnmdb$get_characteristic_columns("Coordinates"), collapse = ", ")
  ))

  # primary key
  stopifnot("coordinate_id" == mnmdb$get_primary_key("Coordinates"))


} # /connection_base_tests

connection_base_tests(test_db)


#_______________________________________________________________________________
### keyring tests

keyring_tests <- function() {
  keyring::keyring_create("test", password = "")
  print(get_mnm_password(username = "mickey", keyring_label = "test"))
  keyring::keyring_list()
  keyring::keyring_lock("test")
  keyring::keyring_delete("test")
  terminate_keyring("test")
}

#_______________________________________________________________________________
### Do queries work as intended?

query_tests <- function(mnmdb) {

  # protocols are alphabetically sorted
  stopifnot(
    mnmdb$query_columns("Protocols", c("protocol_id", "protocol")) %>%
      filter(grepl("sfp-001-nl", protocol)) %>%
      pull(protocol_id) %>%
      {. == 1}
  )

  # no new teammembers have started
  stopifnot(
    mnmdb$pull_column("TeamMembers", "teammember_id") %>%
      length() %>%
      {. == 11}
  )

  # FreeFieldNotes are spatial, but TeamMembers are not
  stopifnot(
    "FreeFieldNotes" = mnmdb$is_spatial("FreeFieldNotes"),
    "TeamMembers" = isFALSE(mnmdb$is_spatial("TeamMembers"))
  )

  # we can query LocationInfos
  mnmdb$query_table("LocationInfos") %>%
    filter(!is.na(recovery_hints)) %>%
    head(10) %>% tail(2) %>% t() %>% knitr::kable()

  # we can retrieve multiple tables at once
  mnmdb$query_tables_data(c("GroupedActivities", "Protocols", "TeamMembers"))

  # ... and create lookup tables for dependent columns
  mnmdb$lookup_dependent_columns("Protocols", "GroupedActivities")

  # reset sequence keys:
  # (a) restart at one
  mnmdb$set_sequence_key("TeamMembers", verbose = TRUE)
  # (b) set to arbitrary values
  mnmdb$set_sequence_key("TeamMembers", 10, verbose = TRUE)
  # (c) set to highest of actual value and current counter
  mnmdb$set_sequence_key("TeamMembers", "max", verbose = TRUE)

  # an in-memory backup procedure
  store <- mnmdb$store_table_deptree_in_memory("Protocols")
  mnmdb$restore_table_data_from_memory(store)

} # /query_tests

query_tests(test_db)

#_______________________________________________________________________________

## unclear whether this does not kill the ID links of
#   indirectly dependent tables. -> tests
# table_label <- "Locations"
# store <- test_db$store_table_deptree_in_memory("Locations")
tablab <- "Locations"
tablab <- "LocationCells"
tablab <- "Coordinates"
tablab <- "LocationInfos"
tablab <- "SampleUnits"
tablab <- "MHQPolygons"
tablab <- "LocationAssessments"
tablab <- "Visits"
test_db$query_table(tablab)

 table_label <- tablab
 table_id <- test_db$get_table_id(table_label)
 dplyr::tbl(test_db$connection, table_id)

#
# mnmdb$restore_table_data_from_memory(store)

#_______________________________________________________________________________
### spatial tables
test_spatial <- function(mnmdb) {
  # mnmdb <- test_db
  table_label <- "FreeFieldNotes"
  spatial_data <- mnmdb$query_table(table_label)
  # spatial_data %>% count(grts_address) %>% arrange(desc(n)) # different problem

  update_cascade_testing(
    table_label,
    new_data = spatial_data,
    index_columns = c("fieldnote_id"),
    characteristic_columns = NULL,
    tabula_rasa = FALSE,
    skip_sequence_reset = FALSE,
    verbose = TRUE
  )
}

test_spatial(test_db)


#_______________________________________________________________________________
# cascaded update - TeamMember example

# update_cascade_testing


#_______________________________________________________________________________
