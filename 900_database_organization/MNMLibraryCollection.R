
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
