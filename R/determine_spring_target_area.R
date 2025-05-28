

# determine the target area for a spring (7220) location
determine_spring_target_area <- function(
    location,
    wedge_width_rad,
    wedge_range_m,
    ...
  ) {


  stopifnot("dplyr" = require("dplyr"))
  stopifnot("sf" = require("sf"))

  source(here::here("..", "R", "geometry_helpers.R"))
  source(here::here("..", "R", "spatial_helpers.R"))
  source(here::here("..", "R", "calculate_flow_direction.R"))

  location_coords <- sf::st_coordinates(location) %>%
    dplyr::as_tibble() %>%
    dplyr::rename_with(tolower)

  flow_direction <- calculate_flow_direction(location, ...)

  wedge_points <- carve_wedge(
    -flow_direction,
    wedge_width_rad,
    1.1 * wedge_range_m[2]
  )


  target_area <- wedge_points %>%
    dplyr::mutate(
      x = x + location_coords[["x"]],
      y = y + location_coords[["y"]]
    ) %>%
    sf::st_as_sf(coords = c("x", "y"), crs = 31370)
  target_area <- sf::st_combine(target_area) %>%
    sf::st_cast("POLYGON", warn = FALSE)


  range_buffer <- sf::st_difference(
    sf::st_buffer(location, wedge_range_m[2]),
    sf::st_buffer(location, wedge_range_m[1])
    ) %>%
    suppressWarnings

  target_area <- sf::st_intersection(target_area, range_buffer)

  return(target_area)

}
