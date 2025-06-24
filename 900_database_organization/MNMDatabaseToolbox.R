


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
#'        store a connection password
#'
#' @param config_filepath the path to the config file
#' @param working_dbname the target database name
#' @param table_key the table to be changed
#' @param new_data a data frame or tibble with the new data
#' @param profile config section header (configs with multiple connection settings)
#' @param dbstructure_folder the folder in which to find the database structire csv collection
#' @param characteristic_columns a subset of columns of the data table
#'        by which old and new data can be uniquely identified and joined; refers to the new data
#' @param rename_characteristics TODO link columns with different names by renaming them in new_data
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
#'    new_data <- dplyr::tbl(source_connection, DBI::Id(schema = "outbound", table = test_table)) %>% collect(),
#'    characteristic_columns = c("scheme", "stratum", "grts_address", "column_newname")
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
    characteristic_columns = NULL, # TODO
    rename_characteristics = NULL,
    verbose = TRUE
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("RPostgres" = require("RPostgres"))
  stopifnot("glue" = require("glue"))

  # establish a database connection
  db_target <- connect_database_configfile(
    config_filepath,
    database = working_dbname,
    profile = profile
  )

  if (is.null(dbstructure_folder)) {
    dbstructure_folder <- "db_structure"
  }

  schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, schema, geometry)

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
    here::here("dumps", glue::glue("safedump_{now}.sql")),
    config_filepath = config_filepath,
    database = working_dbname,
    profile = "dumpall",
    user = "monkey",
    exclude_schema = c("tiger", "public")
  )


  ### (2) load current data

  table_relations <- read_table_relations_config(
    storage_filepath = here::here("devdb_structure", "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key))

  dependent_tables <- table_relations %>% pull(dependent_table)

  table_existing_data_list <- query_tables_data(
      db_target,
      database = "loceval_dev",
      tables = lapply(c(table_key, dependent_tables), FUN = get_tableid)
  )


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
  }

  old_data <- query_columns(
    db_target,
    get_tableid(table_key),
    columns = c(characteristic_columns, pk)
  )

  # this data is not lost yet, but will be checked against the `new_data` to upload.
  lostrow_data <- dplyr::tbl(db_target, get_tableid(table_key)) %>% collect()

  # what about `sf` data?
  # - R function overloading: no matter if sf or not
  # - because geometry columns are skipped for `characteristic_columns`
  #       -> seems to work the same


  ### (5) UPLOAD/replace the data

  # use `rename_characteristics`
  # to rename cols in the new_data to the server data logic
  new_data
  rename_characteristics
  for (rnc in 1:length(rename_characteristics)) {
    new_colname <- rename_characteristics[[rnc]]
    server_colname <- names(rename_characteristics)[rnc]
    names(new_data)[names(new_data) == new_colname] <- server_colname
  }

  # TODO there must be more column match checks
  # prior to deletion
  # in connection with `characteristic_columns`

  # TODO write function
  # to restore key lookup table

  # DELETE existing data
  execute_sql(
    db_target,
    glue::glue("DELETE  FROM {get_namestring(table_key)};"),
    verbose = verbose
  )

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

  new_redownload <- query_columns(
    db_target,
    get_tableid(table_key),
    columns = c(characteristic_columns, pk)
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
  not_found <- pk_lookup %>%
    select(!!!rlang::syms(c(glue::glue("{pk}_old"), pk)))  %>%
    filter(if_any(everything(), ~ is.na(.x)))

  lost_rows <- lostrow_data %>%
    semi_join(
      not_found,
      by = pk
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


  ## update dependent tables
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
    if (!(reference_col_old %in% names(pk_lookup))) {
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
    key_replacement <- key_replacement[
      !mapply(identical,
        key_replacement[[reference_col_old]],
        key_replacement[[dependent_key]]
      )
    , ]

    if (nrow(key_replacement) == 0) next # nothing to update

    ### UPDATE the dependent table
    # ... by looking up the dependent table pk
    dep_pk <- get_primary_key(deptab)

    # repl_rownr <- 1
    get_update_row_string <- function(repl_rownr){
      dep_pk_val <- key_replacement[repl_rownr, dep_pk]
      val <- key_replacement[repl_rownr, dependent_key]
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
    for (cmd in update_command) {
      execute_sql(db_target, cmd, verbose = verbose)
    }

  } # /loop dependent tables


} #/update_datatable_recursively





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
    database,
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
    database_connection <- DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = database,
      host = host,
      port = port,
      user = user,
      password = password
    )
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
