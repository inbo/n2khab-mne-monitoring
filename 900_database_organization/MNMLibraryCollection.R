#!/usr/bin/env Rscript

# regularly used sets of libraries
# and REP data handling (interpreting REP prep as a library)

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
rep_common_libraries <- c(
  "magrittr",
  "dplyr",
  "tidyr",
  "stringr",
  "digest",
  "purrr",
  "lubridate",
  "googledrive",
  "readr",
  "rprojroot",
  "sf",
  "terra",
  "n2khab"
)
load_rep_common_libraries <- function(
  ) load_libraries(rep_common_libraries)
# load_rep_common_libraries()

#_______________________________________________________________________________
database_interaction_libraries <- c(
  "configr",
  "keyring",
  "DBI",
  "RPostgres",
  "dplyr",
  "sf",
  "here",
  "getPass",
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
# REP DATA AND CODE

load_rep_rdata <- function(data_basepath = file.path(".", "data"), reload = FALSE, to_env = parent.frame()) {

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

  # Download and load R objects from the REP into global environment
  # reload <- FALSE # in this one, we normally reload.
  rep_rdata_path <- file.path(data_basepath, "objects_panflpan5.RData")
  if (reload || !file.exists(rep_rdata_path)){

    # copy the old file
    if (file.exists(rep_rdata_path)) {
      this_date <- format(Sys.time(), "%Y%m%d")
      backup_path <- file.path(data_basepath, glue::glue("objects_panflpan5_{this_date}.bak"))
      file.copy(from = rep_rdata_path, to = backup_path, overwrite = TRUE)
    }

    googledrive::drive_download(
      googledrive::as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"),
      path = rep_rdata_path,
      overwrite = reload
    )
  }
  load(rep_rdata_path, envir = to_env)

} # /load_rep_rdata


reload_rep_code_snippets <- function(fresh_snippet_path = NULL, to_env = NULL) {

  # libraries must be re-loaded
  load_rep_common_libraries()

  # must source the original code as well to avoid outdated/wrong functions
  if (!exists("snippet_base_path")) {
    snippet_base_path <- rprojroot::find_root(is_git_root)
  }

  grts_mh <- n2khab::read_GRTSmh()

  grts_mh_index <- dplyr::tibble(
      id = seq_len(terra::ncell(grts_mh)),
      grts_address = values(grts_mh)[, 1]
    ) %>%
    dplyr::filter(!is.na(grts_address))

  source_snippet_supplements <- function(file_name) {
    source(file.path(snippet_base_path, "020_fieldwork_organization", "R", file_name))
  }
  source_snippet_supplements("system_helpers.R")
  source_snippet_supplements("misc.R")
  source_snippet_supplements("repetitive_join_functions.R")
  source_snippet_supplements("grts.R")
  source_snippet_supplements("grts_mh.R")
  source_snippet_supplements("location_attribute_processing.R")
  source_snippet_supplements("calendar_operations_and_priorities.R")


  if (is.null(to_env)) {
    to_env = globalenv()
  }

  if (is.null(fresh_snippet_path)) {
    fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
  }

  # load variables into environment
  load(fresh_snippet_path, envir = to_env)

} # /load_rep_code_snippets



verify_rep_objects <- function() {

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

  # fieldwork calendar
  stopifnot(
    "NOT FOUND: snip snap >> `fieldwork_shortterm_prioritization_by_stratum`" =
      exists("fieldwork_shortterm_prioritization_by_stratum")
  ) # implies fag_stratum_grts_calendar_shortterm_attribs and fag_stratum_grts_calendar

  # replacements
  stopifnot(
    "NOT FOUND: snip snap >> `stratum_schemepstargetpanel_spsamples_terr_replacementcells`" =
      exists("stratum_schemepstargetpanel_spsamples_terr_replacementcells")
  )

  # orthophotos
  stopifnot(
    "snip snap >> `orthophoto grts` not found" =
      exists("orthophoto_shortterm_type_grts")
  )

  # shout out success!
  message("All expected environment objects were found.")

} # /verify_rep_objects


#_______________________________________________________________________________
