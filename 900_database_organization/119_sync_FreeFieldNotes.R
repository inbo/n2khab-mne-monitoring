#!/usr/bin/env Rscript


#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

require("magrittr") # for the `%>%`


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


# a flexible join with sensible defaults for FreeFieldNotes
characteristic_join_ffn <- function(
    data1,
    data2,
    join_function = dplyr::semi_join,
    ...
  ) {

  data1 %>%
    join_function(
      data2,
      by = dplyr::join_by(!!!rlang::syms(characteristic_columns)),
      ...
    ) %>%
    return()

} # /characteristic_join_ffn

### Sync Procedure, per database

# Step 1: user input assembled in syncdb
synchronize_syncdb_with_data_from_sources <- function(sdb) {
  # sdb <- "mnmgwdb"

  # load the status quo from SYNCDB
  freefieldnotes_statusquo <- query_freefieldnotes(mnmsyncdb)

  # choose the current database connection
  mnmdb <- sourcedb_connections[[sdb]]

  # query sources: user input from databases
  freefieldnotes_userdb <- query_freefieldnotes(mnmdb) %>%
    arrange(log_creation, log_update, fieldnote_id) %>%
    dplyr::mutate(
      archive_date = as.character(NA)
    ) %>%
    dplyr::relocate(archive_date, .before = wkb_geometry)

  # mapview::mapview(freefieldnotes_userdb %>% sf::st_as_sf())

  ### (1) distinguish existing and novel field notes
  existing_fieldnotes_userdb <- freefieldnotes_userdb %>%
    characteristic_join_ffn(freefieldnotes_statusquo)

  novel_fieldnotes <- freefieldnotes_userdb %>%
    characteristic_join_ffn(
      freefieldnotes_statusquo,
      join_function = dplyr::anti_join
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
  #     -> only the userdb can remove fieldnotes
  #     flagging an archive date to freefieldnotes on SYNCDB
  removed_fieldnotes <- freefieldnotes_statusquo %>%
    filter(
      log_origindb == sdb,
      is.na(archive_date)
    ) %>%
    characteristic_join_ffn(
      freefieldnotes_userdb,
      join_function = dplyr::anti_join
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
      characteristic_join_ffn(removed_fieldnotes) %>%
      readr::write_csv2(output_filename)

    # ==> flag removed notes (by update)
    update_fields_in_fieldnotes(mnmsyncdb, removed_fieldnotes)

    # delete them from other user-side databases
    remove_archived_fieldnotes_from_inputdbs(removed_fieldnotes)
  }


  ### (3) update changed fieldnotes
  #   one-directional: changes come from source_db's,
  #   determining latest updates by updating entries with more recent log_update
  #   this is independent of `log_origindb`: any database tool may
  #       change any note. If many databases changed in parallel,
  #       only the latest update will be kept.
  #
  #   distribution from syncdb to sourcedb's will
  #       happen after all news are aggregated.
  #
  finos_with_timestamp_differences <- existing_fieldnotes_userdb %>%
    characteristic_join_ffn(
      freefieldnotes_statusquo %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_syncdb") # CRITICAL to get this right
    ) %>%
    dplyr::filter_out(log_update_syncdb == log_update) %>%
    select(
      -archive_date,
      -fieldnote_id
    )

  # extract the news from user-side sourcedb's
  finos_with_user_updates <- finos_with_timestamp_differences %>%
    dplyr::filter(log_update > log_update_syncdb) %>%
    dplyr::select(-log_update_syncdb)

  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(finos_with_user_updates) > 0) {
    message(glue::glue("
    >>> Updating N={nrow(finos_with_user_updates)} FieldNotes from {sdb}.
    "))
    update_fields_in_fieldnotes(mnmsyncdb, finos_with_user_updates)
  }


} # /synchronize_syncdb_with_data_from_sources

# Step 2: distribute latest version to source databases
distribute_fieldnote_updates_to_sources <- function(sdb) {

  # load the status quo from SYNCDB
  freefieldnotes_statusquo <- query_freefieldnotes(mnmsyncdb) %>%
    dplyr::filter(is.na(archive_date)) %>%
    dplyr::select(-archive_date, -log_origindb, -fieldnote_id)

  mnmdb <- sourcedb_connections[[sdb]]
  freefieldnotes_userdb <- query_freefieldnotes(mnmdb)

  # (1) distribute novel notes
  novel_fieldnotes <- freefieldnotes_statusquo %>%
    characteristic_join_ffn(
      freefieldnotes_userdb,
      join_function = dplyr::anti_join
    )

  if (nrow(novel_fieldnotes) > 0) {
    upload_new_fieldnotes_append(
      mnmdb,
      novel_fieldnotes
    )
  }

  # (2) update existing notes
  updated_fieldnotes <- freefieldnotes_statusquo %>%
    characteristic_join_ffn(
      freefieldnotes_userdb %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_userdb")
    ) %>%
    filter(log_update > log_update_userdb) %>%
    select(
      -log_update_userdb
    )

  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(updated_fieldnotes) > 0) {
    message(glue::glue("
    >>> Updating N={nrow(updated_fieldnotes)} FieldNotes in {sdb}.
    "))
    update_fields_in_fieldnotes(mnmdb, updated_fieldnotes)
  }

}


#_______________________________________________________________________________
### Execution: loop databases

for (sdb in sourcedb_labels) {
  synchronize_syncdb_with_data_from_sources(sdb)
}

for (sdb in sourcedb_labels) {
  distribute_fieldnote_updates_to_sources(sdb)
}


# TODO TODOs:
# - update / reset table primary keys
#   - also make sure that `ogc_id` (and related seq's) are MAXed!
#   - e.g. by checking that the geometry updates
# - test on `-dev` with actual fieldnote changes
# - REVOKE before, GRANT after updates to avoid simultaneous writing

# NOTE:
# The approach above has limited coverage of simultaneous changes.
# Information may be lost if different endpoints trigger changes on the same
# day. For example, if between a backup and the consecutive sync action, both
# `loceval` (09:58) and `mnmsurfdb` (10:37) edit the same notes, then only the
# version with later timestamp (in this example: `mnmsurfdb`) will be kept.
