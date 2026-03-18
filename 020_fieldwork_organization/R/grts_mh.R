# functions using the GRTS master - habitats
# cf. https://github.com/inbo/n2khab/blob/main/R/GRTSmh.R


### grts cells and geometry
grts_mh <- read_GRTSmh()
# create a spatial index of the GRTS addresses
grts_mh_index <- tibble(
  id = seq_len(ncell(grts_mh)),
  grts_address = values(grts_mh)[, 1]
) %>%
  filter(!is.na(grts_address))

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
