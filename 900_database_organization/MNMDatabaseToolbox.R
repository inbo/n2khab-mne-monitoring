


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
