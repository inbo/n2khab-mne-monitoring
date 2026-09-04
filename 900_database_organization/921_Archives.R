
## quick script to create an `archive` table

# libraries
source("MNMLibraryCollection.R")
load_poc_common_libraries()
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


# connect database
mirror <- "-staging"
mnmdb_mirror <- "mnmgwdb{mirror}"

mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmdb_mirror
)

# start empty
empty_archive <- mnmdb$query_table("Protocols") %>%
  filter(TRUE == FALSE) %>%
  mutate(version_id = integer()) %>%
  relocate(version_id)


rs <- DBI::dbWriteTable(
  mnmdb$connection,
  DBI::Id("archive", "oldProtocols"),
  empty_archive,
  row.names = FALSE,
  overwrite = FALSE,
  append = TRUE,
  factorsAsCharacter = TRUE,
  binary = TRUE
)
