#!/usr/bin/env Rscript


#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

require("magrittr") %>% suppressPackageStartupMessages() # for the `%>%`


date_today <- as.integer(format(Sys.time(), "%Y%m%d"))

message("________________________________________________________________")
message("<<<<< Syncing Trails [all]. ")
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
# suffix <- "-dev"



## connect sync database
mnmsyncdb_mirror <- glue::glue("mnmsyncdb{suffix}")

mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsyncdb_mirror
)

message(glue::glue("\tconnected: psql {mnmsyncdb$shellstring}"))


## connect source databases
sourcedb_labels <- c("loceval", "mnmgwdb", "mnmsurfdb")
sourcedb_connections <- list()

for (sdb in sourcedb_labels) {
  sourcedb_connections[[sdb]] <- connect_mnm_database(
    config_filepath = config_filepath,
    database = glue::glue("{sdb}{suffix}")
  )
  message(glue::glue("\tconnected: psql {sourcedb_connections[[sdb]]$shellstring}"))

}


## Permission Safety --------------------------------------------------------------
# to avoid parallel work during the update procedure,
# permissions are temporarily revoked, and restored afterwards.
#    \dp "inbound"."Trails"

# store user roles with write access
writeaccess_userroles <- list(
  "mnmgwdb" = "user_gwdb",
  "mnmsurfdb" = "user_surfdb",
  "loceval" = "user_loceval"
)

# Batch REVOKE or GRANT all permissions on Trails on all databases
batch_manage_ffn_write_permissions <- function(verb = c("REVOKE", "GRANT")) {

  # check input: either REVOKE, or GRANT
  verb <- match.arg(verb)

  # loop databases
  for (sdb in sourcedb_labels) {

    mnmdb <- sourcedb_connections[[sdb]]
    role <- writeaccess_userroles[[sdb]]
    table_namestring <- mnmdb$get_namestring("Trails")

    # extra syntactical spice
    preposition <- dplyr::case_when(
      verb == "REVOKE" ~ "FROM",
      verb == "GRANT" ~ "TO"
    )

    # loop critical actions
    for (action in c("SELECT", "INSERT", "UPDATE", "DELETE")) {

      # stitch the query
      permission_query <- glue::glue(
        "{verb} {action} ON {table_namestring} {preposition} {role};"
      )

      # execute the query
      mnmdb$execute_sql(permission_query, verbose = FALSE)
    } # /loop actions

  } # /loop databases

  message(glue::glue("\t[{verb}'d all access from Trails on {suffix}.]"))


  # finalize
  if (verb == "REVOKE") {
    ## ensure that permissions are restored if the script fails.
    # does this count as a special type of recursion? ;)
    reg.finalizer(
      .GlobalEnv,
      function(e) batch_manage_ffn_write_permissions("GRANT"),
      onexit = TRUE
    )
  }

  return(invisible(NULL))
} # /manage_write_permissions

batch_manage_ffn_write_permissions("REVOKE")



## Trails --------------------------------------------------------------

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


# a common function to query and parse the trails, given a database
query_trails <- function(db) {
  trails <- db$query_table("Trails") %>%
    dplyr::arrange(log_creation, log_creator) %>%
    ensure_nonna_crs()
    # round_creation_date() %>% # OBSOLETE: rounded (truncated) on server side

  # prevent data type join confilcts
  if (nrow(trails) == 0) {
    trails %<>%
      dplyr::mutate_at(
        dplyr::vars(log_creation, log_update),
        as.character
      )
  }

  trails %>%
    return()
}


# there... and back again: upload new trails,
# simply appending them to the existing data
upload_new_trails_append <- function(db, trails_to_upload) {

  db$set_sequence_key(
    "Trails",
    new_key_value = "max",
    sequence_label = "inbound.seq_trail_id",
    verbose = FALSE
  )

#  append_tabledata(
#    db$connection,
#    table_id = db$get_table_id("Trails"),
#    data_to_append = trails_to_upload %>%
#    sf::st_as_sf(crs = 31370),
#    characteristic_columns = characteristic_columns,
#    verbose = TRUE

  # the clumsy way: direct insert
  upload_sf <- trails_to_upload %>% sf::st_as_sf(crs = 31370)
  sf::st_geometry(upload_sf) <- "wkb_geometry"

  db$insert_data(
    table_label = "Trails",
    upload_data = upload_sf
  )

} # /upload_new_trails_append

# update all fields in the Trails,
#     looking them up via characteristic columns
update_fields_in_trails <- function(db, updated_trails) {

  # table pointers
  srctab <- "temp_upd_trails"
  trgtab <- db$get_namestring("Trails")

  # lookup columns
  if (!all(characteristic_columns %in% names(updated_trails))) {
    stop("Cannot update: characteristic columns missing from update data.")
  }

  lookup_criteria <- unlist(lapply(
    c(characteristic_columns),
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))


  ### build update query
  # updated columns
  update_columns <- names(updated_trails)
  update_columns <- update_columns[!(update_columns %in% characteristic_columns)]
  ucolumnamed <- unlist(lapply(
    update_columns,
    FUN = function(col) glue::glue("{col} = SRCTAB.{col}")
  ))

  timestamp_types <- c(
    "log_creation" = "timestamp(3)",
    "log_update" = "timestamp(3)"
  )
  timestamp_types <- timestamp_types[
    names(timestamp_types) %in% names(updated_trails)
  ]

  # create temp table
  if ("wkb_geometry" %in% update_columns) {
    # well-known-binary solution
    rs <- sf::st_write(
      updated_trails,
      db$connection,
      srctab,
      row.names = FALSE,
      delete_layer = TRUE, # "overwrite"
      factorsAsCharacter = TRUE,
      binary = TRUE,
      temporary = TRUE,
      field.types = timestamp_types
    )
  } else {
    # general solution
    DBI::dbWriteTable(
      db$connection,
      name = srctab,
      value = updated_trails,
      overwrite = TRUE,
      temporary = TRUE,
      field.types = timestamp_types
    )
  }


  # concat update query
  update_string <- glue::glue("
    UPDATE {trgtab} AS TRGTAB
      SET
       {paste0(ucolumnamed, collapse = ', ')}
      FROM {srctab} AS SRCTAB
      WHERE
       ({paste0(lookup_criteria, collapse = ') AND (')})
    ;")

  # execute update
  db$execute_sql(update_string, verbose = FALSE)

  # drop temptable
  db$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)

  return(invisible(NULL))
} # /update_fields_in_trails


# field notes which disappear from their source database
# will be removed from all other databases
# however, they remain archived in the syncdb table
remove_archived_trails_from_inputdbs <- function(finos_to_remove) {

  table_label <- "Trails"

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
} # /remove_archived_trails_from_inputdbs


# a flexible join with sensible defaults for Trails
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
  # sdb <- "mnmsurfdb"
  # sdb <- "mnmgwdb"
  # sdb <- "loceval"

  # load the status quo from SYNCDB
  trails_statusquo <- query_trails(mnmsyncdb)
  # %>% arrange(log_creation) %>% head(3)

  # choose the current database connection
  mnmdb <- sourcedb_connections[[sdb]]
  # mnmdb$shellstring

  # query sources: user input from databases
  trails_userdb <- query_trails(mnmdb) %>%
    dplyr::arrange(log_creation, log_update, trail_id) %>%
    dplyr::mutate(
      archive_date = as.character(NA)
    ) %>%
    dplyr::relocate(archive_date, .before = wkb_geometry)
    # %>% arrange(log_creation) %>% head(3)


  # test3_statusquo <- trails_statusquo %>%
  #   arrange(log_creation) %>%
  #   select(starts_with("log_")) %>%
  #   head(3)
  # test3_statusquo %>%
  #   t() %>% knitr::kable()

  # test3_userdb <- trails_userdb %>%
  #   arrange(log_creation) %>%
  #   select(starts_with("log_")) %>%
  #   head(3)
  # test3_userdb %>%
  #   t() %>% knitr::kable()

  # test <- test3_userdb %>%
  #   characteristic_join_ffn(test3_statusquo)

  # test3_userdb %>% pull(log_creation) %>% knitr::kable()
  # test3_statusquo %>% pull(log_creation) %>% knitr::kable()

  # test3_userdb %>%
  #   semi_join(
  #     test3_statusquo,
  #     by = dplyr::join_by(log_creator, log_creation),
  #   )


  # mapview::mapview(trails_userdb %>% sf::st_as_sf())
  # trails_userdb %>% arrange(desc(log_update))

  ### (1) distinguish existing and novel field notes
  existing_trails_userdb <- trails_userdb %>%
    characteristic_join_ffn(trails_statusquo)

  novel_trails <- trails_userdb %>%
    characteristic_join_ffn(
      trails_statusquo,
      join_function = dplyr::anti_join
    ) %>%
    dplyr::select(-trail_id) %>%
    dplyr::mutate(log_origindb = sdb)

  # ==> upload novel notes
  if (nrow(novel_trails) > 0) {
    message(glue::glue("
    \t<<< Retrieving N={nrow(novel_trails)} novel Trails entered by {sdb}.
    "))

    upload_new_trails_append(
      mnmsyncdb,
      novel_trails
    )
  }


  ### (2) find deleted trails
  #     taking log_origindb into account to check which notes are removed
  #     -> only the userdb can remove trails
  #     flagging an archive date to trails on SYNCDB
  removed_trails <- trails_statusquo %>%
    filter(
      log_origindb == sdb,
      is.na(archive_date)
    ) %>%
    characteristic_join_ffn(
      trails_userdb,
      join_function = dplyr::anti_join
    ) %>%
    dplyr::select(!!!rlang::syms(characteristic_columns)) %>%
    dplyr::mutate(archive_date = date_today)
  # IMPORTANT: these removals must be reflected in
  #            all the other sdb's (see below)

  ## handle deleted trails
  if (nrow(removed_trails) > 0) {

    # dump a copy to logs
    output_filename <- file.path(".", "logs", glue::glue(
        "{format(Sys.time(), '%Y%m%d%H%M')}_deleted_trails_{sdb}.csv"
      ))
    message(glue::glue("
    \t[><] N={nrow(removed_trails)} notes REMOVED from {sdb};
    \t\tbackup dumped to {output_filename}.
    "))

    trails_statusquo %>%
      characteristic_join_ffn(removed_trails) %>%
      readr::write_csv2(output_filename)

    # ==> flag removed notes (by update)
    update_fields_in_trails(mnmsyncdb, removed_trails)

    # delete them from other user-side databases
    remove_archived_trails_from_inputdbs(removed_trails)
  }


  ### (3) update changed trails
  #   one-directional: changes come from source_db's,
  #   determining latest updates by updating entries with more recent log_update
  #   this is independent of `log_origindb`: any database tool may
  #       change any note. If many databases changed in parallel,
  #       only the latest update will be kept.
  #
  #   distribution from syncdb to sourcedb's will
  #       happen after all news are aggregated.
  #
  finos_with_timestamp_differences <- existing_trails_userdb %>%
    characteristic_join_ffn(
      trails_statusquo %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_syncdb") # CRITICAL to get this right
    ) %>%
    dplyr::filter_out(log_update_syncdb == log_update) %>%
    select(
      -archive_date,
      -trail_id
    )

  # extract the news from user-side sourcedb's
  finos_with_user_updates <- finos_with_timestamp_differences %>%
    dplyr::filter(log_update > log_update_syncdb) %>%
    dplyr::select(-log_update_syncdb)

  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(finos_with_user_updates) > 0) {
    message(glue::glue("
    \t<<< Syncing N={nrow(finos_with_user_updates)} changed Trails from {sdb}.
    "))
    update_fields_in_trails(mnmsyncdb, finos_with_user_updates)
  }


} # /synchronize_syncdb_with_data_from_sources

# Step 2: distribute latest version to source databases
distribute_trails_updates_to_sources <- function(sdb) {

  # load the status quo from SYNCDB
  trails_statusquo <- query_trails(mnmsyncdb) %>%
    dplyr::filter(is.na(archive_date)) %>%
    dplyr::select(-archive_date, -log_origindb, -trail_id)

  mnmdb <- sourcedb_connections[[sdb]]
  trails_userdb <- query_trails(mnmdb)


  # (1) distribute novel notes
  novel_trails <- trails_statusquo %>%
    characteristic_join_ffn(
      trails_userdb,
      join_function = dplyr::anti_join
    )

  if (nrow(novel_trails) > 0) {
    message(glue::glue("
    \t>>> Distributing N={nrow(novel_trails)} novel Trails to {sdb}.
    "))

    upload_new_trails_append(
      mnmdb,
      novel_trails
    )
  }

  # trails_statusquo %>%
  #   count(!!!rlang::syms(characteristic_columns)) %>%
  #   arrange(-n)

  # (2) update existing notes
  updated_trails <- trails_statusquo %>%
    characteristic_join_ffn(
      trails_userdb %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_userdb")
    ) %>%
    filter(log_update > log_update_userdb) %>%
    select(
      -log_update_userdb
    )

  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(updated_trails) > 0) {
    message(glue::glue("
    \t<<< Updating N={nrow(updated_trails)} changed Trails on {sdb}.
    "))
    update_fields_in_trails(mnmdb, updated_trails)
  }

} # /distribute_trails_updates_to_sources


#_______________________________________________________________________________
### Execution: loop databases

for (sdb in sourcedb_labels) {
  synchronize_syncdb_with_data_from_sources(sdb)
}

for (sdb in sourcedb_labels) {
  distribute_trails_updates_to_sources(sdb)
}

# restore permissions
batch_manage_ffn_write_permissions("GRANT")

# TODO TODOs:
# - update / reset table primary keys
#   - also make sure that `ogc_id` (and related seq's) are MAXed!
#   - e.g. by checking that the geometry updates

# NOTE:
# The approach above has limited coverage of simultaneous changes.
# Information may be lost if different endpoints trigger changes on the same
# day. For example, if between a backup and the consecutive sync action, both
# `loceval` (09:58) and `mnmsurfdb` (10:37) edit the same notes, then only the
# version with later timestamp (in this example: `mnmsurfdb`) will be kept.

message("________________________________________________________________")
message(" >>>>> Finished syncing Trails [all]. ")
message("________________________________________________________________")
