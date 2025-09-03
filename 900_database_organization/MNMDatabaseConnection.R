#!usr/bin/env Rscript

# poor man's OOP: the database connection list object
# supposed to be loaded prior to "DatabaseToolbox"

#_______________________________________________________________________________
### TABLE OF CONTENTS
#
# Conventions:
# - `table_namestring` is the SQL table reference including quotes,
#     e.g. `"metadata"."TeamMembers"`
# - `table_label` is just the case sensitive table name, e.g. `TeamMembers`
# - `table_key` is tha same as label, but can be all lowercase, e.g. `teammembers`
# - `table_id` is the DBI table identifier,
#     e.g. DBI::Id(schema = "metadata", table = "TeamMembers")
# - `db$` is the abstract variable name / `mnmdb$` is the same in applications
#    (analogous to class / object dualism)
#
# The `db$` (list) object brings functions and general structural information.
# These functions are limited: they cannot change the `db$` object,
# nor store data in R (though note that some functions do, of course, change
# database content.
#
# +---------------------------------------------------------------------+
# | `db$` / `mnmdb$` bring database structure and references with them. |
# +---------------------------------------------------------------------+
#   no less, no more.

# SQL Basics
# > execute_sql(mnmdb, sql_command, verbose = TRUE) -> invisible(result)
# > dump_all <- function(
#     config_filepath, database_to_dump, target_filepath,
#     connection_profile = "dumpall", exclude_schema = NULL) -> [file]
# > append_tabledata <- function(
#     db_connection, table_id, data_to_append,
#     characteristic_columns = NA, verbose = TRUE ) -> [sql]
#
# Database Structure
# > read_table_relations_config(storage_filepath) -> relation_lookup
#
# Connection Handling
# > connect_database_configfile(
#     config_filepath, database, profile, host, port, user, password
#   ) -> database_connection
#
# Database Workhorse
# > connect_mnm_database(
#     config_filepath,
#     database_mirror = NA,
#     skip_structure_assembly = FALSE,
#     [... -> connection_database_configfile]
#   ) -> mnmdb
#   - db$connection_profile
#   - db$folder
#   - db$host
#   - db$port
#   - db$database
#   - db$user
#   - db$shellstring
#   - db$connection
#   - db$execute_sql(self, ...) -> [reparametrization]
#   - db$dump_all(self, ...) -> [reparametrization]
# > mnmdb_assemble_structure_lookups(db) -> db
#   - db$tables
#   - db$table_relations
#   - db$excluded_tables
#   - db$get_schema(table_label) -> character
#   - db$get_namestring(table_label) -> character
#   - db$get_table_id(table_label) -> DBI::Id
#   - db$get_table_id_lowercase(table_key) -> DBI::Id
#   - db$get_dependent_tables(table_key) -> c(key, df)
#   - db$get_dependent_table_ids(table_key) -> list(DBI::Id)
#   - db$load_table_info(table_label) -> df(table info)
#   - db$get_characteristic_columns(table_label) -> c(column names)
#   - db$get_primary_key(table_label) -> character(pk)
# > mnmdb_assemble_query_functions(db) -> db
#   - db$query_columns(table_label, select_columns) -> df(columns)
#   - db$pull_column(table_label, select_column) -> c()
#   - db$is_spatial(table_key) -> bool
#   - db$query_table(table_label) -> df
#   - db$query_tables_data(tables) -> list(df)
#   - db$lookup_dependent_columns(table_label, deptab_label) -> df(pk, fk)
#   - db$set_sequence_key(table_label, new_key_value, sequence_label, verbose)
#   - db$store_table_deptree_in_memory(table_label) -> list("label", "data")
#   - db$restore_table_data_from_memory(table_content_storage, verbose)
#   - db$insert_data(table_label, new_data)
#   - db$delete_unused(table_label, sql_filter_unused)

#_______________________________________________________________________________
### SQL BASICS

is.scalar.na <- function(checkvar) {
  return(
    is.atomic(checkvar) &&
    (length(checkvar) == 1) &&
    is.na(checkvar)
  )
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

#' dump the database with a system call to `pg_dump` (linux)
#'
#' @details To apply this from scripts, password is not used. Make sure
#' to configure your `~/.pgpass` file for a read only user, or configure
#' a "dumpall" entry in your config.
#'
#' @param mnmdb an MNM database including DBI connection, structure, and
#'        working functions. See `MNMDatabaseConnection.R` for details.
#' @param target_filepath triv.
#' @param exclude_schema schemata to exclude, e.g. c("tiger", "public")
#'
#' @examples
#' \dontrun{
#'   now <- format(Sys.time(), "%Y%m%d%H%M")
#'   dump_all(
#'     config_filepath = file.path("./postgis_server.conf"),
#'     database_to_dump = "mnmdb-testing",
#'     here::here(glue::glue("dumps/safedump_{now}.sql")),
#'     exclude_schema = c("tiger", "public")
#'   )
#' }
#'
dump_all <- function(
    config_filepath,
    database_to_dump,
    target_filepath,
    connection_profile = "dumpall",
    exclude_schema = NULL
  ) {
  # database_to_dump <- "loceval_dev"

  stopifnot(
    "configr" = require("configr"),
    "glue" = require("glue"),
    "here" = require("here")
  )

  config <- configr::read.config(file = config_filepath)[[connection_profile]]

  dump_connection <- connect_database_configfile(
    config_filepath = config_filepath,
    database = database_to_dump,
    profile = connection_profile,
    password = NA
  )

  shellstring <- glue::glue(
    "-U {config$user} -h {config$host} -p {config$port} -d {database_to_dump}"
    )

  # exclude some schemas
  exschem_string <- " "
  if (!is.null(exclude_schema)) {

    exschem_string <- c()
    for (exschem in exclude_schema){
      exschem_string <- c(exschem_string, glue::glue("-N {exschem}"))
    }
    exschem_string <- paste(exschem_string, collapse = " ")
  }


  # dump the database!
  dump_string <- glue::glue('
    pg_dump {shellstring} {exschem_string} --no-password -c > "{target_filepath}"
    ')

  system(dump_string)

} # /dump_all


#' Append data to a table which is not already in there.
#'
#' This function loads the content of a table, and then uploads only
#' the new rows which are not already present (as judged by some
#' characteristic columns).
#'
#' @param db_connection an existing database connection, optionally passed
#'        to prevent repeated connection in scripts
#' @param table_id a DBI::Id of the table to append
#' @param data_to_append triv.
#' @param characteristic_columns a subset of columns of the data table
#'        by which old and new data can be uniquely identified and joined;
#'        refers to the new data
#' @param verbose provides extra prose on the way, in case you need it
#'
append_tabledata <- function(
    db_connection,
    table_id,
    data_to_append,
    characteristic_columns = NA,
    verbose = TRUE
  ) {


  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))

  content <- DBI::dbReadTable(db_connection, table_id)
  # head(content)

  if (any(is.na(characteristic_columns))) {
    # ... or just take all columns
    characteristic_columns <- names(data_to_append)
  }

  # refcol <- enquo(characteristic_columns)
  existing <- content %>% dplyr::select(!!!characteristic_columns)
  to_upload <- data_to_append %>%
    dplyr::anti_join(existing, dplyr::join_by(!!!characteristic_columns)
  )

  rs <- DBI::dbWriteTable(
    db_connection,
    table_id,
    to_upload,
    overwrite = FALSE,
    append = TRUE
  )
  # res <- DBI::dbFetch(rs)
  # DBI::dbClearResult(rs)

  message(sprintf(
    "%s: %i rows uploaded, %i/%i existing judging by '%s'.",
    toString(table_id),
    nrow(to_upload),
    nrow(existing),
    nrow(data_to_append),
    paste0(characteristic_columns, collapse = ", ")
  ))

  return(invisible(rs))

} #/ append_tabledata


#_______________________________________________________________________________
### STRUCTURE

#' Read a table relation config file and convert it to data frame.
#'
#' Database structure is generated from a spreadsheet document. There is one
#' special file which stores the database structure, i.e. the relations of
#' tables to each other. It is generated by the adjacent Python scripts and read
#' in via `configr`. This function helps to load that relations file.
#'
#' @param storage_filepath the path to the config file
#'
#' @return data frame with the column relations from a dependent to a relation
#'     table. Note that relation table names are lowercase due to some
#'     ConfigParser limitation.
#'
#' @examples
#' \dontrun{
#'   read_table_relations_config(
#'     storage_filepath = file.path(
#'       "./devdb_structure/table_relations.conf"
#'   ))
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

} # /read_table_relations_config


#_______________________________________________________________________________
# CONNECTION HANDLING

#' Connect to a postgreSQL database, using settings from a config file
#'
#' Connect to a postgreSQL database (other dialects trivial).
#' Connection settings are loaded from a config file, content such as
#'     [profile-name]
#'     folder = ./dbstructure
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


#_______________________________________________________________________________
# DATABASE WORKHORSE

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
    skip_structure_assembly = FALSE,
    ... # -> connect_database_configfile
  ) {
  # database_mirror <- "mnmgwdb-staging"

  stopifnot(
    "glue" = require("glue"),
    "DBI" = require("DBI"),
    "keyring" = require("keyring"),
    "configr" = require("configr")
  )
  stopifnot("provide database mirror" = isFALSE(is.na(database_mirror)))

  # collect db connection
  db <- list()
  db$connection_profile <- database_mirror

  # load profile
  config <- configr::read.config(file = config_filepath)[[db$connection_profile]]

  for (cfg in attributes(config)$names) {
    if (cfg == "password") next
    db[[cfg]] <- config[[cfg]]
  }

  # args can overwrite config and must be stored correctly
  args <- list(...)
  for (arg in names(args)) {
    if (arg == "password") next
    db[[arg]] <- args[[arg]]
  }

  # connect
  # db$connection <- connect_database_configfile(
  #   config_filepath,
  #   profile = database_mirror,
  #   database = config$database
  # )
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

  # shell string for psql use
  db$shellstring <- glue::glue("-U {db$user} -h {db$host} -p {db$port} -d {db$database}")

  # direct execution
  db$execute_sql <- function(...) {return(execute_sql(db$connection, ...))}
  # db$execute_sql('SELECT last_value FROM "metadata".seq_protocol_id;')

  db$dump_all <- function(...) {return(dump_all(config_filepath, db$database, ...))}
  # db$dump_all("dumps/test.sql", exclude_schema = c("tiger", "public"))

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
  # db$tables %>% knitr::kable()

  # this one is created by python scripts
  db$table_relations <- read_table_relations_config(
    storage_filepath = here::here(db$folder, "table_relations.conf")
    )
  # db$table_relations %>% knitr::kable()

  # some tables are excluded
  db$excluded_tables <- db$tables %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)
  # db$excluded_tables %>% knitr::kable()

  # get schema for a table
  db$get_schema <- function(table_label) {
    return(
      db$tables %>%
        filter(table == table_label) %>%
        pull(schema)
    )
  }
  # db$get_schema("GroupedActivities")

  # get namestring as used in direct SQL queries
  db$get_namestring <- function(table_label) glue::glue(
    '"{db$get_schema(table_label)}"."{table_label}"'
  )
  # db$get_namestring("TeamMembers")

  # get table Id as used DBI/dbplyr queries
  db$get_table_id <- function(table_label) DBI::Id(
    schema = db$get_schema(table_label),
    table = table_label
  )
  # db$get_table_id("LocationCells")

  # same as above, but from lowercase table key
  db$get_table_id_lowercase <- function(table_key) {
    schema <- db$tables %>%
      filter(tolower(table) == tolower(table_key)) %>%
      pull(schema)
    tkey_correct <- db$tables %>%
      filter(tolower(table) == tolower(table_key)) %>%
      pull(table)
    return(DBI::Id(schema, tkey_correct))
  }
  # db$get_table_id_lowercase("locationcells")


  ### table dependency structure
  db$get_dependent_tables <- function(table_key) {
    return(c(
      table_key,
      db$table_relations %>%
      filter(tolower(relation_table) == tolower(table_key),
        !(dependent_table %in% db$excluded_tables)
      ) %>% pull(dependent_table)
    ))
  }
  # db$get_dependent_tables("Locations")

  # return table IDs for all dependent tables
  db$get_dependent_table_ids <- function(table_key) {
    deptabs <- db$get_dependent_tables(table_key)
    lapply(
        deptabs,
        FUN = db$get_table_id_lowercase
      ) %>%
      setNames(deptabs) %>%
      return()
  }
  # db$get_dependent_table_ids("Locations")

  # specific table info
  db$load_table_info <- function(table_label) {
    table_info <- read.csv(
      here::here(db$folder, glue::glue("{table_label}.csv"))
    )
    return(table_info)
  }
  # db$load_table_info("FreeFieldNotes")


  db$get_characteristic_columns <- function(table_label) {

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
  # db$get_characteristic_columns("FreeFieldNotes")


  # or need a primary key?
  db$get_primary_key <- function(table_label) {
    return(
      db$load_table_info(table_label) %>%
        filter(primary_key == "True") %>%
        pull(column)
    )
  }
  # db$get_primary_key("FreeFieldNotes")

  # the result: a database object with more features
  return(db)
} # /mnmdb_assemble_structure_lookups


mnmdb_assemble_query_functions <- function(db) {
  ## testing:
  # table_label <- "Locations"
  # table_key <- table_label
  # select_column <- "location_id"
  # select_columns <- c("grts_address", "location_id")

  db$query_columns <- function(table_label, select_columns) {
    dplyr::tbl(db$connection, db$get_table_id(table_label)) %>%
      dplyr::select(!!!rlang::syms(select_columns)) %>%
      dplyr::collect() %>%
      return()
  }
  # db$query_columns(table_label, select_columns)
  # db$query_columns("Protocols", c("protocol_id", "description"))

  db$pull_column <- function(table_label, select_column) {
    dplyr::tbl(db$connection, db$get_table_id(table_label)) %>%
      dplyr::select(!!select_column) %>%
      dplyr::collect() %>%
      dplyr::pull(!!select_column) %>%
      return()
  }
  # db$pull_column(table_label, db$get_primary_key(table_label)) %>% max()

  db$is_spatial <- function(table_key) {
    read.csv(here::here(db$folder, "TABLES.csv")) %>%
      select(table, geometry) %>%
      filter(tolower(table) == tolower(table_key)) %>%
      pull(geometry) %>%
      {is.na(.) || (. == "")} %>%
      isFALSE() %>%
      return()
    # attr(table_id, "name")[[2]] # would be the variant for a DBI::Id
  }
  # db$is_spatial("FreeFieldNotes")
  # db$is_spatial("LocationInfos")

  db$query_table <- function(table_label) {

    table_id <- db$get_table_id(table_label)
    if (db$is_spatial(table_label)) {
      data <- sf::st_read(db$connection, layer = table_id) %>%
        select(-ogc_fid) %>%
        collect
      sf::st_geometry(data) <- "wkb_geometry"
    } else {
      data <- dplyr::tbl(db$connection, table_id) %>% collect
    }
    data <- data %>% as_tibble

    return(data)
  }
  # db$query_table("FreeFieldNotes") %>% head(2) %>% t() %>% knitr::kable()

  db$query_tables_data <- function(tables) {
    lapply(
        tables,
        FUN = db$query_table
      ) %>%
      setNames(tables) %>%
      return()
  }
  # db$query_tables_data(c("GroupedActivities", "Protocols", "TeamMembers"))

  # all dependent lookup columns
  db$lookup_dependent_columns <- function(table_label, deptab_label) {
    # db <- mnmdb
    # deptab_label <- dependent_tables[[1]]

    if (table_label == deptab_label) return(NA)

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
  # db$lookup_dependent_columns("Protocols", "GroupedActivities")


  # Set table sequence key; defaults to "1" (=reset), can do "max" (current highest).
  # No keys are harmed when executing this function.
  db$set_sequence_key <- function(
      table_label,
      new_key_value = NULL,
      sequence_label = NULL,
      verbose = FALSE
    ) {
    # db <- mnmdb
    # sequence_label <- "seq_replacementarchive_id"

    # primary key -> related to sequence label
    pk <- db$get_primary_key(table_label)

    if (is.null(sequence_label)) {
      sequence_label <- glue::glue('"{db$get_schema(table_label)}".seq_{pk}')
    }

    # log pre/post values
    key_log <- list("label" = sequence_label)

    # check current value
    nextval_query <- glue::glue("SELECT last_value FROM {sequence_label};")
    current_highest <- DBI::dbGetQuery(db$connection, nextval_query)[[1, 1]]
    key_log$pre <- current_highest

    if (is.null(new_key_value)) {
      new_key_value <- "1"
      # set to one because data is re-inserted
      db$execute_sql(
        glue::glue(
          "ALTER SEQUENCE {sequence_label} RESTART WITH {new_key_value};"
        ),
        verbose = verbose
      )

      key_log$post <- new_key_value

      return(invisible(key_log))

    } else if (new_key_value == "max") {
      # set to current max value in the database
      nextval <- DBI::dbGetQuery(db$connection, nextval_query)[[1, 1]]
      max_pk <- db$pull_column(table_label, pk) %>% max
      new_key_value <- max(c(nextval, max_pk))

    }

    if (is.na(new_key_value)) new_key_value <- "1"

    # set the key, either to given value, or to current "max"
    db$execute_sql(
      glue::glue("SELECT setval('{sequence_label}', {new_key_value});"),
      verbose = verbose
    )

    # return log
    key_log$post <- new_key_value
    return(invisible(key_log))

  } # /set_sequence_key
  # table_label <- "Protocols"
  # db$set_sequence_key(table_label, verbose = TRUE)
  # db$set_sequence_key("Protocols", "max", verbose = TRUE)

  # temporarily store table and dependencies in memory
  db$store_table_deptree_in_memory <- function(table_label) {
    # savetabs <- find_dependent_tables("mnmgwdb_db_structure", "Visits")
    savetabs <- db$get_dependent_tables(table_label)

    lapply(
        savetabs,
        FUN = function(tablab) db$query_table(tablab)
      ) %>%
      setNames(savetabs) %>%
      return()
  }
  # table_content_storage <- db$store_table_deptree_in_memory(table_label)

  # push table from memory back to the server
  #   involves key resetting
  #   and the usual "delete / append" strategy
  db$restore_table_data_from_memory <- function(table_content_storage, verbose = TRUE) {
    # table_content_storage <- store

    restore_ <- function(idx) {
      # idx <- 1

      table_label <- names(table_content_storage)[[idx]]
      schema <- db$get_schema(table_label)
      table_id <- db$get_table_id(table_label)
      table_data <- table_content_storage[[idx]]

      if (is.scalar.na(table_data) || (nrow(table_data) < 1)) {
        message("no data to restore.")
        return(invisible(NA))
      }

      # restore data
      pk <- db$get_primary_key(table_label)

      # Note that I neglect dependent table here, since they will be re-uploaded after
      # delete from table
      db$execute_sql(
        glue::glue("DELETE FROM {db$get_namestring(table_label)};"),
        verbose = verbose
      )

      # reset the sequence
      db$set_sequence_key(table_label)

      # append the table data
      db$insert_data(table_label, table_data)
      # append_tabledata(db$connection, table_id, table_data)

      # restore sequence
      db$set_sequence_key(table_label, "max")

      return(invisible(NULL))
    }

    # list-restore
    invisible(
      lapply(seq_len(length(table_content_storage)), FUN = restore_)
    )

    return(invisible(NULL))
  } # /restore_table_data_from_memory


  # insert table data
  db$insert_data <- function(table_label, upload_data) {
    # db <- mnmdb
    # upload_data <- data_replacement

    if ("ogc_fid" %in% names(upload_data)) {
      # do not upload this technical location key
      upload_data <- upload_data %>% select(-ogc_fid)
    }

    # ? geometry // spatial data
    if (db$is_spatial(table_label)) {
      ## insert spatial data

      upload_data <- sf::st_as_sf(upload_data)
      type_count <- as_tibble(sf::st_geometry_type(upload_data)) %>%
        count(value)

      if (nrow(type_count) > 1) {
        type_most <- type_count %>%
          arrange(desc(n)) %>%
          head(1) %>%
          pull(value)
        upload_data <- sf::st_cast(upload_data, as.character(type_most))
      }

      sf::st_geometry(upload_data) <- "wkb_geometry"

      rs <- sf::st_write(
        upload_data,
        db$connection,
        db$get_table_id(table_label),
        row.names = FALSE,
        delete_layer = FALSE, # "overwrite"
        append = TRUE,
        factorsAsCharacter = TRUE,
        binary = TRUE
      )

    } else {

      # regular, non-geometry data
      rs <- DBI::dbWriteTable(
        db$connection,
        db$get_table_id(table_label),
        upload_data,
        row.names = FALSE,
        overwrite = FALSE,
        append = TRUE,
        factorsAsCharacter = TRUE,
        binary = TRUE
      )
    }

    return(invisible(rs))
  }

  # remove all rows which have not noticably changed from their inception state
  db$delete_unused <- function(table_label, sql_filter_unused) {

    maintenance_users <- paste(
      c("update", "maintenance", db$user),
      collapse = "', '"
    )

    cleanup_query <- glue::glue(
      "DELETE FROM {db$get_namestring(table_label)}
        WHERE log_user IN ('{maintenance_users}')
          AND {sql_filter_unused}
      ;" # landowner will be script-updated (outbound)
    )

    db$execute_sql(cleanup_query, verbose = TRUE)
  }


  return(db)

} # /mnmdb_assemble_query_functions


