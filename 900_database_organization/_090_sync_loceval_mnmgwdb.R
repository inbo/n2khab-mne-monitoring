# TODO ON HOLD
# I have decided to use python to make this runnable on the R-less server

library("dplyr")
library("sf")
source("MNMDatabaseToolbox.R")

# sync:
#     - FreeFieldNotes (☇spatial)
#     - LocationInfos
#       - (recovery_hints are more specific -> keep on Visits)
#     - > loceval


projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")
config <- configr::read.config(file = config_filepath) # [[connection_profile]]

loceval <- connect_database_configfile(
  config_filepath,
  profile = "loceval_testing"
)

mnmgwdb <- connect_database_configfile(
  config_filepath,
  profile = "mnmgwdb_testing"
)


#_______________________________________________________________________________
# Free Field Notes

db_source <- loceval
db_target <- mnmgwdb
schema <- "inbound"
table_key <- "FreeFieldNotes"
primary_key_columns <- c("freefieldnote_id")
data_columns <- c("teammember_id", "field_note", "note_date", "location", "activity", "photo")
is_spatial <- TRUE
# TODO reference_links <- lookup_df # create a translator a priori

supplement_table <- function(
    db_source,
    db_target,
    schema,
    table_key,
    primary_key_columns,
    data_columns,
    is_spatial = FALSE
  ) {

  if (is_spatial) {
    load_data_function <- sf::
  }

  data_source <- dplyr::tbl(
      db_source,
      DBI::Id(schema, table_key)
    )

  data_target <- dplyr::tbl(
      db_source,
      DBI::Id(schema, table_key)
    )

    # [!] reference_links

}
