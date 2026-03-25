# functions using the GRTS master - habitats
# cf. https://github.com/inbo/n2khab/blob/main/R/GRTSmh.R


stopifnot("dplyr" = require("dplyr"))
stopifnot("n2khab" = require("n2khab"))

### grts cells and geometry
if (!exists("grts_mh")) {
  grts_mh <<- n2khab::read_GRTSmh()
}
# create a spatial index of the GRTS addresses
if (!exists("grts_mh_index")) {
  grts_mh_index <<- dplyr::tibble(
      id = seq_len(terra::ncell(grts_mh)),
      grts_address = values(grts_mh)[, 1]
    ) %>%
    dplyr::filter(!is.na(grts_address))
}

#' wrapper to perform `add_point_coords_grts` with the `_mh` objects
append_point_coords_grts_mh <- function(...) {
  add_point_coords_grts(
    ...,
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  ) %>%
  return()
}

#' wrapper to perform `filter_grtsraster_by_address` with the `_mh` objects
filter_grtsraster_by_address_mh <- function(...) {
  filter_grtsraster_by_address(
    ...,
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  ) %>%
  return()
}
