
library("spbal")
library("dplyr")
library("sf")


make_a_point <- function (x, y) t(as.matrix(c(x, y), byrows = TRUE, ncol = 2, nrow = 1))

make_polygon <- function(point_matrix, coord_cols = NULL, crs = 31370) {

  if (is.null(coord_cols)) {
    coord_cols <- c("x", "y")
  }

  spatial_df <- as.data.frame(point_matrix) %>%
    setNames(coord_cols) %>%
    sf::st_as_sf(coords = coord_cols, crs = crs)

  return(sf::st_combine(spatial_df) %>% sf::st_cast("POLYGON", warn = FALSE))

}



generate_random_sampling <- function(
    zone_radius = 10, # m
    angle_range = 2*pi,
    n_samples = 128,
    location_seed = 42 # location_specific
  ) {

  # prepare the unit zone
  unit_zone_rad <- make_polygon(
    rbind(
      make_a_point(0, 0),
      make_a_point(0, 1),
      make_a_point(1, 1),
      make_a_point(1, 0),
      make_a_point(0, 0)
    )
  )

  # plot(unit_zone_rad)

  # set location-specific seed (grts_address -> reproducibility)
  set.seed(location_seed)

  # spatial sampling using Balanced Acceptance
  # https://cran.r-project.org/web/packages/spbal/vignettes/spbal.html
  result <- spbal::BAS(sf::st_as_sf(unit_zone_rad, crs = NA), n = n_samples)
  samples <- result$sample

  # coordinate tricks
  coords <- sf::st_coordinates(samples)

  # scale to angular- and radial range
  phi <- coords[,1] * angle_range
  r <- coords[,2] * zone_radius
  # plot(r, phi)

  # convert to x/y
  x <- r * cos(phi)
  y <- r * sin(phi)

  # plot(x, y)
  # text(x, y, 1:n_samples)

  # voila!
  return(cbind(x, y))
}



zone_radius <- 10 # m
angle_range <- 2*pi
n_samples <- 128
location_seed <- 509 # one_location$location_id
random_points <- generate_random_sampling(
  zone_radius,
  angle_range ,
  n_samples,
  location_seed
)

plot(random_points)
text(
  random_points[, 1],
  random_points[, 2],
  1:n_samples,
  pos = 3
)
