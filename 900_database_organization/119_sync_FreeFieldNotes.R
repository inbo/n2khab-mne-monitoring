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
    database = glue::glue("{sdb}{suffix}"),
    user = "monkey",
    password = NA
  )

}



## FreeFieldNotes --------------------------------------------------------------

characteristic_columns <- c(
  "log_creator",
  "log_creation"
)

# ensure that the CRS of a spatial tibble (or whatever dplyr/sf give us) at
# least wraps the right coordinate reference system
ensure_nonna_crs <- function(tbl) {
  if (is.na(sf::st_crs(tbl))) {
    tbl <- tbl %>%
      sf::st_as_sf() %>%
      sf::st_set_crs(31370) %>%
      dplyr::as_tibble()
  }

  return(tbl)
}

# to enable (filtering) joins, the `log_creation` datetime must be rounded to
# full seconds
round_creation_date <- function(tbl) {

  # note: there is also `?lubridate::floor_date`, but besides the slightly funny
  # function name I fear that float accuracy of seconds can also make it come
  # out at `floor(0.9999)` which would fail to join `floor(1.0001)`.
  # With `round_date`, the same issue happens if `log_creation == 0.4999`, but I
  # find this less likely.
  tbl %>%
    mutate(log_creation = lubridate::round_date(log_creation, "seconds")) %>%
    return()
}

# a common function to query and parse the fieldnotes, given a database
query_freefieldnotes <- function(db) {
  db$query_table("FreeFieldNotes") %>%
    dplyr::arrange(log_creation, log_creator) %>%
    ensure_nonna_crs() %>%
    round_creation_date() %>%
    return()
}


# there... and back again: upload new fieldnotes,
# simply appending them to the existing data
upload_new_fieldnotes_append <- function(db, fieldnotes_to_upload) {

  append_tabledata(
    db$connection,
    table_id = db$get_table_id("FreeFieldNotes"),
    data_to_append = fieldnotes_to_upload %>%
    sf::st_as_sf(crs = 31370),
    characteristic_columns = characteristic_columns,
    verbose = TRUE
  )

}

# update all fields in the FreeFieldNotes,
#     looking them up via characteristic columns
update_fields_in_fieldnotes <- function(db, updated_fieldnotes) {

  # TODO continue here
  if (any(characteristic_columns) not in names(updated_fieldnotes)) ...

  create temptable

  concat update query
  execute

  drop temptable

}


# Sync Procedure, per database
synchronize_syncdb_with_freefieldnotes <- function(sdb) {
  # sdb <- "mnmgwdb"

  # load the status quo from SYNCDB
  freefieldnotes_statusquo <- query_freefieldnotes(mnmsyncdb)
  # observation: datetime in `log_creation` does not
  #   work well for filtering joins -> rounded explicitly


  # choose the current database connection
  mnmdb <- sourcedb_connections[[sdb]]

  # query source: user input from databases
  freefieldnotes_userdb <- query_freefieldnotes(mnmdb) %>%
    dplyr::mutate(
      archive_date = NA
    ) %>%
    dplyr::relocate(archive_date, .before = wkb_geometry)

  # mapview::mapview(freefieldnotes_userdb %>% sf::st_as_sf())

  # (1) distinguish existing and novel field notes
  existing_fieldnotes_userdb <- freefieldnotes_userdb %>%
    dplyr::semi_join(
      freefieldnotes_statusquo,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    )

  novel_fieldnotes <- freefieldnotes_userdb %>%
    dplyr::anti_join(
      freefieldnotes_statusquo,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    ) %>%
    head(10) # TODO remove testing limit

  # ==> upload novel notes
  upload_new_fieldnotes_append(
    mnmsyncdb,
    novel_fieldnotes
  )


  # (2) find deleted fieldnotes
  #     taking log_origindb into account to check which notes are removed
  #     -> only the source db can remove fieldnotes
  #     flagging an archive date to freefieldnotes on SYNCDB
  removed_fieldnotes <- freefieldnotes_statusquo %>%
    filter(log_origindb == sdb) %>%
    dplyr::anti_join(
      freefieldnotes_userdb,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    ) %>%
    select(!!!rlang::syms(characteristic_columns)) %>%
    dplyr::mutate(archive_date = date_today)
  # IMPORTANT: these removals must be reflected in
  #            all the other sdb's (see below)

  # ==> flag removed notes (by update)
  if (nrow(removed_fieldnotes) > 0) {
    update_fields_in_fieldnotes(mnmsyncdb, removed_fieldnotes)
  }

  # (3) update changed fieldnotes (bi-directional)
  #     by slicing the latest log_update
  finos_timestamp_comparison <- existing_fieldnotes_userdb %>%
    dplyr::inner_join(
      freefieldnotes_statusquo %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns)),
      suffix = c("", "_syncdb") # CRITICAL to get this right
    )

  # issue again: very small rounding differences can occur
  finos_with_user_updates <- finos_timestamp_comparison %>%
    filter((log_update - log_update_syncdb) > lubridate::seconds(0.0001)) %>%
    select(-log_update_syncdb)

  # # update from syncdb to userdb's will happen after all news are aggregated.
  # fino_newer_on_sync <- finos_timestamp_comparison %>%
  #   filter((log_update_syncdb - log_update_userdb) > lubridate::seconds(0.0001))

  # ==> reflect all updates from fieldnotes



} # /synchronize_syncdb_with_freefieldnotes


# TODO TODOs:
# - turn around: feedback to soruce-db's (must happen quick)
#     - while removing all FFNs with !is.na(archive_date)
# - update / reset table primary keys
# - test on `-dev` with actual fieldnote changes
