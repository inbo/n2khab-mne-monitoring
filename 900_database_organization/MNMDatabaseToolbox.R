#_______________________________________________________________________________
# common commands

# .libPaths("/data/R/library")
# SET search_path TO public,"metadata","outbound","inbound","archive";

#_______________________________________________________________________________
# LIBRARIES

load_libraries <- function(libs) {
  load_lib <- function(...) {
    suppressPackageStartupMessages(library(...))
  }
  sapply(unique(libs), load_lib, character.only = TRUE)
  return(invisible(NULL))
}

poc_common_libraries <- c(
  "dplyr",
  "tidyr",
  "stringr",
  "purrr",
  "lubridate",
  "googledrive",
  "readr",
  "rprojroot",
  "sf",
  "terra",
  "n2khab"
)
load_poc_common_libraries <- function(
  ) load_libraries(poc_common_libraries)
# load_poc_common_libraries()

database_interaction_libraries <- c(
  "configr",
  "keyring",
  "DBI",
  "RPostgres",
  "dplyr",
  "glue"
)
load_database_interaction_libraries <- function(
  ) load_libraries(database_interaction_libraries)
# load_database_interaction_libraries()

spatial_data_handling_libraries <- c(
  "sf",
  "terra"
)
load_spatial_data_handling_libraries <- function(
  ) load_libraries(spatial_data_handling_libraries)
# load_spatial_data_handling_libraries()

inbo_libraries <- c(
  "n2khab",
  "inbospatial",
  "inbodb"
)
load_inbo_libraries <- function(
  ) load_libraries(inbo_libraries)
# load_inbo_libraries()


#_______________________________________________________________________________
# POC DATA AND CODE

load_poc_rdata <- function(data_basepath = "./data", reload = FALSE) {

  # Setup for googledrive authentication. Set the appropriate env vars in
  # .Renviron and make sure you ran drive_auth() interactively with these settings
  # for the first run (or to renew an expired Oauth token).
  # See ?gargle::gargle_options for more information.
  if (Sys.getenv("GARGLE_OAUTH_EMAIL") != "") {
    options(gargle_oauth_email = Sys.getenv("GARGLE_OAUTH_EMAIL"))
  }
  if (Sys.getenv("GARGLE_OAUTH_CACHE") != "") {
    options(gargle_oauth_cache = Sys.getenv("GARGLE_OAUTH_CACHE"))
  }

  # Download and load R objects from the POC into global environment
  # reload <- FALSE # in this one, we normally reload.
  poc_rdata_path <- file.path(data_basepath, "objects_panflpan5.RData")
  if (reload || !file.exists(poc_rdata_path)){

    # copy the old file
    if (file.exists(poc_rdata_path)) {
      this_date <- format(Sys.time(), "%Y%m%d")
      backup_path <- file.path(data_basepath, glue::glue("objects_panflpan5_{this_date}.bak"))
      file.copy(from = poc_rdata_path, to = backup_path, overwrite = TRUE)
    }

    drive_download(
      as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"),
      path = poc_rdata_path,
      overwrite = reload
    )
  }
  load(poc_rdata_path)

  versions_required <- c(versions_required, "habitatmap_2024_v99_interim")
  verify_n2khab_data(n2khab_data_checksums_reference, versions_required)
}


load_poc_code_snippets <- function(base_path = NA) {

  if (is.na(base_path)) {
    base_path <- rprojroot::find_root(is_git_root)
  }

  source(file.path(base_path, "020_fieldwork_organization/R/grts.R"))
  source(file.path(base_path, "020_fieldwork_organization/R/misc.R"))

  invisible(capture.output(source("050_snippet_selection.R")))
  source("051_snippet_transformation_code.R")

  stopifnot(
    "NOT FOUND: snip snap >> `grts_mh_index`" = exists("grts_mh_index")
  )

  stopifnot(
    "NOT FOUND: snip snap >> `scheme_moco_ps_stratum_targetpanel_spsamples`" =
      exists("scheme_moco_ps_stratum_targetpanel_spsamples")
  )

  stopifnot(
    "NOT FOUND: snip snap >> `stratum_schemepstargetpanel_spsamples`" =
      exists("stratum_schemepstargetpanel_spsamples")
  )

  stopifnot(
    "NOT FOUND: snip snap >> `units_cell_polygon`" =
      exists("units_cell_polygon")
  )

  stopifnot(
    "NOT FOUND: RData >> `activities`" =
      exists("activities")
  )

  stopifnot(
    "NOT FOUND: RData >> `activity_sequences`" =
      exists("activity_sequences")
  )

  stopifnot(
    "NOT FOUND: RData >> `n2khab_strata`" =
      exists("n2khab_strata")
  )

  stopifnot(
    "snip snap >> `orthophoto grts` not found" =
      exists("orthophoto_2025_type_grts")
  )

  # fieldwork calendar
  stopifnot(
    "NOT FOUND: snip snap >> `fieldwork_2025_prioritization_by_stratum`" =
      exists("fieldwork_2025_prioritization_by_stratum")
  )

  # replacements
  stopifnot(
    "NOT FOUND: snip snap >> `stratum_schemepstargetpanel_spsamples_terr_replacementcells`" =
      exists("stratum_schemepstargetpanel_spsamples_terr_replacementcells")
  )

}


#_______________________________________________________________________________
# MISC

is.scalar.na <- function(checkvar) is.atomic(checkvar) && (length(checkvar) == 1) && is.na(checkvar)


lookup_join <- function(.data, lookup_tbl, join_column){
  joined_tbl <- .data %>%
    left_join(
      lookup_tbl,
      by = join_by(!!enquo(join_column))
      # relationship = "many-to-one",
      # unmatched = "drop"
    ) %>%
  select(-!!enquo(join_column))

  return(joined_tbl)

}


#_______________________________________________________________________________
# SQL CONVENIENCE

execute_sql <- function(mnmdb, sql_command, verbose = TRUE) {
  # a rather trivial wrapper for dbExecute
  # which doesn't even work for multi-commands :/

  if (verbose) {
    message(sql_command)
  }

  stopifnot("DBI" = require("DBI"))

  rs <- DBI::dbExecute(mnmdb$connection, sql_command)

  if (verbose) {
    message("done.")
  }

  return(invisible(rs))

}


# TODO: option to drop; but mind cascading

# this function loads the content of a table, and then uploads only
# the new rows which are not already present (as judged by some
# characteristic columns).
append_tabledata <- function(
    mnmdb,
    db_table,
    data_to_append,
    characteristic_columns = NA
  ) {
  content <- DBI::dbReadTable(mnmdb$connection, db_table)
  # head(content)

  if (any(is.na(characteristic_columns))) {
    # ... or just take all columns
    characteristic_columns <- names(data_to_append)
  }

  # refcol <- enquo(characteristic_columns)
  existing <- content %>% select(!!!characteristic_columns)
  to_upload <- data_to_append %>%
    anti_join( existing, join_by(!!!characteristic_columns)
  )

  rs <- DBI::dbWriteTable(
    mnmdb$connection,
    db_table,
    to_upload,
    overwrite = FALSE,
    append = TRUE
  )
  # res <- DBI::dbFetch(rs)
  # DBI::dbClearResult(rs)

  message(sprintf(
    "%s: %i rows uploaded, %i/%i existing judging by '%s'.",
    toString(db_table),
    nrow(to_upload),
    nrow(existing),
    nrow(data_to_append),
    paste0(characteristic_columns, collapse = ", ")
  ))
  return(invisible(rs))

} #/ append_tabledata


upload_and_lookup <- function(
    mnmdb,
    ...,
    characteristic_columns,
    index_columns
  ) {

  append_tabledata(
    mnmdb$connection,
    ...,
    characteristic_columns
  )

  lookup <- mnmdb$query_columns(
    table_label,
    c(characteristic_columns, index_columns)
  )

  return(lookup)
}


#_______________________________________________________________________________
# LOOKUP RESTORATION

# procedure to loop through a table
# which is linked to "Locations" via `location_id`
# and restore the correct id.
# This is necessary because previously assembled data is
#   in some cases retained, but
#   would loose links to the pruned "Locations" after rearrangement.
restore_location_id_by_grts <- function(
      mnmdb,
      table_label,
      retain_log = FALSE,
      verbose = FALSE
    ) {


  # know table relations to get the pk
  table_relations <- mnmdb$table_relations %>%
    filter(relation_table == tolower(table_label))

  pk <- mnmdb$get_primary_key(table_label)

  target_namestring <- mnmdb$get_namestring(table_label)

  # query the status quo
  location_lookup <- mnmdb$query_tbl("Locations") %>%
    select(grts_address, location_id)

  # optional: store and retain "log_" columns
  # TODO (though I fear this did not work)
  target_cols <- c(pk, "grts_address")
  if (retain_log) {
    target_cols <- c(pk, "grts_address", "log_user", "log_update")
  }

  target_lookup <- mnmdb$query_tbl(table_label) %>%
    select(!!!target_cols)

  key_replacement <- target_lookup %>%
    left_join(
      location_lookup,
      by = join_by(grts_address),
      relationship = "many-to-one"
    )


  ### UPDATE the location-related table

  # repl_rownr <- 10 # testing
  get_update_row_string <- function(repl_rownr){

    dep_pk_val <- key_replacement[repl_rownr, pk]
    val <- key_replacement[repl_rownr, "location_id"]
    if (is.na(val)) {
      val <- "NULL"
    }

    if (retain_log) {
      log_user <- key_replacement[[repl_rownr, "log_user"]]
      log_update <- key_replacement[[repl_rownr, "log_update"]]
      logstr <- glue::glue(",
        log_user = '{log_user}',
        log_update = '{toString(log_update)}'
      ")
    } else {
      logstr <- ""
    }

    update_string <- glue::glue("
      UPDATE {target_namestring}
        SET location_id = {val} {logstr}
      WHERE {pk} = {dep_pk_val}
      ;
    ")

    return(update_string)
  }

  # concatenate update rows
  update_command <- lapply(
    1:nrow(key_replacement),
    FUN = get_update_row_string
  )

  # spin up a progress bar
  if (verbose) {
    pb <- txtProgressBar(
      min = 0, max = nrow(key_replacement),
      initial = 0, style = 1
    )
  }

  # execute the update commands.
  for (repl_rownr in 1:nrow(key_replacement)) {
    if (verbose) setTxtProgressBar(pb, repl_rownr)
    cmd <- update_command[[repl_rownr]]
    mnmdb$execute_sql(cmd, verbose = FALSE)
  }

  if (verbose) close(pb) # close the progress bar

  # TODO this is sluggish, of course; I would rather prefer a combined UPDATE.

} # /restore_location_id_by_grts


#_______________________________________________________________________________
# UPDATE - CASCADE

#' Update table content and cascade all key changes to dependent tables
#'
#' Updates the content of a data table in a relatively safe manner
#' by recursing the database structure and updating foreign keys in other
#' tables which link to the changed data.
#' Cascading changes is based on characteristic columns that serve as
#' keys for joining old and new data.
#' "Safe manner" means that dumps and backups are written to text files
#' along the way.
#' The original intention of this function was to provide tooling for
#' reloading backed up content of a previous data version, or for copying
#' data from one connection to the other.
#'        hint: use keyring::key_set("DBPassword", "db_user_password") to
#'        store a connection password prior to execution.
#'
#' @param config_filepath the path to the config file
#' @param working_dbname the target database name
#' @param table_key the table to be changed
#' @param new_data a data frame or tibble with the new data
#' @param profile config section header (configs with multiple connection
#'        settings)
#' @param dbstructure_folder the folder in which to find the
#'        database structure csv collection
#' @param characteristic_columns a subset of columns of the data table
#'        by which old and new data can be uniquely identified and joined;
#'        refers to the new data
#' @param rename_characteristics link columns with different names by
#'        renaming them in new_data
#' @param db_connection an existing database connection, optionally passed
#'        to prevent repeated connection in scripts
#' @param verbose provides extra prose on the way, in case you need it
#'
#' @examples
#' \dontrun{
#'    working_dbname <- "monkey_business"
#'    dbstructure_folder <- "db_structure"
#'    connection_profile <- "monkey-connections"
#'    config_filepath <- file.path("./monkey_server.conf")
#'    # keyring::key_set("DBPassword", "db_user_password")
#'
#'    test_table <- "LocationCalendar"
#'    new_data <- dplyr::tbl(
#'        source_connection,
#'        DBI::Id(schema = "outbound", table = test_table)
#'      ) %>% collect(),
#'    characteristic_columns = \
#'      c("scheme", "stratum", "grts_address", "column_newname")
#'
#'    update_datatable_and_dependent_keys(
#'      config_filepath = config_filepath,
#'      working_dbname = working_dbname,
#'      table_key = test_table,
#'      new_data = new_data,
#'      profile = connection_profile,
#'      dbstructure_folder = dbstructure_folder,
#'      characteristic_columns = characteristic_columns,
#'      rename_characteristics = c(column_oldname = "column_newname")
#'      verbose = TRUE
#'    )
#' }
#'
update_datatable_and_dependent_keys <- function(
    config_filepath,
    working_dbname,
    table_key,
    new_data,
    profile = NULL,
    dbstructure_folder = NULL,
    characteristic_columns = NULL,
    rename_characteristics = NULL,
    db_connection = NULL,
    skip_sequence_reset = FALSE,
    verbose = TRUE
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("RPostgres" = require("RPostgres"))
  stopifnot("glue" = require("glue"))

  # establish a database connection
  if (is.null(db_connection)) {
    db_target <- connect_database_configfile(
      config_filepath,
      database = working_dbname,
      profile = profile
    )
  } else {
    # ... unless it is given for repeated use
    db_target <- db_connection
  }

  if (is.null(dbstructure_folder)) {
    dbstructure_folder <- "db_structure"
  }

  schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, schema, geometry, excluded)

  # These are clumsy, temporary, provisional helpers.
  # But, hey, there will be time later.
  get_schema <- function(table_label) {
    return(schemas %>%
      filter(table == table_label) %>%
      pull(schema)
    )
  }
  get_namestring <- function(table_label) glue::glue('"{get_schema(table_label)}"."{table_label}"')
  get_tableid <- function(table_label) DBI::Id(schema = get_schema(table_label), table = table_label)


  ### (1) dump all data, for safety
  now <- format(Sys.time(), "%Y%m%d%H%M")
  dump_all(
    here::here("dumps", glue::glue("safedump_{working_dbname}_{now}.sql")),
    config_filepath = config_filepath,
    database = working_dbname,
    profile = "dumpall",
    user = "monkey",
    exclude_schema = c("tiger", "public")
  )


  ### (2) load current data
  excluded_tables <- schemas %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)

  table_relations <- read_table_relations_config(
    storage_filepath = here::here(dbstructure_folder, "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key),
      !(dependent_table %in% excluded_tables)
    )

  dependent_tables <- table_relations %>% pull(dependent_table)

  # table_existing_data_list <- query_tables_data(
  #   db_target,
  #   database = working_dbname,
  #   tables = lapply(c(table_key, dependent_tables), FUN = get_tableid)
  # )


  ### (3) store key lookup of dependent table

  # query_columns(db_connection, get_tableid(table_key), c("protocol_id", "description"))
  # deptab_key <- "GroupedActivities"

  lookups <- lapply(
    dependent_tables,
    FUN = function(deptab_key) mnmdb$lookup_dependent_columns(table_key, deptab_key)
  ) %>% setNames(dependent_tables)

  ### (4) retrieve old data
  pk <- mnmdb$get_primary_key(table_key)

  if (is.null(characteristic_columns)) {
    characteristic_columns <- mnmdb$get_characteristic_columns(table_key)
  } # TODO else: check that col really is a field in the table

  # TODO there must be more column match checks
  # prior to deletion
  # in connection with `characteristic_columns`

  # TODO write function to restore key lookup table
  # TODO allow rollback (of focal and dependent tables)

  old_data <- dplyr::tbl(db_target, get_tableid(table_key)) %>% collect


  ### ERROR
  # the old data does not contain dependent table keys any more.
  # if there are no characteristic columns, depentent table lookups are dead
  # at the point of DELETE.
  # This happened with SSPSTapas on production already (20250825).



  ### (5) UPLOAD/replace the data

  # use `rename_characteristics`
  # to rename cols in the new_data to the server data logic
  # new_data
  # rename_characteristics
  for (rnc in seq_len(length(rename_characteristics))) {
    new_colname <- rename_characteristics[[rnc]]
    server_colname <- names(rename_characteristics)[rnc]
    names(new_data)[names(new_data) == new_colname] <- server_colname
  }

  # ## NO: no appending needed here; appending happens in the wrapper.
  # # per default, this function appends the table content,
  # # which means that
  # #   - all entries in `new_data` are uploaded anyways
  # #   - `old_data` rows which do not match `new_data` in characteristic
  # #     columns are also re-uploaded
  # if (append_existing) {
  #   # columns must either be non-index, or in the new data
  #   # (to avoid case where existing indices are rowbound with NULL)
  #   subset_columns <- names(old_data)
  #   subset_columns <- subset_columns[
  #     (!(subset_columns %in% index_columns))
  #     || (subset_columns %in% names(new_data))
  #   ]

  #   # new and old data go together
  #   new_data <- bind_rows(
  #     old_data %>%
  #       select(!!!subset_columns) %>%
  #       anti_join(
  #         new_data,
  #         by = join_by(!!!characteristic_columns)
  #       ),
  #       new_data
  #     ) %>%
  #     distinct

  # }

  # this data is not lost yet, but will be checked against the `new_data` to upload.
  # lostrow_data <- dplyr::tbl(db_target, get_tableid(table_key)) %>% collect()

  # what about `sf` data?
  # - R function overloading: no matter if sf or not
  # - because geometry columns are skipped for `characteristic_columns`
  #       -> seems to work the same


  ### store dependent table lookups
  # here I short-circuit the DELETE/CASCADE process.
  store_dependent_lookups <- function(deptab) {

    dep_pk <- mnmdb$get_primary_key(deptab)

    # the pk is the fk in the dt
    fk_lookup <- dplyr::tbl(
      db_target,
      get_tableid(deptab)
    ) %>%
    select(!!!c(dep_pk, pk)) %>%
    collect

    return(fk_lookup)
  }

  fk_lookups <- lapply(
    dependent_tables,
    FUN = store_dependent_lookups
  ) %>% setNames(dependent_tables)


  ### DELETE existing data -> DANGEROUS territory!
  execute_sql(
    db_target,
    glue::glue("DELETE  FROM {get_namestring(table_key)};"),
    verbose = verbose
  )

  # On the occasion, we reset the sequence counter
  if ((length(pk) > 0) && isFALSE(skip_sequence_reset)) {

    sequence_key <- glue::glue('"{get_schema(table_key)}".seq_{pk}')
    nextval_query <- glue::glue("SELECT last_value FROM {sequence_key};")
    current_highest <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]

    # set to one because data is re-inserted
    execute_sql(
      db_target,
      glue::glue('ALTER SEQUENCE {sequence_key} RESTART WITH 1;'),
      verbose = verbose
    )
  }

  # INSERT new data, appending the empty table
  #    (to make use of the "ON DELETE SET NULL" rule)
  # new_data %>%
  #   filter(grts_address == 871030, activity_group_id == 4) %>%
  #   knitr::kable()
  rs <- DBI::dbWriteTable(
    db_target,
    get_tableid(table_key),
    new_data,
    row.names = FALSE,
    overwrite = FALSE,
    append = TRUE,
    factorsAsCharacter = TRUE,
    binary = TRUE
  )

  # new_data %>% head() %>% knitr::kable()


  ## restore sequence
  if ((length(pk) > 0) && isFALSE(skip_sequence_reset)) {
    nextval <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]
    max_pk <- dplyr::tbl(db_target, get_tableid(table_key)) %>%
      select(!!pk) %>% collect %>%
      pull(!!pk) %>% max
    nextval <- max(c(nextval, max_pk))

    execute_sql(
      db_target,
      glue::glue("SELECT setval('{sequence_key}', {nextval});"),
      verbose = verbose
    )
  }


  if (length(pk) > 0) {
    ### TODO !!! shouldn't this be *all* index_columns, instead just pk?
    cols_to_query <- c(characteristic_columns, pk)
  } else {
    cols_to_query <- c(characteristic_columns)
  }

  new_redownload <- query_columns(
    db_target,
    get_tableid(table_key),
    columns = cols_to_query
  )

  # THIS is the critical join of the stored old data (with key) and the reloaded, new data (key)
  # entries which were not present prior to update are not in this lookup
  new_redownload %>%
    count(samplelocation_id, grts_address, activity_group_id,
          date_start, fieldworkcalendar_id
          ) %>%
    arrange(desc(n))

  pk_lookup <- old_data %>%
    left_join(
      new_redownload,
      by = characteristic_columns,
      relationship = "one-to-one",
      suffix = c("_old", ""),
      unmatched = "drop"
    )

  if (FALSE) {
    a <- old_data %>%
      select(!!c(pk, characteristic_columns))  %>%
      filter(grts_address == 23238)
    b <- new_redownload %>%
      select(!!c(pk, characteristic_columns))  %>%
      filter(grts_address == 23238)
    new_redownload %>% head() %>% knitr::kable()
    a %>% knitr::kable()
    b %>% knitr::kable()

    a %>% left_join(
      b,
      by = characteristic_columns,
      relationship = "one-to-one",
      suffix = c("_old", ""),
      unmatched = "drop"
    ) %>% knitr::kable()
  }


  ## save non-recovered rows
  if (length(pk) > 0) {
    not_found <- pk_lookup %>%
      select(!!!rlang::syms(c(glue::glue("{pk}_old"), pk)))  %>%
      filter(if_any(everything(), ~ is.na(.x)))

    # (corrected 20250825)
    lost_rows <- old_data %>%
      semi_join(
        not_found,
        by = join_by(!!pk == !!glue::glue("{pk}_old"))
      )

    # mourn the loss of rows
    if (nrow(lost_rows) > 0) {
      warning("some previous data rows were not found back.")
      knitr::kable(lost_rows)
      write.csv(
        lost_rows,
        glue::glue("dumps/lostrows_{table_key}_{now}.csv"),
        row.names = FALSE
      )
    }
  }


  ## update dependent tables
  # "LocationCells"       "SampleLocations"     "LocationAssessments" "ExtraVisits"
  # deptab <- "LocationCells"
  # deptab <- dependent_tables[[1]]

  for (deptab in dependent_tables) {

    # extract the associating columns
    keycolumn_linkpair <- table_relations %>%
      filter(
        relation_table == tolower(table_key),
        dependent_table == deptab
      ) %>%
      select(dependent_column, relation_column)
    dependent_key <- keycolumn_linkpair[["dependent_column"]]
    reference_key <- keycolumn_linkpair[["relation_column"]]

    # the focus table, linking old and new pk values
    # copied in case multiple deptabs have same key diff name
    pk_link <- pk_lookup
    # ensure `_old` suffix for joining below
    # dependent_col_old <- glue::glue("{dependent_key}_old")
    reference_col_old <- glue::glue("{reference_key}_old")
    if (isFALSE(reference_col_old %in% names(pk_lookup))) {
      names(pk_link)[names(pk_link) == reference_key] <- reference_col_old
    }

    # reduced to just the "old -> new" keys
    pk_link <- pk_link %>%
      select(!!!rlang::syms(c(reference_col_old, pk)))

    # names(pk_link)[names(pk_link) == dependent_key] <- reference_key


    # finally, combine the lookup table
    lookup <- lookups[[deptab]]

    # swap the table-specific names
    names(lookup)[names(lookup) == dependent_key] <- reference_col_old
    names(pk_link)[names(pk_link) == reference_key] <- dependent_key

    key_replacement <- lookup %>%
      left_join(
        pk_link,
        by = reference_col_old,
        relationship = "many-to-one",
        suffix = c("_old", "")
      )

    # dump-store look
    write.csv(
      key_replacement,
      glue::glue("dumps/lookup_{now}_{table_key}_{deptab}.csv"),
      row.names = FALSE
    )


    # restrict this to modified data, ignore empty rows
    # by FILTER for changed values
    key_replacement <- bind_rows(
      key_replacement[
        !mapply(identical,
          key_replacement[[reference_col_old]],
          key_replacement[[dependent_key]]
        )
        , ],
      key_replacement[
        is.na(key_replacement[[reference_col_old]])
        , ]
      )

    if (nrow(key_replacement) == 0) next # nothing to update

    ### UPDATE the dependent table
    # ... by looking up the dependent table pk
    dep_pk <- mnmdb$get_primary_key(deptab)

    if (length(dep_pk) == 0) next # these is the LocationCells

    fk_table <- fk_lookups[[deptab]]
    # repl_rownr <- 1
    get_update_row_string <- function(repl_rownr){
      dep_pk_val <- key_replacement[repl_rownr, dep_pk]
      val <- key_replacement[repl_rownr, dependent_key][[1]]

      # desparate attempt 1: check the previously saved data
      fk_vals <- fk_table %>% pull(!!dep_pk)
      if (is.na(val)) {
        fk_val <- fk_table[fk_vals == dep_pk_val[[1]],] %>% pull(!!pk)

        if (isFALSE(is.na(fk_val))) {
          old_vals <- pk_link %>% pull(!!reference_col_old)
          val <- pk_link[old_vals == fk_val, 2][[1]]
        }
      }

      # failure: set NULL
      if (is.na(val)) {
        val <- "NULL"
      }

      update_string <- glue::glue("
        UPDATE {get_namestring(deptab)}
          SET {dependent_key} = {val}
        WHERE {dep_pk} = {dep_pk_val}
        ;
      ")

      return(update_string)
    }

    update_command <- lapply(
      1:nrow(key_replacement),
      FUN = get_update_row_string
    )

    # execute the update commands.
    message(
      glue::glue(
        "Updating {dependent_key} of {deptab} (N={length(update_command)})."
      )
    )

    for (cmd in update_command) {
      execute_sql(db_target, cmd, verbose = FALSE)
    }

  } # /loop dependent tables


} #/update_datatable_and_dependent_keys



parametrize_cascaded_update <- function(mnmdb) {

  ucl_function <- function(
      table_label,
      new_data,
      index_columns,
      tabula_rasa = FALSE,
      characteristic_columns = NULL,
      skip_sequence_reset = FALSE,
      verbose = TRUE
    ) {

    schema <- mnmdb$get_schema(table_label)

    if (verbose) {
      message("________________________________________________________________")
      message(glue::glue("Cascaded update of {schema}.{table_key}"))
    }

    # characteristic columns := columns which uniquely define a data row,
    # but which are not the primary key.
    if (is.null(characteristic_columns)) {
      # in case no char. cols provided, just take all columns.
      characteristic_columns <- mnmdb$get_characteristic_columns
    }

    ## (0) check that characteristic columns are UNIQUE:
    # the char. columns of the data to upload
    new_characteristics <- new_data %>%
      select(!!!characteristic_columns) %>%
      distinct()
    stopifnot("Error: characteristic columns are not characteristic!" =
      nrow(new_data) == nrow(new_characteristics))


    to_upload <- new_data

    # existing content
    prior_content <- mnmdb$query_tbl(table_label)
    # head(prior_content)
    # prior_content %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()


    ## (1) optionally append
    if (isFALSE(tabula_rasa)) {

      # columns must either be non-index, or in the new data
      # (to avoid case where existing indices are rowbound with NULL)
      subset_columns <- names(prior_content)
      subset_columns <- subset_columns[
        (!(subset_columns %in% index_columns))
        | (subset_columns %in% names(to_upload))
      ]

      existing_unchanged <- prior_content %>%
        select(!!!subset_columns) %>%
        anti_join(
          new_characteristics,
          by = join_by(!!!characteristic_columns)
        )
      # prior_content %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
      # new_characteristics %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
      # existing_unchanged %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()

      existing_removed <- prior_content %>%
        select(!!!subset_columns) %>%
        semi_join(
          new_characteristics,
          by = join_by(!!!characteristic_columns)
        )
      # existing_removed %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()

      # # refcol <- enquo(characteristic_columns)
      # existing_unchanged <- existing_characteristics %>%
      #   anti_join(
      #     new_characteristics,
      #     by = join_by(!!!characteristic_columns)
      #   ) %>%
      #   left_join(
      #     prior_content,
      #     by = join_by(!!!characteristic_columns)
      #   )

      if (verbose) {
        message(glue::glue("  {nrow(existing_unchanged)} rows will be retained."))
        if (nrow(existing_removed) > 0) {
          message(glue::glue("  {nrow(existing_removed)} rows changed, potential info LOST."))
          now <- format(Sys.time(), "%Y%m%d%H%M")
          write.csv(
            existing_removed,
            glue::glue("dumps/lost_changerows_{table_key}_{now}.csv"),
            row.names = FALSE
          )
        }
      }

      # combine existing and new data
      to_upload <- bind_rows(
          existing_unchanged,
          to_upload
        ) %>%
        distinct() # HERE is the bug.
      # to_upload %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
    } else {
        message(glue::glue("  Tabula rasa: no rows will be retained."))
    }

    ## do not upload index columns
    retain_cols <- names(to_upload)
    retain_cols <- retain_cols[!(retain_cols %in% index_columns)]
    to_upload <- to_upload %>% select(!!!retain_cols)


    ### double safety: load/catch/restore
    table_content_storage <- mnmdb$store_table_deptree_in_memory(table_label)

    tryCatch({
      ### update datatable, propagating/cascading new keys to other's fk

      update_datatable_and_dependent_keys(
        mnmdb,
        table_key = table_key,
        new_data = to_upload,
        characteristic_columns = characteristic_columns,
        skip_sequence_reset = skip_sequence_reset,
        verbose = verbose
      )
      # TODO rename_characteristics = rename_characteristics,
    }, error = function(wrnmsg) {
      message("##### update failed! #####")
      message(glue::glue("--> uploading {nrow(to_upload)} rows to {table_key} "))
      message(wrnmsg)
      message("\nrestoring data.\n")
      invisible(
        mnmdb$restore_table_data_from_memory(table_content_storage)
      )
      return(NA)
    })


    lookup <- mnmdb$query_columns(
      table_key,
      c(characteristic_columns, index_columns)
      )

    if (verbose){
      message(sprintf(
        "%s: %i rows uploaded, were %i existing judging by '%s'.",
        mnmdb$get_namestring,
        nrow(to_upload),
        nrow(prior_content),
        paste0(characteristic_columns, collapse = ", ")
      ))
    }

    return(lookup)

  } # /update_cascade_lookup

  return(ucl_function)
} # /parametrize_cascaded_update


#_______________________________________________________________________________
# DATABASE STRUCTURE

# the first entry is the table itself
# find_dependent_tables("mnmgwdb_db_structure", "Visits")
obsolete_find_dependent_tables <- function(dbstructure_folder = "db_structure", table_key) {
  # dbstructure_folder <- "./mnmgwdb_db_structure"
  # table_key <- "Visits"

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, schema, geometry, excluded)

  ### (2) load current data
  excluded_tables <- schemas %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)

  table_relations <- read_table_relations_config(
    storage_filepath = here::here(dbstructure_folder, "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key),
      !(dependent_table %in% excluded_tables)
    )

  dependent_tables <- c(
    table_key,
    table_relations %>% pull(dependent_table)
    )

  create_dbi_identifier <- function(tabkey) {
    schema <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(schema)
    tkey_right <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(table)
    return(DBI::Id(schema, tkey_right))
  }

  table_ids <- lapply(dependent_tables, FUN = create_dbi_identifier)

  return(table_ids)

} # /find_dependent_tables


# store the content of a table in memory
obsolete_load_table_content <- function(
    db_connection,
    dbstructure_folder,
    table_id
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))

  is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, geometry) %>%
    filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
    pull(geometry) %>% is.na

  if (is_spatial) {
    data <- sf::st_read(db_connection, table_id) %>% collect
  } else {
    data <- dplyr::tbl(db_connection, table_id) %>% collect
  }

  return(list("id" = table_id, "data" = data))

} # /load_table_content


# push table from memory back to the server
obsolete_restore_table_data_from_memory <- function(
    db_target,
    content_list,
    dbstructure_folder = "db_structure",
    verbose = TRUE
  ) {
  # content_list <- table_content_storage[[3]]

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  table_id <- content_list$id
  table_key <- attr(table_id, "name")
  table_lable <- glue::glue('"{table_key[[1]]}"."{table_key[[2]]}"')
  table_data <- content_list$data


  if (is.scalar.na(table_data) || (nrow(table_data) < 1)) {
    message("no data to restore.")
    return(invisible(NA))
  }

  # restore data
  pk <- mnmdb$get_primary_key(table_key[[2]])

  # TODO need to branch geometry tables?
  # is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  #   select(table, geometry) %>%
  #   filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
  #   pull(geometry) %>% is.na

  # using dplyr/DBI to upload has the usual issues of deletion/restroation,
  # i.e. that user roles are not persistent.
  # Hence, the usual trick of "empty/append".

  # Note that I neglect dependent table here, since they will be re-uploaded after
  ## delete from table
  execute_sql(
    db_target,
    glue::glue("DELETE FROM {table_lable};"),
    verbose = verbose
  )

  ## reset the sequence
  sequence_key <- glue::glue('"{table_key[[1]]}".seq_{pk}')
  nextval_query <- glue::glue("SELECT last_value FROM {sequence_key};")

  current_highest <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]

  execute_sql(
    db_target,
    glue::glue('ALTER SEQUENCE {sequence_key} RESTART WITH 1;'),
    verbose = verbose
  )

  ## append the table data
  append_tabledata(db_target, table_id, table_data)

  ## restore sequence
  nextval <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]
  nextval <- max(c(nextval, current_highest, table_data %>% pull(pk)))

  execute_sql(
    db_target,
    glue::glue("SELECT setval('{sequence_key}', {nextval});"),
    verbose = verbose
  )

  return(invisible(NULL))

} # /restore_table_data_from_memory




#' Read a table relation config file and convert it to data frame.
#'
#' @param storage_filepath the path to the config file
#'
#' @return data frame with the column relations from a dependent to a relation
#'     table. Note that relation table names are lowercase due to some
#'     ConfigParser limitation.
#'
#' @examples
#' \dontrun{
#'    read_table_relations_config(storage_filepath = file.path("./devdb_structure/table_relations.conf"))
#' }
#'
read_table_relations_config <- function(storage_filepath) {

  stopifnot("configr" = require("configr"))

  # read the raw file
  table_relations <- configr::read.config(file = storage_filepath)

  # Initialize empty. What a humble procedure.
  relation_lookup <- data.frame(
    relation_table = character(),
    dependent_table = character(),
    dependent_column = character(),
    relation_column = character()
  )

  # oh, how I miss my dictionaries!
  for (deptab in attributes(table_relations)[[1]]) {
    for (reltab in attributes(table_relations[[deptab]])$names){
      if(is.null(table_relations[[deptab]][reltab])) next
      new_row <- c(
        reltab,
        deptab,
        eval(parse(text = sprintf("c%s", table_relations[[deptab]][[reltab]])))
      )
      relation_lookup <- dplyr::bind_rows(
        relation_lookup,
        setNames(new_row, names(relation_lookup))
      )
    }
  }

  # knitr::kable(relation_lookup)
  return(relation_lookup)

}


#_______________________________________________________________________________
# CONNECTION HANDLING

#' Connect to a postgreSQL database, using settings from a config file
#'
#' Connect to a postgreSQL database (other dialects trivial).
#' Connection settings are loaded from a config file, content such as
#'     [profile-name]
#'     host = localhost
#'     port = 5439
#'     user = test
#'     database = playground
#'     password = <the password you entered IN PLAIN TEXT>
#' The connection parameters can be overwritten by optional function arguments.
#' The purpose of overwriting is simplified handling of multiple connections.
#' Default port 5439 is used if no port is configured or provided.
#' Config file may have different sections (=profiles); if none is chosen, the first
#' must do.
#' Connections will gracefully close upon termination of the R session, by
#' registration of a "finalizer".
#'
#' @param config_filepath the path to the config file
#' @param profile config section header (configs with multiple connection settings)
#' @param host the database server (usually an IP address)
#' @param port the port on which the host serves postgreSQL, default 5439
#' @param user the database username
#' @param password the users database password,
#'        hint1: use keyring::key_set("DBPassword", "db_user_password")
#'
#' @examples
#' \dontrun{
#'     keyring::key_set("DBPassword", "db_user_password") # prompt/store password
#'     config_filepath <- file.path("./server.conf")
#'     db_source <- connect_database_configfile(
#'       config_filepath, # sort of provides default settings
#'       database = "loceval",
#'       profile = "inbopostgis-dev",
#'       user = "panoramix" # override user
#'     )
#' }
#'
connect_database_configfile <- function(
    config_filepath,
    database = NULL,
    profile = NULL,
    host = NULL,
    port = NULL,
    user = NULL,
    password = NULL
    ) {
  # connect to a database, via config file
  # but settings can be overwritten upon function call

  # make sure config file exists
  stopifnot(file.exists(config_filepath))

  # profile (section within the config file)
  if (is.null(profile)) {
    profile <- 1 # use the first profile by default
  }

  # read connection info from a config file
  config <- configr::read.config(file = config_filepath)[[profile]]

  if (is.null(host)) {
    stopifnot("host" %in% attributes(config)$names)
    host <- config$host
  }

  if (is.null(port)) {
    if ("port" %in% attributes(config)$names) {
      port <- config$port
    } else {
      port <- 5439
    }
  }

  if (is.null(database)) {
    stopifnot("database" %in% attributes(config)$names)
    database <- config$database
  }

  if (is.null(user)) {
    stopifnot("user" %in% attributes(config)$names)
    user <- config$user
  }

  # store a label for verbose disconnection at exit
  db_label <- sprintf("%s@%s/%s", user, host, database)

  # get password.
  # (1) direct function input
  # (2) from config file
  # (3) user input
  if (is.null(password)) {
    if (is.null(config[["password"]])){
      if (keyring::key_get("DBPassword", "db_user_password") == "") {
        keyring::key_set("DBPassword", "db_user_password")
      }
      password <- keyring::key_get("DBPassword", "db_user_password")
    } else {
      password <- config$password
    }
  }

  # connect to database
  #
  tryCatch({
    if (is.na(password)) {
      database_connection <- DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = database,
        host = host,
        port = port,
        user = user
      )
    } else {
      database_connection <- DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = database,
        host = host,
        port = port,
        user = user,
        password = password
      )
    }
    },
    error = function(wrnmsg) {
      message(
        sprintf(
          'no password provided for connection %s. \n Try `keyring::key_set("DBPassword", "db_user_password")`.',
          db_label)
      )
    }
  )


  # remove the config: we do not want to expose credentials further
  # down in this notebook
  rm(config)

  # register disconnect for finalization
  # https://stackoverflow.com/a/41179916
  reg.finalizer(
    .GlobalEnv,
    function(e){
      DBI::dbDisconnect(database_connection)
      message(sprintf("Database %s gracefully disconnected.", db_label))
    },
    onexit = TRUE
  )

  return(invisible(database_connection))
} # /connect_database_configfile


#' Connect to an MNM database by config and mirror.
#'
#' Connect to an MNM postgreSQL database.
#' Just requires a config file and a mirror.
#' The returned object is feature-rich, bringing all required
#' lookup-tables and functions.
#'
#' @param config_filepath the path to the config file
#' @param database_mirror database and mirror (equal to "config profile")
#' @param ... further connection parameters, forwarded to connect_database_configfile
#'
connect_mnm_database <- function(
    config_filepath,
    database_mirror = NA,
    skip_structure_assembly = FALSE ,
    ...
  ) {
  # database_mirror <- "mnmgwdb-staging"

  stopifnot(
    "glue" = require("glue"),
    "DBI" = require("DBI"),
    "keyring" = require("keyring"),
    "configr" = require("configr")
  )
  stopifnot("provide database mirror" = isFALSE(is.na(mirror)))

  # collect db connection
  db <- list()
  db$connection_profile <- database_mirror

  # load profile
  config <- configr::read.config(file = config_filepath)[[db$connection_profile]]

  for (cfg in attributes(config)$names) {
    if (cfg == "password") next
    db[[cfg]] <- config[[cfg]]
  }

  # connect
  db$connection <- connect_database_configfile(
    config_filepath,
    profile = database_mirror,
    database = config$database
  )
  if ("database" %in% attributes(config)$names) {
    db$connection <- connect_database_configfile(
      config_filepath,
      profile = database_mirror,
      database = config$database,
      ...
    )
  } else {
    db$connection <- connect_database_configfile(
      config_filepath,
      profile = database_mirror,
      ...
    )
  }

  # extend
  if (isFALSE(skip_structure_assembly)) {
    db <- mnmdb_assemble_structure_lookups(db)
    db <- mnmdb_assemble_query_functions(db)
  }

  return(db)
} # /connect_mnm_database


# take a database object and give it some structure
mnmdb_assemble_structure_lookups <- function(db) {

  # tables and their relations
  db$tables <- read.csv(here::here(db$folder, "TABLES.csv")) %>%
    select(table, schema, geometry, excluded)

  # this one is created by python scripts
  db$table_relations <- read_table_relations_config(
    storage_filepath = here::here(db$folder, "table_relations.conf")
    )

  # some tables are excluded
  db$excluded_tables <- db$tables %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)

  # get schema for a table
  db$get_schema <- function(table_label) {
    return(
      schemas %>%
        filter(table == table_label) %>%
        pull(schema)
    )
  }

  # get namestring as used in direct SQL queries
  db$get_namestring <- function(table_label) glue::glue('"{db$get_schema(table_label)}"."{table_label}"')

  # get table Id as used DBI/dbplyr queries
  db$get_tableid <- function(table_label) DBI::Id(schema = db$get_schema(table_label), table = table_label)

  ### table dependency structure
  db$get_dependent_tables <- function (table_key) {
    return(c(
      table_key,
      db$table_relations %>%
      filter(relation_table == tolower(table_key),
        !(dependent_table %in% db$excluded_tables)
      ) %>% pull(dependent_table)
    ))
  }

  # same as above, but from lowercase table key
  db$get_dbi_identifier_lowercase <- function(tabkey) {
    schema <- db$tables %>%
      filter(tolower(table) == tolower(tabkey)) %>%
      pull(schema)
    tkey_right <- schemas %>%
      filter(tolower(table) == tolower(tabkey)) %>%
      pull(table)
    return(DBI::Id(schema, tkey_right))
  }

  # return table IDs for all dependent tables
  db$get_dependent_table_ids <- function(table_key){
    return(lapply(
      db$get_dependent_tables(table_key),
      FUN = db$get_dbi_identifier_lowercase
    ))
  }

  # specific table info
  db$load_table_info <- function(table_label){
    table_info <- read.csv(
      here::here(db$folder, glue::glue("{table_label}.csv"))
    )
    return(table_info)
  }


  db$get_characteristic_columns <- function(table_label){

    # excluded from checks
    logging_columns <- c("log_user", "log_update", "geometry", "wkb_geometry")

    full_table_info <- db$load_table_info(table_label)

    pk <- full_table_info %>%
      filter(primary_key == "True") %>%
      pull(column)

    characteristic_columns <- full_table_info %>%
      filter(
        !(column %in% logging_columns),
        !(column %in% pk),
      ) %>%
      pull(column)

    return(characteristic_columns)
  }


  # or need a primary key?
  db$get_primary_key <- function(table_label) {
    return(
      db$load_table_info(table_label) %>%
        filter(primary_key == "True") %>%
        pull(column)
    )
  }

  # the result: a database object with more features
  return(db)
} # /mnmdb_assemble_structure_lookups


mnmdb_assemble_query_functions <- function(db) {

  db$query_columns <- function(table_label, select_columns){
    dplyr::tbl(db$connection, db$get_tableid(table_label)) %>%
      dplyr::select(!!!rlang::syms(select_columns)) %>%
      dplyr::collect()
  }

  db$is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, geometry) %>%
    filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
    pull(geometry) %>% is.na

  db$query_tbl <- function(table_label) {
    if (db$is_spatial(table_label)) {
      data <- sf::st_read(db_connection, table_id) %>% collect
    } else {
      data <- dplyr::tbl(db_connection, table_id) %>% collect
    }
    return(data)
  }

  # query_columns(db_connection, get_tableid(table_key), c("protocol_id", "description"))
  db$query_tables_data <- function(tables) {
    data <- lapply(
      tables,
      FUN =
    )
    return(data)
  }

  # all dependent lookup columns
  db$lookup_dependent_columns <- function(table_label, deptab_label) {

    # with a little help from my Python
    deptab_pk <- db$get_primary_key(deptab_label)

    # get the foreign key columns
    dependent_key <- db$table_relations %>%
      filter(
        relation_table == tolower(table_label),
        dependent_table == deptab_label
      ) %>%
      pull(dependent_column)

    # lookup the key columns
    key_lookup <- db$query_columns(
      deptab_label,
      c(deptab_pk, dependent_key)
    )

    return(key_lookup)
  }


  # temporarily store table and dependencies in memory
  db$store_table_deptree_in_memory <- function(table_label) {
    # savetabs <- find_dependent_tables("mnmgwdb_db_structure", "Visits")
    savetabs <- mnmdb$get_dependent_tables(table_label)

    return(
      lapply(
        savetabs,
        FUN = function(tablab) list(
          "label" = tablab,
          "data" = db$query_tbs(tablab)
        )
      )
    )
  }

  # direct execution
  db$execute_sql <- function(...) {return(execute_sql(db$connection, ...)}

  # push table from memory back to the server
  #   involves key resetting
  db$restore_table_data_from_memory <- function(table_content_storage, verbose = TRUE) {
    restore_ <- function(tabledata_list) {

      table_label <- tabledata_list$label
      schema <- db$get_schema(table_label)
      table_id <- db$get_tableid(table_label)
      table_data <- tabledata_list$data

      if (is.scalar.na(table_data) || (nrow(table_data) < 1)) {
        message("no data to restore.")
        return(invisible(NA))
      }

      # restore data
      pk <- db$get_primary_key(table_label)

      # Note that I neglect dependent table here, since they will be re-uploaded after
      ## delete from table
      db$execute_sql(
        glue::glue("DELETE FROM {table_label};"),
        verbose = verbose
      )

      ## reset the sequence
      sequence_key <- glue::glue('"{schema}".seq_{pk}')
      nextval_query <- glue::glue("SELECT last_value FROM {sequence_key};")

      current_highest <- DBI::dbGetQuery(db$connection, nextval_query)[[1, 1]]

      db$execute_sql(
        glue::glue('ALTER SEQUENCE {sequence_key} RESTART WITH 1;'),
        verbose = verbose
      )

      ## append the table data
      append_tabledata(db$connection, table_id, table_data)

      ## restore sequence
      nextval <- DBI::dbGetQuery(db$connection, nextval_query)[[1, 1]]
      nextval <- max(c(nextval, current_highest, table_data %>% pull(pk)))

      db$execute_sql(
        glue::glue("SELECT setval('{sequence_key}', {nextval});"),
        verbose = verbose
      )

      return(invisible(NULL))
    }

    # list-restore
    invisible(
      lapply(table_content_storage, FUN = restore_)
    )
  }



  return(db)

} # /mnmdb_assemble_query_functions


#_______________________________________________________________________________
# HANDLE BACKUPS

### TODO CONTINUE move this to db$ // mnmdb$

#' dump the database with a system call to `pg_dump` (linux)
#'
#' @details To apply this from scripts, password is not used. Make sure
#' to configure your `~/.pgpass` file.
#'
#' @param target_filepath the path to store the dump
#' @param config_filepath the path to the config file
#' @param database the database to backup
#' @param profile config section header (configs
#'        with multiple connection settings; best define a `dumpall`)
#' @param host the database server (usually an IP address)
#' @param port the port on which the host serves postgreSQL, default 5439
#' @param user the database username
#'
#' @examples
#' \dontrun{
#'   now <- format(Sys.time(), "%Y%m%d%H%M")
#'   dump_all(
#'     here::here(glue::glue("dumps/safedump_{now}.sql")),
#'     config_filepath = config_filepath,
#'     database = working_dbname,
#'     profile = "dumpall",
#'     user = "readonly_user",
#'     exclude_schema = c("tiger", "public")
#'   )
#' }
#'
dump_all <- function(
    target_filepath,
    config_filepath,
    database,
    profile = NULL,
    user = NULL,
    host = NULL,
    port = NULL,
    exclude_schema = NULL
    ) {

  stopifnot(
    "configr" = require("configr"),
    "glue" = require("glue"),
    "here" = require("here")
  )

  # profile (section within the config file)
  if (is.null(profile)) {
    profile <- 1 # use the first profile by default
  }

  # read connection info from a config file,
  # unless user provided different credentials
  config <- configr::read.config(file = config_filepath)[[profile]]

  if (is.null(host)) {
    stopifnot("host" %in% attributes(config)$names)
    host <- config$host
  }

  if (is.null(port)) {
    if ("port" %in% attributes(config)$names) {
      port <- config$port
    } else {
      port <- 5439
    }
  }

  if (is.null(user)) {
    stopifnot("user" %in% attributes(config)$names)
    user <- config$user
  }

  # exclude some schemas
  if (!is.null(exclude_schema)) {

    exschem_string <- c()
    for (exschem in exclude_schema){
      exschem_string <- c(exschem_string, glue::glue("-N {exschem}"))
    }
    exschem_string <- paste(exschem_string, collapse = " ")
  }

  # dump the database!
  dump_string <- glue::glue('
    pg_dump -U {user} -h {host} -p {port} -d {database} {exschem_string} --no-password > "{target_filepath}"
    ')

  system(dump_string)

} # /dump_all


