
#' data source version persistence
#'
#' Manually check data source versions (something to be automated by n2khab
#' package in the future, based on preset versions)
#'
confirm_n2khab_data_consistency <- function() {

  # required for the pipe operator
  stopifnot("magrittr" = require("magrittr"))
  stopifnot("n2khab" = require("n2khab"))

  # the checksums of working data versions (as of 20250501)
  # - watersurfaces_hab: version watersurfaces_hab_v6
  # - habitatstreams: version habitatstreams_2023
  # - habitatsprings: version habitatsprings_2020v2
  # - flanders: version "flanders_2018-05-16"
  reference_checksum <- c(
    flanders.dbf = "d21a599325723682",
    flanders.prj = "2f10404ffd869596",
    flanders.shp = "72fff53084b356be",
    flanders.shx = "1880e141bbcdc6ca",
    habitatsprings.geojson = "7268c26f52fcefe4",
    habitatstreams.dbf = "dee7a620e3bcae0a",
    habitatstreams.lyr = "a120f92d80c92a3a",
    habitatstreams.prj = "7e64ff1751a50937",
    habitatstreams.shp = "5a7d7cddcc52c5df",
    habitatstreams.shx = "b2087e6affe744f4",
    habitatstreams.sld = "2f192b84b4df99e9",
    watersurfaces_hab.gpkg = "e2920c4932008387"
  )

  # for comparison: checksums of current files on disk
  status_checksum <- file.path(
      n2khab::locate_n2khab_data(),
      c(
        "20_processed/watersurfaces_hab",
        "10_raw/habitatsprings",
        "10_raw/habitatstreams",
        "10_raw/flanders"
      )
    ) %>%
    list.files(full.names = TRUE) %>%
    n2khab::xxh64sum()

  # per filename, check whether checksums match
  check_identical_checksum <- function (filename) {

    # the check
    file_check <- identical(
        reference_checksum[filename],
        status_checksum[filename]
      )

    # more verbose error upon mismatch
    if (!file_check) {
      message(paste0(
        "ERROR: file `",
        filename,
        "` changed on disk.",
        collapse = "") )
      }

    # stop or return TRUE
    return(is.null(
      stopifnot(file_check)
    ))

  }

  # check all files
  check <- all(sapply(names(reference_checksum), FUN = check_identical_checksum))

  # confirm correctness of all n2khab data files
  if (check) message("All n2khab data files match the recorded state.")

} # /confirm_n2khab_data_consistency
