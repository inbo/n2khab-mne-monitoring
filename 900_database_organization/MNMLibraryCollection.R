#!/usr/bin/env Rscript

# regularly used sets of libraries
# and POC data handling (interpreting POC prep as a library)

#_______________________________________________________________________________
# LIBRARIES

load_libraries <- function(libs) {
  load_lib <- function(...) {
    suppressPackageStartupMessages(library(...))
  }
  sapply(unique(libs), load_lib, character.only = TRUE)
  return(invisible(NULL))
}

#_______________________________________________________________________________
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

#_______________________________________________________________________________
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

#_______________________________________________________________________________
spatial_data_handling_libraries <- c(
  "sf",
  "terra"
)
load_spatial_data_handling_libraries <- function(
  ) load_libraries(spatial_data_handling_libraries)
# load_spatial_data_handling_libraries()

#_______________________________________________________________________________
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

load_poc_rdata <- function(data_basepath = "./data", reload = FALSE, to_env = parent.frame()) {

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

    googledrive::drive_download(
      googledrive::as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"),
      path = poc_rdata_path,
      overwrite = reload
    )
  }
  load(poc_rdata_path, envir = to_env)

} # /load_poc_rdata


load_poc_code_snippets <- function(base_path = NA) {

  if (is.na(base_path)) {
    base_path <- rprojroot::find_root(is_git_root)
  }

  source(file.path(base_path, "020_fieldwork_organization/R/grts.R"))
  source(file.path(base_path, "020_fieldwork_organization/R/misc.R"))

  invisible(capture.output(source("050_snippet_selection.R")))
  source("051_snippet_transformation_code.R")


} # /load_poc_code_snippets



verify_poc_objects <- function() {

  versions_required <- c(versions_required, "habitatmap_2024_v99_interim")
  verify_n2khab_data(n2khab_data_checksums_reference, versions_required)


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


  # shout out success!
  message("All expected environment objects were found.")

} # /verify_poc_objects


#_______________________________________________________________________________
