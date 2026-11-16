

#' Determine the target area for a spring (7220) location.
#'
#' Provides a polygon area in the vicinity of the
#' spring (type 7220) habitat location of interest,
#' in the opposite direction of putative groundwater flow (elevation model).
#' The function is designed for springs, but should be rather
#' generic: feel free to exapt.
#'
#' @param location an `sf` point-like object capturing the spring location.
#' @param wedge_width_rad indicates the slice of a circle
#'        to which the target buffer is restricted.
#'        range [0, 2*pi]; set to 2*pi if `is.na`
#' @param wedge_range_m two-element vector c(from, to) which
#'        determines the distance range around the point in
#'        which the target location should be found.
#' @inheritParams calculate_flow_direction
#'
#' @return target area, as an sf object with POLYGON geometry
#'
#' @examples
#' \dontrun{
#'   location <- n2khab::read_habitatsprings(units_7220 = TRUE) %>%
#'     filter(unit_id == 6)
#'   target_area <- determine_spring_target_area(
#'     location,
#'     wedge_width_rad = pi/3,
#'     wedge_range_m = c(4, 32),
#'     flow_range = 64,
#'     flow_cellsize = 8
#'   )
#' }
#'
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
