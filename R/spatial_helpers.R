
### CRS
# assert crs 31370
assert_31370 <- function(sf_obj){
  stopifnot(
    "crs 31370" = format(sf::st_crs(sf_obj)) == "BD72 / Belgian Lambert 72"
  )
  return(sf_obj)
}


### bounding box and spatial extent

# get extent in x direction
get_x_extent <- function(box) abs(box[["xmax"]] - box[["xmin"]])

# get extent in y direction
get_y_extent <- function(box) abs(box[["ymax"]] - box[["ymin"]])

# get some extent proxy in both directions ()
get_extent <- function(box) sqrt(get_x_extent(box)^2 + get_y_extent(box)^2) / 2

# convert a bounding box to an sf::polygon
bbox_to_polygon <- function(box) {

  polybox <- as.data.frame(rbind(
      c(box[["xmin"]], box[["ymin"]]),
      c(box[["xmax"]], box[["ymin"]]),
      c(box[["xmax"]], box[["ymax"]]),
      c(box[["xmin"]], box[["ymax"]]),
      c(box[["xmin"]], box[["ymin"]])
    )) %>%
    setNames(c("x", "y")) %>%
    sf::st_as_sf(coords = c("x", "y"), crs = 31370)

  polybox <- sf::st_combine(polybox) %>%
    sf::st_cast("POLYGON", warn = FALSE)

  return(polybox)
}

### sf operations
# get a point and a vector combined to an sf linestream
create_sf_vector <- function(pt, vec, unit_id) {
  line <- as.data.frame(rbind(pt, pt + vec)) %>%
    setNames(c("x", "y")) %>%
    sf::st_as_sf(coords = c("x", "y"), crs = 31370)

  line <- sf::st_sf(sf::st_combine(line) %>% st_cast("LINESTRING"))

  return(sf::st_sf(data.frame(unit_id = unit_id, geom = line)))
}


# close holes in a polygon
# by succession of "expand" and "shrink"
close_polygon <- function(pol, radius = 1){
  return(
    pol %>%
      sf::st_buffer(radius) %>%
      sf::st_buffer(-radius)
  )
}


### procedural generalization

# wedge carving
#' Create a wedge (slice from a circle) based on a direction and range
#'
#' @details A wedge is a slice of a circle, defined by
#' - a direction vector
#' - and a wedge width (angular range or slice, in radians)
#' - and a wedge range, i.e. the distance range from center to consider
#'
#' @param direction_vector (two-element vector) direction, seen from the center
#' @param wedge_width_rad (two-element vector) angular range of the wedge,
#'        range [0, 2*pi]; set to 2*pi if is.na
#' @param wedge_range_max (decimal) radius of the wedge
#'
#' @return wedge point data frame; can be converted to `sf::st_as_sf(...)`
#'
#' @examples
#' \dontrun{
#'   plot(carve_wedge(c(1., 1.), pi/4, 16), asp = 1, type = "o")
#' }
#'
carve_wedge <- function(direction_vector, wedge_width_rad, wedge_range_max) {

  source(here::here("..", "R", "geometry_helpers.R"))

  pt0 <- t(as.matrix(c(0, 0)))
  radius <- t(as.matrix(direction_vector))
  arc_vec <- max(wedge_range_max) * radius / vector_norm(radius)

  # ensure correct wedge width
  wedge_width_rad <- wedge_width_rad %% (2 * pi)
  if (
    (!is.numeric(wedge_width_rad)) ||
    (is.na(wedge_width_rad)) ||
    (wedge_width_rad == 0)
    ) {
    wedge_width_rad <- 2 * pi
  }


  wedge_steps <- seq(
    -wedge_width_rad / 2,
    +wedge_width_rad / 2,
    length.out = as.integer(round(rad2deg(wedge_width_rad))) + 1
  )

  wedge_points <- data.frame(t(cbind(sapply(
    wedge_steps, FUN = function(ang) rotate_vec_2d(arc_vec, ang)
  ))))

  wedge_points <- dplyr::bind_rows(
    data.frame(pt0),
    wedge_points,
    data.frame(pt0)
  )

  wedge <- wedge_points %>%
    setNames(c("x", "y"))

  return(wedge)
}
