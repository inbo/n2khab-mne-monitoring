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
    database = glue::glue("{sdb}{suffix}")
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
    mutate(log_creation = lubridate::round_date(log_creation, "milliseconds")) %>%
    return()
}

# a common function to query and parse the fieldnotes, given a database
query_freefieldnotes <- function(db) {
  db$query_table("FreeFieldNotes") %>%
    dplyr::arrange(log_creation, log_creator) %>%
    ensure_nonna_crs() %>%
    # round_creation_date() %>% # OBSOLETE: rounded (truncated) on server side
    return()
}


# there... and back again: upload new fieldnotes,
# simply appending them to the existing data
upload_new_fieldnotes_append <- function(db, fieldnotes_to_upload) {

  db$set_sequence_key(
    "FreeFieldNotes",
    new_key_value = "max",
    sequence_label = "inbound.seq_fieldnote_id",
    verbose = FALSE
  )

  append_tabledata(
    db$connection,
    table_id = db$get_table_id("FreeFieldNotes"),
    data_to_append = fieldnotes_to_upload %>%
    sf::st_as_sf(crs = 31370),
    characteristic_columns = characteristic_columns,
    verbose = TRUE
  )

} # /upload_new_fieldnotes_append

# update all fields in the FreeFieldNotes,
#     looking them up via characteristic columns
update_fields_in_fieldnotes <- function(db, updated_fieldnotes) {

  # table pointers
  srctab <- "temp_upd_freefieldnotes"
  trgtab <- db$get_namestring("FreeFieldNotes")

  # lookup columns
  if (!all(characteristic_columns %in% names(updated_fieldnotes))) {
    stop("Cannot update: characteristic columns missing from update data.")
  }

  lookup_criteria <- unlist(lapply(
    c(characteristic_columns),
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))


  ### build update query
  # updated columns
  update_columns <- names(updated_fieldnotes)
  update_columns <- update_columns[!(update_columns %in% characteristic_columns)]
  ucolumnames <- unlist(lapply(
    update_columns,
    FUN = function(col) glue::glue("{col} = SRCTAB.{col}")
  ))


  # create temp table
  DBI::dbWriteTable(
    db$connection,
    name = srctab,
    value = updated_fieldnotes,
    overwrite = TRUE,
    temporary = TRUE
  )

  # concat update query
  update_string <- glue::glue("
    UPDATE {trgtab} AS TRGTAB
      SET
       {paste0(ucolumnames, collapse = ', ')}
      FROM {srctab} AS SRCTAB
      WHERE
       ({paste0(lookup_criteria, collapse = ') AND (')})
    ;")

  # execute update
  db$execute_sql(update_string, verbose = TRUE)

  # drop temptable
  db$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)

  return(invisible(NULL))
} # /update_fields_in_fieldnotes

# field notes which disappear from their source database
# will be removed from all other databases
# however, they remain archived in the syncdb table
remove_archived_fieldnotes_from_inputdbs <- function(finos_to_remove) {

  table_label <- "FreeFieldNotes"

  # ensure that the filtering is not skipped due to empty dataframe
  if (nrow(finos_to_remove) == 0) return(invisible(NULL))

  ### prepare deletion filter sting
  fino2rem <- finos_to_remove %>%
    select(!!!rlang::syms(characteristic_columns))

  # prepend name of column (SQL conditionals)
  for (charcol in characteristic_columns) {
    fino2rem[, charcol] <- lapply(
      fino2rem[, charcol],
      FUN = \(val) paste0(
        charcol, " = '", val, "'",
        sep = ""
      )
    )
  } # TODO this only covers varchar/date/"'" columns
  # fino2rem %>% glimpse

  # combine columns
  fino2rem <- fino2rem %>%
    tidyr::unite(
      all_filters_concatenated,
      tidyselect::all_of(characteristic_columns),
      sep = ") AND ("
    ) %>%
    pull(all_filters_concatenated)


  ### loop databases and delete
  for (sdb in sourcedb_labels) {

    ## select connection
    mnmdb <- sourcedb_connections[[sdb]]

    ## combine deletion query
    table_namestring <- mnmdb$get_namestring(table_label)

    deletion_string <- glue::glue("
      DELETE FROM ONLY {table_namestring}
      WHERE (({paste0(fino2rem, collapse = ')) \n\tOR ((')}))
      ;
    ")

    ## execute - DELETE!
    mnmdb$execute_sql(deletion_string, verbose = TRUE)
  }
} # /remove_archived_fieldnotes_from_inputdbs


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
    arrange(log_creation, log_update, fieldnote_id) %>%
    dplyr::mutate(
      archive_date = NA
    ) %>%
    dplyr::relocate(archive_date, .before = wkb_geometry)

  # mapview::mapview(freefieldnotes_userdb %>% sf::st_as_sf())

  ### (1) distinguish existing and novel field notes
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
    dplyr::select(-fieldnote_id) %>%
    dplyr::mutate(log_origindb = sdb) %>%
    head(10) # TODO remove testing limit

  # ==> upload novel notes
  upload_new_fieldnotes_append(
    mnmsyncdb,
    novel_fieldnotes
  )


  ### (2) find deleted fieldnotes
  #     taking log_origindb into account to check which notes are removed
  #     -> only the source db can remove fieldnotes
  #     flagging an archive date to freefieldnotes on SYNCDB
  removed_fieldnotes <- freefieldnotes_statusquo %>%
    filter(
      log_origindb == sdb,
      is.na(archive_date)
    ) %>%
    dplyr::anti_join(
      freefieldnotes_userdb,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
    ) %>%
    dplyr::select(!!!rlang::syms(characteristic_columns)) %>%
    dplyr::mutate(archive_date = date_today)
  # IMPORTANT: these removals must be reflected in
  #            all the other sdb's (see below)

  if (FALSE) {
    # guerilla testing
    removed_fieldnotes <- novel_fieldnotes %>%
      head(3) %>%
      dplyr::select(!!!rlang::syms(characteristic_columns)) %>%
      dplyr::mutate(archive_date = date_today)
  }

  ## handle deleted fieldnotes
  if (nrow(removed_fieldnotes) > 0) {

    # dump a copy to logs
    output_filename <- file.path(".", "logs", glue::glue(
        "{format(Sys.time(), '%Y%m%d%H%M')}_deleted_freefieldnotes_{sdb}.csv"
      ))
    message(glue::glue("
    [!!!] N={nrow(removed_fieldnotes)} notes REMOVED from {sdb};
      \tbackup dumped to {output_filename}.
    "))

    freefieldnotes_statusquo %>%
      dplyr::semi_join(
        removed_fieldnotes,
        by = dplyr::join_by(!!!rlang::syms(characteristic_columns))
      ) %>%
      readr::write_csv2(output_filename)

    # ==> flag removed notes (by update)
    update_fields_in_fieldnotes(mnmsyncdb, removed_fieldnotes)

    # delete them from other user-side databases
    remove_archived_fieldnotes_from_inputdbs(removed_fieldnotes)
  }


  ### (3) update changed fieldnotes (bi-directional)
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
