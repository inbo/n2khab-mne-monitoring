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
  location_lookup <- mnmdb$query_table("Locations") %>%
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
#' @param mnmdb an MNM database including DBI connection, structure, and
#'        working functions. See `MNMDatabaseConnection.R` for details.
#' @param table_key the table to be changed
#' @param new_data a data frame or tibble with the new data
#' @param characteristic_columns a subset of columns of the data table
#'        by which old and new data can be uniquely identified and joined;
#'        refers to the new data
#' @param rename_characteristics link columns with different names by
#'        renaming them in new_data
#' @param verbose provides extra prose on the way, in case you need it
#'
#' @examples
#' \dontrun{
#'   config_filepath <- file.path("./postgis_server.conf")
#'   # keyring::key_set("DBPassword", "db_user_password") # <- for source database
#'   source_db <- connect_mnm_database(
#'     config_filepath,
#'     database_mirror = "source-testing"
#'   )
#'
#'   test_table <- "LocationCalendar"
#'   new_data <- source_db$query_table(test_table)
#'   characteristic_columns = \
#'     c("scheme", "stratum", "grts_address", "column_newname")
#'
#'   update_datatable_and_dependent_keys(
#'     mnmdb = source_db,
#'     table_key = test_table,
#'     new_data = new_data,
#'     characteristic_columns = characteristic_columns,
#'     rename_characteristics = c(column_oldname = "column_newname")
#'     verbose = TRUE
#'   )
#' }
#'
update_datatable_and_dependent_keys <- function(
    mnmdb,
    table_label,
    new_data,
    characteristic_columns = NULL,
    rename_characteristics = NULL,
    skip_sequence_reset = FALSE,
    verbose = TRUE
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("RPostgres" = require("RPostgres"))
  stopifnot("glue" = require("glue"))

  # check if database connection is active
  # TODO mnmdb$connection_is_active

  ### (1) dump all data, for safety
  now <- format(Sys.time(), "%Y%m%d%H%M")
  mnmdb$dump_all(
    here::here("dumps", glue::glue("safedump_{working_dbname}_{now}.sql")),
    exclude_schema = c("tiger", "public")
  )


  ### (2) load current data
  table_relations <- mnmdb$table_relations %>%
    filter(
      tolower(relation_table) == tolower(table_lable),
      !(dependent_table %in% mnmdb$excluded_tables)
    )

  dependent_tables <- mnmdb$get_dependent_tables(table_label)


  ### (3) store key lookup of dependent table
  lookups <- lapply(
    dependent_tables,
    FUN = function(deptab_label) mnmdb$lookup_dependent_columns(table_label, deptab_label)
  ) %>% setNames(dependent_tables)


  ### (4) retrieve old data
  pk <- mnmdb$get_primary_key(table_key)

  if (is.null(characteristic_columns)) {
    characteristic_columns <- mnmdb$get_characteristic_columns(table_label)
  } # TODO else: check that col really is a field in the new_data table

  # TODO there must be more column match checks
  # prior to deletion
  # in connection with `characteristic_columns`

  old_data <- mnmdb$query_table(table_label)


  ### ERROR
  # the old data does not contain dependent table keys any more.
  # if there are no characteristic columns, depentent table lookups are dead
  # at the point of DELETE.
  # This happened with SSPSTapas on production already (20250825).
  # TODO review this, see also `lookups` above.

  ### (5) adjust column names

  # use `rename_characteristics`
  # to rename cols in the new_data to the server data logic
  # new_data
  # rename_characteristics
  for (rnc in seq_len(length(rename_characteristics))) {
    new_colname <- rename_characteristics[[rnc]]
    server_colname <- names(rename_characteristics)[rnc]
    names(new_data)[names(new_data) == new_colname] <- server_colname
  }


  # what about `sf` data?
  # - R function overloading: no matter if sf or not
  # - because geometry columns are skipped for `characteristic_columns`
  #       -> seems to work the same


  ### (6) store dependent table lookups
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


  ### (7) DELETE existing data -> DANGEROUS territory!
  mnmdb$execute_sql(
    glue::glue("DELETE  FROM {get_namestring(table_key)};"),
    verbose = verbose
  )

  # On the occasion, we reset the sequence counter
  if ((length(pk) > 0) && isFALSE(skip_sequence_reset)) {
    mnmdb$reset_sequence_key(table_label)
  }

  ### (8) INSERT new data
  # INSERT new data, appending the empty table
  #    (to make use of the "ON DELETE SET NULL" rule)
  mnmdb$insert_data(table_label, new_data)

  # new_data %>%
  #   filter(grts_address == 871030, activity_group_id == 4) %>%
  #   knitr::kable()
  # new_data %>% head() %>% knitr::kable()


  ## restore sequence
  if ((length(pk) > 0) && isFALSE(skip_sequence_reset)) {
    mnmdb$reset_sequence_key(table_label, "max")

  }


  if (length(pk) > 0) {
    ### TODO !!! shouldn't this be *all* index_columns, instead just pk?
    cols_to_query <- c(characteristic_columns, pk)
  } else {
    cols_to_query <- c(characteristic_columns)
  }

  new_redownload <- mnmdb$query_columns(
    table_label,
    select_columns = cols_to_query
  )

  # THIS is the critical join of the stored old data (with key) and the reloaded, new data (key)
  # entries which were not present prior to update are not in this lookup
  # new_redownload %>%
  #   count(samplelocation_id, grts_address, activity_group_id,
  #         date_start, fieldworkcalendar_id
  #         ) %>%
  #   arrange(desc(n))

  pk_lookup <- old_data %>%
    left_join(
      new_redownload,
      by = characteristic_columns,
      relationship = "one-to-one",
      suffix = c("_old", ""),
      unmatched = "drop"
    )

  if (FALSE) {
    # TODO return here to inspect the repercussions of previous errors
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
    # get_dependent_tables
    keycolumn_linkpair <- dependent_tables %>%
      filter(
        dependent_table == deptab
      ) %>%
      select(dependent_column, relation_column)
    dependent_key <- keycolumn_linkpair[["dependent_column"]]
    reference_key <- keycolumn_linkpair[["relation_column"]]

    # the focus table, linking old and new pk values
    # copied in case multiple deptabs have same key diff name
    pk_link <- pk_lookup # copying for temporary renaming

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
    lookup_deptab <- lookups[[deptab]]

    # swap the table-specific names
    names(lookup_deptab)[
        names(lookup_deptab) == dependent_key
      ] <- reference_col_old
    names(pk_link)[names(pk_link) == reference_key] <- dependent_key

    key_replacement <- lookup_deptab %>%
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

    if (length(dep_pk) == 0) next # special case, e.g. the LocationCells

    # get the original foreign key values
    fk_table <- fk_lookups[[deptab]]

    # prepare rowwise update
    # repl_rownr <- 1
    get_update_row_string <- function(repl_rownr) {
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
      mnmdb$execute_sql(cmd, verbose = FALSE)
    }

  } # /loop dependent tables


} #/update_datatable_and_dependent_keys



#' parametrize cascaded update for a given database
#'
#' The update_datatable... function above relies on the database which is given.
#' Yet it also has aspects which only change at runtime (hence not part of the
#' `MNMDatabaseConnection.R`).
#' This function parametrizes the cascaded upload with a given connection.
#'
#'
parametrize_cascaded_update <- function(mnmdb) {

  #' Take this, @roxygen! A function within a function to be returned
  #' for functional application.
  #' Here: the parametrized "update/cascade/lookup" function.
  #' How dare you do not handle this, @roxygen?
  #' Don't we agree that functions are first class citizens in R?!
  #'
  #' @param table_label the table lable
  #' @param new_data new data for upload
  #' @param index_columns colums which are returned in the lookup
  #' @param tabula_rasa empty the table prior to upload (fresh restart)
  #' @param characteristic_columns a subset of columns of the data table
  #'        by which old and new data can be uniquely identified and joined;
  #'        refers to the new data
  #' @param skip_sequence_reset do (or do not) reset the sequence columns
  #' @param verbose provides extra prose on the way, in case you need it
  #'
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
    # this is a rather abstract construct; hope R will work it.

    if (verbose) {
      message("________________________________________________________________")
      message(glue::glue("Cascaded update of {schema}.{table_label}"))
    }

    # characteristic columns := columns which uniquely define a data row,
    # but which are not the primary key.
    if (is.null(characteristic_columns)) {
      # in case no char. cols provided, just take all columns.
      characteristic_columns <- mnmdb$get_characteristic_columns(table_label)
    }

    ## (0) check that characteristic columns are UNIQUE:
    # the char. columns of the data to upload
    new_characteristics <- new_data %>%
      select(!!!characteristic_columns) %>%
      distinct()
    stopifnot("Error: characteristic columns are not characteristic!" =
      nrow(new_data) == nrow(new_characteristics))


    new_data_raw <- new_data

    # existing content
    prior_content <- mnmdb$query_table(table_label)
    # head(prior_content)
    # prior_content %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()


    ## (1) optionally append
    if (isFALSE(tabula_rasa)) {

      # columns must either be non-index, or in the new data
      # (to avoid case where existing indices are rowbound with NULL)
      subset_columns <- names(prior_content)
      subset_columns <- subset_columns[
        (!(subset_columns %in% index_columns))
        | (subset_columns %in% names(new_data))
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
      new_data <- bind_rows(
          existing_unchanged,
          new_data
        ) %>%
        distinct()
      # new_data %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
    } else {
      message(glue::glue("  Tabula rasa: no rows will be retained."))
    }

    ## do not upload index columns
    retain_cols <- names(new_data)
    retain_cols <- retain_cols[!(retain_cols %in% index_columns)]
    new_data <- new_data %>% select(!!!retain_cols)


    ### double safety: load/catch/restore
    table_content_storage <- mnmdb$store_table_deptree_in_memory(table_label)

    tryCatch({
      ### update datatable, propagating/cascading new keys to other's fk

      update_datatable_and_dependent_keys(
        mnmdb,
        table_label = table_label,
        new_data = new_data,
        characteristic_columns = characteristic_columns,
        skip_sequence_reset = skip_sequence_reset,
        verbose = verbose
      )
      # TODO rename_characteristics = rename_characteristics,
    }, error = function(wrnmsg) {
      message("\n")
      message("##########################")
      message("##### update failed! #####")
      message(glue::glue("--> FAILED uploading {nrow(new_data)} rows to {table_label} :"))
      message(wrnmsg)
      message("\nrestoring data.\n")
      invisible(
        mnmdb$restore_table_data_from_memory(table_content_storage)
      )
      return(NA)
    })


    lookup_deptab <- mnmdb$query_columns(
      table_key,
      c(characteristic_columns, index_columns)
      )

    if (verbose){
      message(sprintf(
        "%s: %i rows uploaded, were %i existing judging by '%s'.",
        mnmdb$get_namestring,
        nrow(new_data),
        nrow(prior_content),
        paste0(characteristic_columns, collapse = ", ")
      ))
    }

    return(lookup_deptab)

  } # /update_cascade_lookup

  return(ucl_function)
} # /parametrize_cascaded_update

