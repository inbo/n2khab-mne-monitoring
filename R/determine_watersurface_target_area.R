

#' Determine target area for well placement
#' around aquatic habitat types.
#'
#' Provides a polygon area in a buffer band around the
#' water surface of interest, in the upstream direction
#' of putative groundwater flow (elevation model).
#'
#' @param water_polygon an `sf` polygon-like object capturing
#'        the water surface.
#' @param original_location sf point indicating placement target;
#'        centroid of the water_polygon will be used per default.
#' @param buffer_range two-element vector c(from, to) which
#'        determines the distance range around the polygon in
#'        which the target location should be found.
#' @param buffer_arc_radians indicates the slice of a circle
#'        to which the target buffer is restricted.
#'        range [0, 2*pi]; set to 2*pi of is.na
#' @inheritParams calculate_polygon_flow_direction
#'
#' @return target area, as an sf object with POLYGON geometry
#'
#' @examples
#' \dontrun{
#'   wspol <- read_watersurfaces_hab(interpreted = TRUE)$watersurfaces_polygons
#'   test_polygon <- wspol %>%
#'     filter(polygon_id == "LIMGNK0062") %>%
#'     sf::st_cast("POLYGON", warn = FALSE)
#'   test_target <- determine_watersurface_target_area(
#'     test_polygon,
#'     buffer_range = c(1, 10),
#'     buffer_arc_radians = 1, # because 1 ≡ pi/3
#'     flow_range = 64,
#'     flow_cellsize = 8
#'   )
#' }
#'
determine_watersurface_target_area <- function(
    water_polygon,
    original_location = NA,
    buffer_range = NA,
    buffer_arc_radians = 1, # because 1 ≡ pi/3
    view_map = FALSE,
    ...
  ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("sf" = require("sf"))

  source(here::here("..", "R", "geometry_helpers.R"))
  source(here::here("..", "R", "spatial_helpers.R"))
  source(here::here("..", "R", "calculate_polygon_flow_direction.R"))

  # ensure meaningful buffer range
  if (any(is.na(buffer_range))) {
    buffer_range <- c(5, 20)
  } else {
    buffer_range <- c(min(buffer_range), max(buffer_range))
  }

  # ensure correct wedge width
  buffer_arc_radians <- buffer_arc_radians %% (2*pi)
  if ((!is.numeric(buffer_arc_radians)) ||
      (is.na(buffer_arc_radians)) ||
      (buffer_arc_radians == 0)
      ){
    buffer_arc_radians = 2*pi
  }

  # a buffer belt around the aquatic type
  water_buffer <- sf::st_difference(
    sf::st_buffer(water_polygon, buffer_range[2]),
    sf::st_buffer(water_polygon, buffer_range[1])
    ) %>% suppressWarnings
  # mapview(water_buffer)

  # ensure the wedge covers the belt
  wedge_range <- get_extent(sf::st_bbox(water_buffer)) + buffer_range[2]


  # determine the flow direction and project the opposite way
  if (any(is.na(original_location))) {
    original_location <- sf::st_centroid(water_polygon) %>%
      suppressWarnings()
  }

  # correct coordinate columns
  original_location <- sf::st_as_sf(
    cbind(
      sf::st_drop_geometry(original_location),
      dplyr::as_tibble(sf::st_coordinates(original_location)) %>%
        dplyr::rename(c("x" = "X", "y" = "Y"))
    ),
    coords = c("x", "y"),
    crs = 31370
  )

  # get flow direction
  # upstream <- t(as.matrix(-calculate_flow_direction(original_location)))
  upstream <- t(as.matrix(
    -calculate_polygon_flow_direction(water_polygon, ...)
  ))

  # standardized vector length
  upstream_vec <- wedge_range * upstream / vector_norm(upstream)

  arc_points <- rbind(t(as.matrix(c(0, 0))))
  for (rot_rad in seq(
      -buffer_arc_radians/2,
      buffer_arc_radians/2,
      length.out = as.integer(round(rad2deg(buffer_arc_radians)))
    )) {
    pt <- rotate_vec_2d(upstream_vec, rot_rad)
    arc_points <- rbind(arc_points, pt)
  }

  # offset the arc by the center location
  center_coords <- sf::st_coordinates(original_location) %>%
    dplyr::as_tibble() %>% dplyr::rename_with(tolower)

  arc <- as.data.frame(arc_points) %>%
    setNames(c("x", "y")) %>%
    dplyr::mutate(x = x + center_coords[["x"]], y = y + center_coords[["y"]]) %>%
    sf::st_as_sf(coords = c("x", "y"), crs = 31370)

  arc <- sf::st_combine(arc) %>% sf::st_cast("POLYGON", warn = FALSE)

  # the target are is the intersect of the arc and the buffer
  target_area <- arc %>% sf::st_intersection(water_buffer)

  # optional visualization
  if (view_map) {
    stopifnot("mapview" = require("mapview"))
    m1 <- mapview::mapview(water_polygon, map.types = "OpenStreetMap", col.regions = "lightblue")
    m2 <- mapview::mapview(water_buffer, map.types = "OpenStreetMap", col.regions = "darkblue")
    m3 <- mapview::mapview(arc, map.types = "OpenStreetMap", col.regions = "orange")
    # m4 <- mapview(target_area, map.types = "OpenStreetMap", col.regions = "red")
    m1+m2+m3
  }


  return(target_area)
} # /determine_watersurface_target_area
