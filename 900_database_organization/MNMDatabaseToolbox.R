#!/usr/bin/env Rscript

# Various database-related helper functions.
# Usually depend on
# - libraries (`MNMLibraryCollection.R`), specifically
#     `poc_common_libraries`,
#     `database_interaction_libraries`,
#     `load_poc_code_snippets`
# - the POC
#   (`050_snippet_selection.R`, `051_snippet_transformation_code.R`, to be moved)
# - a database connection (`MNMDatabaseConnection.R`)
#

#_______________________________________________________________________________
# common commands (quick helpers for Falk)

# .libPaths("/data/R/library")
# SET search_path TO public,"metadata","outbound","inbound","archive";

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



# TODO: option to drop; but mind cascading

# this function loads the content of a table, and then uploads only
# the new rows which are not already present (as judged by some
# characteristic columns).
append_tabledata <- function(
    mnmdb,
    table_id,
    data_to_append,
    characteristic_columns = NA
  ) {

  content <- DBI::dbReadTable(mnmdb$connection, table_id)
  # head(content)

  if (any(is.na(characteristic_columns))) {
    # ... or just take all columns
    characteristic_columns <- names(data_to_append)
  }

  # refcol <- enquo(characteristic_columns)
  existing <- content %>% select(!!!characteristic_columns)
  to_upload <- data_to_append %>%
    anti_join(existing, join_by(!!!characteristic_columns)
  )

  rs <- DBI::dbWriteTable(
    mnmdb$connection,
    table_id,
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
    table_label,
    ..., # -> append_tabledata
    characteristic_columns,
    index_columns
  ) {

  # label and id
  table_id <- mnmdb$get_table_id(table_label)

  # append the data
  append_tabledata(
    mnmdb$connection,
    table_id = table_id,
    ...,
    characteristic_columns
  )

  # collect the lookup (link characteristics to index)
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

  target_lookup <- mnmdb$query_columns(table_label, target_cols)

  key_replacement <- target_lookup %>%
    left_join(
      location_lookup,
      by = join_by(grts_address),
      relationship = "many-to-one"
    )


  ### UPDATE the location-related table

  # repl_rownr <- 10 # testing
  get_update_row_string <- function(repl_rownr) {

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
    seq_len(nrow(key_replacement)),
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
# ### TODO!!! continue conversion
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

  # schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  #   select(table, schema, geometry, excluded)

  # These are clumsy, temporary, provisional helpers.
  # But, hey, there will be time later.
  ## get_schema <- function(table_label) {
  ##   return(schemas %>%
  ##     filter(table == table_label) %>%
  ##     pull(schema)
  ##   )
  ## }
  # get_namestring <- function(table_label) glue::glue('"{get_schema(table_label)}"."{table_label}"')
  # get_tableid <- function(table_label) DBI::Id(schema = get_schema(table_label), table = table_label)


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
  #   tables = lapply(c(table_key, dependent_tables), FUN = get_table_id)
  # )


  ### (3) store key lookup of dependent table

  # query_columns(db_connection, get_table_id(table_key), c("protocol_id", "description"))
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

  old_data <- dplyr::tbl(db_target, get_table_id(table_key)) %>% collect


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
  # lostrow_data <- dplyr::tbl(db_target, mnmdb$get_table_id(table_key)) %>% collect()

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
      mnmdb$get_table_id(deptab)
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
    mnmdb$get_table_id(table_key),
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
    max_pk <- dplyr::tbl(db_target, mnmdb$get_table_id(table_key)) %>%
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
    mnmdb$get_table_id(table_key),
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
