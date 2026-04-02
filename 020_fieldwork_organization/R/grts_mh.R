# functions using the GRTS master - habitats
# cf. https://github.com/inbo/n2khab/blob/main/R/GRTSmh.R


load_grts_mh_to_env <- function(env = NULL) {

  require_pkgs(c("dplyr", "n2khab"))

  ### grts cells and geometry
  if (!exists("grts_mh")) {
    if (is.null(env)) {
      if (identical(environment(), globalenv())) {
        env <- environment()
      } else if (identical(environment(), baseenv())) {
        env <- environment()
      } else {
        env <- parent.env(environment())
      }
    }
    assign(
      "grts_mh",
      n2khab::read_GRTSmh(),
      pos = env
    )

  }

  # create a spatial index of the GRTS addresses
  if (!exists("grts_mh_index")) {
    assign(
      "grts_mh_index",
      dplyr::tibble(
        id = seq_len(terra::ncell(grts_mh)),
        grts_address = values(grts_mh)[, 1]
      ) %>%
      dplyr::filter(!is.na(grts_address)),
      pos = env
    )
  }

} # /load_grts_mh_to_env


#' wrapper to perform `add_point_coords_grts` with the `_mh` objects
append_point_coords_grts_mh <- function(..., env = NULL) {

  require_pkgs("n2khab")

  if (is.null(env)) {
    env <- parent.env(environment())
  }
  load_grts_mh_to_env(env = env)


  if (!exists("add_point_coords_grts")) {
    stop(
      " (in function `add_point_coords_grts_mh`)",
      "\n\tfunction `add_point_coords_grts` is missing.",
      "\n\tPlease load the REP `*.RData` file first."
    )
  }

  add_point_coords_grts(
    ...,
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  ) %>%
  return()
} # /append_point_coords_grts_mh


#' wrapper to perform `filter_grtsraster_by_address` with the `_mh` objects
filter_grtsraster_by_address_mh <- function(..., env = NULL) {

  require_pkgs("n2khab")

  load_grts_mh_to_env(
    env = parent.env(environment())
  )

  if (!exists("filter_grtsraster_by_address")) {
    stop(
      " (in function `filter_grtsraster_by_address_mh`)",
      "\n\tfunction `filter_grtsraster_by_address` is missing.",
      "\n\tPlease load the REP `*.RData` file first."
    )
  }


  filter_grtsraster_by_address(
    ...,
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  ) %>%
  return()

} # /filter_grtsraster_by_address_mh
