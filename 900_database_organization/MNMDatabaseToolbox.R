

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
    profile = 1 # use the first profile by default
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
}
