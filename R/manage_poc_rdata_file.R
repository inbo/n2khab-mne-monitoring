
#' Download the latest POC RData file from google drive.
#'
#' Will pull the latest MNE POC data file from google drive.
#'
#' @details For MNE project initiation, we work with an `.RData` file
#' to co-ordinate work efforts, development, and testing on the
#' preliminary sample. The plan is to later publish that data file
#' with releases on this repo, or replace it by a dynamic query of the
#' sampling frame and sample.
#'
#' @param sample_filepath the `file.path` to store the sample locally
#' @param overwrite passed through to `?googledrive::drive_download`
#'
#' @examples
#' \dontrun{
#'   force_reload <- TRUE
#'   sample_filepath <- file.path("data/latest_POC.RData")
#'
#'   if (force_reload || !file.exists(sample_filepath)) {
#'     download_poc_rdata_file(sample_filepath, overwrite = TRUE)
#'   }
#' }
#'
download_poc_rdata_file <- function(sample_filepath, overwrite = FALSE) {
  googledrive::drive_download(
    googledrive::as_id("1Z93w-C3XRQ8756W3835JPfxggGEstjKR"),
    path = sample_filepath,
    overwrite = overwrite
  )
}


#' Load the POC `.RData` file into a new environment.
#'
#' With the (latest?) `.RData` file stored locally,
#' create a temporary environment in R and load all the data objects
#' into it.
#' Optionally checks whether some objects relevant for
#' aquatic sample repositioning are present in the file.
#'
#' @param sample_filepath the local `file.path` location of the sample `.RData`
#' @param skip_check (boolean) to skip the specific content checks.
#'
#' @return an R environment containing the `.Rdata` objects.
#'
#' @examples
#' \dontrun{
#'   sample_filepath <- file.path("data/latest_POC.RData")
#'
#'   env_extradata <- load_rdata_environment(sample_filepath)
#'   ls(env_extradata)
#'   get("stratum_units_non_cell_n2khab", envir = env_extradata)
#' }
#'
load_rdata_environment <- function(
    sample_filepath,
    skip_check = FALSE
  ) {

  env_extradata <- new.env()
  load(sample_filepath, envir = env_extradata)
  # ls(envir = env_extradata)

  if (skip_check) return(env_extradata)

  # check that some crucial objects exist in the env
  for (var in c(
    "units_non_cell_n2khab_grts",
    "stratum_units_non_cell_n2khab",
    "scheme_moco_ps_stratum_sppost_spsamples_spares_sf"
    )) {
    tryCatch(
    {stopifnot(exists(var, envir = env_extradata))},
    error = function(wrnmsg) {
      message(paste0(
        "The variable ", var,
        " does not exist in environment `env_extradata`.",
        collapse = "")
      )
    }
    )
  }

  return(env_extradata)

}
