#!/usr/bin/env Rscript


#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


date_today <- as.integer(format(Sys.time(), "%Y%m%d"))

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")


# commandline_args <- commandArgs(trailingOnly = TRUE)
# if (length(commandline_args) > 0) {
#   suffix <- commandline_args[1]
# } else {
#   suffix <- ""
#   # suffix <- "-staging" # "-testing"
# }
suffix <- "-staging"



## connect sync database
mnmsyncdb_mirror <- glue::glue("mnmsyncdb{suffix}")

mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsyncdb_mirror
)

message(glue::glue("connected: psql {mnmsyncdb$shellstring}"))
syncdb_update_cascade_lookup <- parametrize_cascaded_update(mnmsyncdb)


## connect source databases
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



## FreeFieldNotes --------------------------------------------------------------

characteristic_columns <- c(
  "log_creator",
  "log_creation"
)

ensure_nonna_crs <- function(tbl) {
  if (is.na(sf::st_crs(tbl))) {
    tbl <- tbl %>%
      sf::st_as_sf() %>%
      sf::st_set_crs(31370) %>%
      dplyr::as_tibble()
  }

  return(tbl)
}

round_creation_date <- function(tbl) {
  tbl %>%
    mutate(log_creation = lubridate::round_date(log_creation, "seconds")) %>%
    return()
}

upload_new_fieldnotes <- function(db, fieldnotes_to_upload) {

  append_tabledata(
    db$connection,
    table_id = db$get_table_id("FreeFieldNotes"),
    data_to_append = fieldnotes_to_upload %>%
    sf::st_as_sf(crs = 31370),
    characteristic_columns = characteristic_columns,
    verbose = TRUE
  )

}


query_freefieldnotes <- function(db) {
  db$query_table("FreeFieldNotes") %>%
    dplyr::arrange(log_creation, log_creator) %>%
    ensure_nonna_crs() %>%
    round_creation_date() %>%
    return()
}


synchronize_syncdb_with_freefieldnotes <- function(sdb) {
  # sdb <- "mnmgwdb"

  # load the status quo from SYNCDB
  freefieldnotes_statusquo <- query_freefieldnotes(mnmsyncdb)
  # observation: datetime in `log_creation` does not
  #   work well for filtering joins -> rounded explicitly


  # choose the current database connection
  mnmdb <- sourcedb_connections[[sdb]]

  # query source: user input from databases
  freefieldnotes_source <- query_freefieldnotes(mnmdb) %>%
    dplyr::mutate(
      archive_date = NA
    ) %>%
    dplyr::relocate(archive_date, .before = wkb_geometry)

  # mapview::mapview(freefieldnotes_source %>% sf::st_as_sf())

  # (1) find novel field notes
  existing_fieldnotes <- freefieldnotes_source %>%
    dplyr::semi_join(
      freefieldnotes_statusquo,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    )

  novel_fieldnotes <- freefieldnotes_source %>%
    dplyr::anti_join(
      freefieldnotes_statusquo,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    ) %>%
    head(10) # TODO remove testing limit

  # upload novel notes
  upload_new_fieldnotes(
    mnmsyncdb,
    novel_fieldnotes
  )


  # (2) find deleted fieldnotes
  #     taking log_origindb into account check which notes are removed
  #     flagging an archive date to freefieldnotes
  removed_fieldnotes <- freefieldnotes_statusquo %>%
    filter(log_origindb == sdb) %>%
    dplyr::anti_join(
      freefieldnotes_source,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    ) %>%
    dplyr::mutate(archive_date = date_today)
  # IMPORTANT: these removals must be reflected in the other sdb's (see below)


  # (3) update changed fieldnotes (bi-directional)
  #     by slicing the latest log_update


} # /synchronize_syncdb_with_freefieldnotes


# TODO TODOs:
# - turn around: feedback to soruce-db's
# - including removing all FFNs with !is.na(archive_date)
# - update / reset keys
