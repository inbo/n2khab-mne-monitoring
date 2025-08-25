

is.scalar.na <- function(checkvar) is.atomic(checkvar) && (length(checkvar) == 1) && is.na(checkvar)


load_table_info <- function(subfolder, tablelabel){
  table_info <- read.csv(
    here::here(subfolder, glue::glue("{tablelabel}.csv"))
  )
  return(table_info)
}

query_columns <- function(db_connection, table_id, columns){
  dplyr::tbl(db_connection, table_id) %>%
    dplyr::select(!!!rlang::syms(columns)) %>%
    dplyr::collect()
}


# query_columns(db_connection, get_tableid(table_key), c("protocol_id", "description"))
query_tables_data <- function (db_connection, database, tables) {
  data <- lapply(
    tables,
    FUN = function(tablelabel) {
        dplyr::collect(dplyr::tbl(db_connection, tablelabel))
      }
  )
  return(data)
}



execute_sql <- function(db_connection, sql_command, verbose = TRUE) {
  # a rather trivial wrapper for dbExecute
  # which doesn't even work for multi-commands :/

  if (verbose) {
    message(sql_command)
  }

  stopifnot("DBI" = require("DBI"))

  rs <- DBI::dbExecute(db_connection, sql_command)

  if (verbose) {
    message("done.")
  }

  return(invisible(rs))

}


# TODO: option to drop; but mind cascading

# this function loads the content of a table, and then uploads only
# the new rows which are not already present (as judged by some
# reference columns).
append_tabledata <- function(conn, db_table, data_to_append, reference_columns = NA){
  content <- DBI::dbReadTable(conn, db_table)
  # head(content)

  if (any(is.na(reference_columns))) {
    # ... or just take all columns
    reference_columns <- names(data_to_append)
  }

  # refcol <- enquo(reference_columns)
  existing <- content %>% select(!!!reference_columns)
  to_upload <- data_to_append %>%
    anti_join( existing, join_by(!!!reference_columns)
  )

  rs <- DBI::dbWriteTable(conn, db_table, to_upload, overwrite = FALSE, append = TRUE)
  # res <- DBI::dbFetch(rs)
  # DBI::dbClearResult(rs)

  message(sprintf(
    "%s: %i rows uploaded, %i/%i existing judging by '%s'.",
    toString(db_table),
    nrow(to_upload),
    nrow(existing),
    nrow(data_to_append),
    paste0(reference_columns, collapse = ", ")
  ))
  return(invisible(rs))

} #/ append_tabledata


upload_and_lookup <- function(conn, db_table, data, ref_cols, index_col) {

  append_tabledata(conn, db_table, data, reference_columns = ref_cols)

  lookup <- dplyr::tbl(conn, db_table) %>%
    select(!!!c(ref_cols, index_col)) %>%
    collect

  return(lookup)
}


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


# procedure to loop through a table
# which is linked to "Locations" via `location_id`
# and restore the correct id.
# This is necessary because previously assembled data is
#   in some cases retained, but
#   would loose links to the pruned "Locations" after rearrangement.
restore_location_id_by_grts <- function(
      db_connection,
      dbstructure_folder,
      target_schema,
      table_key,
      retain_log = FALSE,
      verbose = FALSE
    ) {


  # know table relations to get the pk
  table_relations <- read_table_relations_config(
    storage_filepath = here::here(dbstructure_folder, "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key))

  pk <- load_table_info(dbstructure_folder, table_key) %>%
      filter(primary_key == "True") %>%
      pull(column)

  target_namestring <- glue::glue('"{target_schema}"."{table_key}"')

  # query the status quo
  location_lookup <- dplyr::tbl(
    db_connection,
    DBI::Id("metadata", "Locations")
    ) %>%
    select(grts_address, location_id) %>%
    collect

  # optional: store and retain "log_" columns
  # TODO (though I fear this did not work)
  target_cols <- c(pk, "grts_address")
  if (retain_log) {
    target_cols <- c(pk, "grts_address", "log_user", "log_update")
  }

  target_lookup <- dplyr::tbl(
    db_connection,
    DBI::Id(target_schema, table_key)
    ) %>%
    select(!!!target_cols) %>%
    collect

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
    execute_sql(db_connection, cmd, verbose = FALSE)
  }

  if (verbose) close(pb) # close the progress bar

  # TODO this is sluggish, of course; I would rather prefer a combined UPDATE.

}



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
  get_schema <- function(tablelabel) {
    return(schemas %>%
      filter(table == tablelabel) %>%
      pull(schema)
    )
  }
  get_namestring <- function(tablelabel) glue::glue('"{get_schema(tablelabel)}"."{tablelabel}"')
  get_tableid <- function(tablelabel) DBI::Id(schema = get_schema(tablelabel), table = tablelabel)


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
  get_primary_key <- function(tablelabel){
    pk <- load_table_info(dbstructure_folder, tablelabel) %>%
      filter(primary_key == "True") %>%
      pull(column)
    return(pk)
  }

  get_characteristic_columns <- function(tablelabel){

    # excluded from checks
    logging_columns <- c("log_user", "log_update", "geometry", "wkb_geometry")

    full_table_info <- load_table_info(dbstructure_folder, tablelabel)

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


  # query_columns(db_connection, get_tableid(table_key), c("protocol_id", "description"))
  # deptab_key <- "GroupedActivities"
  query_dependent_columns <- function(table_key, deptab_key) {

    # with a little help from my Python
    deptab_pk <- get_primary_key(deptab_key)

    # get the foreign key columns
    dependent_key <- table_relations %>%
      filter(
        relation_table == tolower(table_key),
        dependent_table == deptab_key
      ) %>%
      pull(dependent_column)

    # lookup the key columns
    key_lookup <- query_columns(
      db_target,
      get_tableid(deptab_key),
      c(deptab_pk, dependent_key)
    )

    return(key_lookup)
  }

  lookups <- lapply(
    dependent_tables,
    FUN = function(deptab_key) query_dependent_columns(table_key, deptab_key)
  ) %>% setNames(dependent_tables)

  ### (4) retrieve old data
  pk <- get_primary_key(table_key)

  if (is.null(characteristic_columns)) {
    characteristic_columns <- get_characteristic_columns(table_key)
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

    dep_pk <- get_primary_key(deptab)

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
  pk_lookup <- old_data %>%
    left_join(
      new_redownload,
      by = characteristic_columns,
      relationship = "one-to-one",
      suffix = c("_old", ""),
      unmatched = "drop"
    )


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
    dep_pk <- get_primary_key(deptab)

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


# the first entry is the table itself
# find_dependent_tables("mnmgwdb_db_structure", "Visits")
find_dependent_tables <- function(dbstructure_folder = "db_structure", table_key) {
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
load_table_content <- function(
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
restore_table_data_from_memory <- function(
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
  get_primary_key <- function(tablelabel){
    pk <- load_table_info(dbstructure_folder, tablelabel) %>%
      filter(primary_key == "True") %>%
      pull(column)
    return(pk)
  }

  pk <- get_primary_key(table_key[[2]])

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



parametrize_cascaded_update <- function(
    config_filepath,
    working_dbname,
    connection_profile,
    dbstructure_folder,
    db_connection
  ) {

  ucl_function <- function(
      schema,
      table_key,
      new_data,
      index_columns,
      tabula_rasa = FALSE,
      characteristic_columns = NULL,
      skip_sequence_reset = FALSE,
      verbose = TRUE
    ) {

    db_table <- DBI::Id(schema = schema, table = table_key)

    if (verbose) {
      message("________________________________________________________________")
      message(glue::glue("Cascaded update of {schema}.{table_key}"))
    }

    # characteristic columns := columns which uniquely define a data row,
    # but which are not the primary key.
    if (is.null(characteristic_columns)) {
      # in case no char. cols provided, just take all columns.
      characteristic_columns <- names(new_data)
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
    prior_content <- dplyr::tbl(
      db_connection,
      db_table
    ) %>% collect()
    # head(prior_content)


    ## (1) optionally append
    if (!tabula_rasa) {

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
      }

      # combine existing and new data
      to_upload <- bind_rows(
          existing_unchanged,
          to_upload
        ) %>%
        distinct()
    } else {
        message(glue::glue("  Tabula rasa: no rows will be retained."))
    }

    ## do not upload index columns
    retain_cols <- names(to_upload)
    retain_cols <- retain_cols[!(retain_cols %in% index_columns)]
    to_upload <- to_upload %>% select(!!!retain_cols)


    ### double safety: load/catch/restore
    # savetabs <- find_dependent_tables("mnmgwdb_db_structure", "Visits")
    savetabs <- find_dependent_tables(dbstructure_folder, table_key)

    load_table_content_this_connection <- function(table_id) {
      return(load_table_content(db_connection, dbstructure_folder, table_id))
    }

    table_content_storage <- lapply(savetabs, FUN = load_table_content_this_connection)


    restore_table_content_this_connection <- function(content_list) {
      restore_table_data_from_memory(
        db_connection,
        content_list,
        dbstructure_folder = dbstructure_folder,
        verbose = TRUE
      )
    }


    tryCatch({
      ### update datatable, propagating/cascading new keys to other's fk

      update_datatable_and_dependent_keys(
        config_filepath = config_filepath,
        working_dbname = working_dbname,
        table_key = table_key,
        new_data = to_upload,
        profile = connection_profile,
        dbstructure_folder = dbstructure_folder,
        db_connection = db_connection,
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
      invisible(lapply(
        table_content_storage,
        FUN = restore_table_content_this_connection
      ))
      return(NA)
    })


    lookup <- dplyr::tbl(
        db_connection,
        db_table
      ) %>%
      select(!!!c(characteristic_columns, index_columns)) %>%
      collect

    if (verbose){
      message(sprintf(
        "%s: %i rows uploaded, were %i existing judging by '%s'.",
        toString(db_table),
        nrow(to_upload),
        nrow(prior_content),
        paste0(characteristic_columns, collapse = ", ")
      ))
    }

    return(lookup)

  } # /update_cascade_lookup
  return(ucl_function)
} # /parametrize_cascaded_update


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
