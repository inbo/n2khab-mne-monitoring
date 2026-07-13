#!/usr/bin/env Rscript

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

todays_date <- strftime(as.POSIXct(Sys.time()), "%Y%m%d%H%M%S")

message("________________________________________________________________")
message("<<<<< Syncing LocationInfos [all]. ")
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



## connect sync database
mnmsyncdb_mirror <- glue::glue("mnmsyncdb{suffix}")

mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsyncdb_mirror
)

message(glue::glue("\tconnected: psql {mnmsyncdb$shellstring}"))
update_cascade_mnmsyncdb <- parametrize_cascaded_update(mnmsyncdb)

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
#    \dp "inbound"."FreeFieldNotes"

# store user roles with write access
writeaccess_userroles <- list(
  "mnmgwdb" = "user_gwdb",
  "mnmsurfdb" = "user_surfdb",
  "loceval" = "user_loceval"
)

# Batch REVOKE or GRANT all permissions on FreeFieldNotes on all databases
batch_manage_infos_write_permissions <- function(verb = c("REVOKE", "GRANT")) {

  # check input: either REVOKE, or GRANT
  verb <- match.arg(verb)

  # loop databases
  for (sdb in sourcedb_labels) {

    mnmdb <- sourcedb_connections[[sdb]]
    role <- writeaccess_userroles[[sdb]]
    table_namestring <- mnmdb$get_namestring("FreeFieldNotes")

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

  message(glue::glue("\t[{verb}'d all access from LocationInfos on {suffix}.]"))


  # finalize
  if (verb == "REVOKE") {
    ## ensure that permissions are restored if the script fails.
    # does this count as a special type of recursion? ;)
    reg.finalizer(
      .GlobalEnv,
      function(e) batch_manage_infos_write_permissions("GRANT"),
      onexit = TRUE
    )
  }

  return(invisible(NULL))
} # /manage_write_permissions

batch_manage_infos_write_permissions("REVOKE")


## LocationInfos --------------------------------------------------------

characteristic_columns <- c(
  "grts_address"
)

## logging columns WILL be updated
# logging_columns <- c("log_update")

# columns which should not get updated
ignored_columns <- c("landowner")

#_______________________________________________________________________________
### helper functions


# a common function to query and parse the LocationInfos, given a database
query_infos <- function(db) {
  infos <- db$query_table("LocationInfos") %>%
    dplyr::arrange(log_creation, log_creator)

  # prevent data type join confilcts
  if (nrow(infos) == 0) {
    infos %<>%
      dplyr::mutate_at(
        dplyr::vars(log_creation, log_update),
        as.character
      )
  }

  infos %>%
    return()
}



# a flexible join with sensible defaults for LocationInfos
characteristic_join_infos <- function(
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

} # /characteristic_join_infos


# update all fields in the LocationInfos,
#     looking them up via characteristic columns
update_fields_in_infos <- function(db, updated_infos) {

  # table pointers
  srctab <- "temp_upd_locationinfos"
  trgtab <- db$get_namestring("LocationInfos")

  # lookup columns
  if (!all(characteristic_columns %in% names(updated_infos))) {
    stop("Cannot update: characteristic columns missing from update data.")
  }

  lookup_criteria <- unlist(lapply(
    c(characteristic_columns),
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))


  ### build update query
  # updated columns; including logging columns!
  update_columns <- names(updated_infos)
  update_columns <- update_columns[!(update_columns %in% characteristic_columns)]
  update_columns <- update_columns[!(update_columns %in% ignored_columns)]
  ucolumnamed <- unlist(lapply(
    update_columns,
    FUN = function(col) glue::glue("{col} = SRCTAB.{col}")
  ))

  timestamp_types <- c(
    "log_creation" = "timestamp(3)",
    "log_update" = "timestamp(3)"
  )
  timestamp_types <- timestamp_types[
    names(timestamp_types) %in% names(updated_infos)
  ]

  # create temp table - non-spatial table solution
  DBI::dbWriteTable(
    db$connection,
    name = srctab,
    value = updated_infos,
    overwrite = TRUE,
    temporary = TRUE,
    field.types = timestamp_types
  )


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
} # /update_fields_in_infos


### Sync Procedure, per database

# Step 1: user input assembled in syncdb
synchronize_syncdb_with_data_from_sources <- function(sdb) {
  # sdb <- "mnmsurfdb"
  # sdb <- "mnmgwdb"
  # sdb <- "loceval"

  # load the status quo from SYNCDB
  infos_statusquo <- query_infos(mnmsyncdb)
  # %>% arrange(log_creation) %>% head(3)

  # choose the current database connection
  mnmdb <- sourcedb_connections[[sdb]]
  # mnmdb$shellstring

  # query sources: user input from databases
  infos_userdb <- query_infos(mnmdb) %>%
    select(-location_id) %>%
    dplyr::arrange(log_creation, log_update, grts_address)



  ### (1) there are novel locations not previously seen on SYNCDB
  # this script only needs to handle existing locations
  # which are fixed per database
  # however, there can be REP updates and new locations in the
  # peer databases, which should cause an INSERT to mnmsyncdb

  new_locations_for_syncdb <- infos_userdb %>%
    characteristic_join_infos(
      infos_statusquo,
      join_function = dplyr::anti_join
    )


  mnmsyncdb_lookup <- update_cascade_mnmsyncdb(
    table_label = "LocationInfos",
    new_data = new_locations_for_syncdb,
    index_columns = c("locationinfo_id"),
    characteristic_columns = characteristic_columns,
    tabula_rasa = FALSE,
    verbose = TRUE
  )

  ### (2) find deleted infos
  # there should never be deleted locations;
  # even if they are removed from the source databases,
  # we keep storing LocationInfos


  ### (3) update changed infos
  #   one-directional: changes come from source_db's,
  #   determining latest updates by updating entries with more recent log_update
  #
  #   distribution from syncdb to sourcedb's will
  #       happen after all news are aggregated.
  #
  infos_with_timestamp_differences <- infos_userdb %>%
    characteristic_join_infos(
      infos_statusquo %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_syncdb") # CRITICAL to get this right
    ) %>%
    dplyr::filter_out(log_update_syncdb == log_update) %>%
    select(
      -locationinfo_id
    )

  # extract the news from user-side sourcedb's
  infos_with_user_updates <- infos_with_timestamp_differences %>%
    dplyr::filter(log_update > log_update_syncdb) %>%
    dplyr::select(-log_update_syncdb)

  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(infos_with_user_updates) > 0) {
    message(glue::glue("
    \t<<< Syncing N={nrow(infos_with_user_updates)} changed LocationInfos from {sdb}.
    "))
    update_fields_in_infos(mnmsyncdb, infos_with_user_updates)
  }


} # /synchronize_syncdb_with_data_from_sources



# Step 2: distribute latest version to source databases
distribute_infos_updates_to_sources <- function(sdb) {

  # load the status quo from SYNCDB
  infos_statusquo <- query_infos(mnmsyncdb) %>%
    dplyr::select(-locationinfo_id)

  mnmdb <- sourcedb_connections[[sdb]]
  infos_userdb <- query_infos(mnmdb)

  # (2) update existing infos
  updated_infos <- infos_statusquo %>%
    characteristic_join_infos(
      infos_userdb %>%
        dplyr::select(!!!rlang::syms(c(characteristic_columns, "log_update"))),
      join_function = dplyr::inner_join,
      suffix = c("", "_userdb")
    ) %>%
    dplyr::filter(log_update > log_update_userdb) %>%
    dplyr::select(
      tidyselect::any_of(names(infos_userdb))
    )


  # ==> reflect all decentral updates on the SYNCDB
  if (nrow(updated_infos) > 0) {
    message(glue::glue("
    \t>>> Updating N={nrow(updated_infos)} changed infos on {sdb}.
    "))
    update_fields_in_infos(mnmdb, updated_infos)
  }

} # /distribute_infos_updates_to_sources


#_______________________________________________________________________________
### Execution: loop databases

for (sdb in sourcedb_labels) {
  synchronize_syncdb_with_data_from_sources(sdb)
}

for (sdb in sourcedb_labels) {
  distribute_infos_updates_to_sources(sdb)
}

# restore permissions
batch_manage_infos_write_permissions("GRANT")

# TODO TODOs:
# - update / reset table primary keys
#   - also make sure that `ogc_id` (and related seq's) are MAXed!
#   - e.g. by checking that the geometry updates

# NOTE:
# The approach above has limited coverage of simultaneous changes.
# Information may be lost if different endpoints trigger changes on the same
# day. For example, if between a backup and the consecutive sync action, both
# `loceval` (09:58) and `mnmsurfdb` (10:37) edit the same infos, then only the
# version with later timestamp (in this example: `mnmsurfdb`) will be kept.

message("________________________________________________________________")
message(" >>>>> Finished syncing Infos [all]. ")
message("________________________________________________________________")
