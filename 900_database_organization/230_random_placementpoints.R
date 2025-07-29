
library("dplyr")
library("tidyr")
library("stringr")
library("purrr")
library("lubridate")
library("sf")
library("terra")
library("n2khab")
library("googledrive")
library("readr")
library("glue")
library("rprojroot")
library("keyring")
library("spbal")

library("configr")
library("DBI")
library("RPostgres")

library("mapview")
# mapviewOptions(platform = "mapdeck")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")

# testing
working_dbname <- "mnmgwdb"
connection_profile <- "mnmgwdb"


config <- configr::read.config(file = config_filepath)[[connection_profile]]
source("MNMDatabaseToolbox.R")

# database connection
db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = connection_profile,
  database = working_dbname
)

# to query latest data from loceval
# (in this case, CellMaps)
loceval_connection <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  password = NA
)


if (FALSE){
### info from POC
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R")

poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)

invisible(capture.output(source("050_snippet_selection.R")))
source("051_snippet_transformation_code.R")
}

assessment_lookup <- bind_rows(
  fag_stratum_grts_calendar %>%
    distinct(grts_address_final, assessed_in_field) %>%
    setNames(c("grts_address", "assessed")),
  stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
    distinct(grts_address_final, last_type_assessment_in_field) %>%
    setNames(c("grts_address", "assessed"))
)


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
    target_radius = 10, # m
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
  r <- coords[,2] * target_radius
  # plot(r, phi)

  # convert to x/y
  x <- r * cos(phi)
  y <- r * sin(phi)

  # plot(x, y)
  # text(x, y, 1:n_samples)

  # voila!
  return(as.data.frame(cbind(x, y, r, (phi - pi)*180/pi)) %>% setNames(c("X", "Y", "r", "phi")))
}



## load SampleLocations

locations_sf <- sf::st_read(
  db_connection,
  DBI::Id("metadata", "Locations")
  ) %>%
  select(-ogc_fid) %>%
  collect


sample_locations <- dplyr::tbl(
  db_connection,
  DBI::Id("outbound", "SampleLocations")
  ) %>%
  collect


## load cell maps and join them with nearest locations

cellmaps_sf <- sf::st_read(
  loceval_connection,
  DBI::Id("inbound", "CellMaps")
  ) %>%
  select(-ogc_fid) %>%
  collect

nearest <- cellmaps_sf %>%
  sf::st_nearest_feature(locations_sf)

cellmaps_sf$location_id <- locations_sf$location_id[nearest]


locations_all <- locations_sf %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest = stringr::str_detect(strata, "^9|^2180|^rbbppm")
  )

# TODO: work with a subset for testing
locations <- locations_all # %>%
  # filter(grts_address %in% c(23238, 23091910, 6314694))

## random sampling procedure

generate_random_points <- function(
    one_location,
    n_points = 20,
    target_radius = 10,
    n_samples = 256,
    is_forest = FALSE,
    is_assessed = FALSE,
    location_seed = 42
  ) {


  target_area <- sf::st_buffer(one_location, target_radius)
  # mapview(target_area)

  cell_center <- sf::st_coordinates(one_location)


  if (is_forest) {

    mhq_zone <- make_polygon(
      rbind(
        cell_center + make_a_point(8, 8),
        cell_center + make_a_point(8, -8),
        cell_center + make_a_point(-8, -8),
        cell_center + make_a_point(-8, 8),
        cell_center + make_a_point(8, 8)
      )
    )
    mhq_safety <- sf::st_buffer(mhq_zone, 2)
  } else {
    mhq_zone <- make_polygon(
      rbind(
        cell_center,
        cell_center + make_a_point(0, 3),
        cell_center + make_a_point(-3, 3),
        cell_center + make_a_point(-3, 0),
        cell_center
      )
    )
    mhq_safety <- sf::st_buffer(mhq_zone, 3)
  }


  cellmap_polygons <- cellmaps_sf %>%
    filter(location_id == one_location$location_id)


  random_points <- generate_random_sampling(
      target_radius = target_radius,
      n_samples = n_samples,
      location_seed = location_seed
    ) + do.call(rbind, replicate(n_samples, c(cell_center, 0, 0), simplify=FALSE))
  random_points_sf <- sf::st_as_sf(random_points, coords = c("X", "Y"), crs = 31370)

  inside_target <- random_points_sf[st_intersects(random_points_sf, target_area, sparse = FALSE),]

  if (is_assessed && is_forest) {
    outside_mhq <- inside_target[st_disjoint(inside_target, mhq_safety, sparse = FALSE),]
  } else {
    outside_mhq <- inside_target
  }
  points_in_habitat <- outside_mhq[st_intersects(outside_mhq, cellmap_polygons, sparse = FALSE),]
  points_in_habitat <- points_in_habitat[1:n_points,]

  if (FALSE) {
    mapview(target_area, col.regions = "white") +
      mapview(cellmap_polygons, col.regions = "yellow") +
      mapview(mhq_safety, col.regions = "orange") +
      mapview(mhq_zone, col.regions = "red") +
      mapview(one_location, col.regions = "darkred") +
      mapview(points_in_habitat, col.regions = "green")
  }

  # plot(random_points)
  # text(
  #   random_points[, 1],
  #   random_points[, 2],
  #   1:n_samples,
  #   pos = 3
  # )

  return(points_in_habitat)

} # / generate random points



### (1) circle of 10 m radius

pb <- txtProgressBar(
  min = 0, max = nrow(locations),
  initial = 0, style = 1
)

# location_row <- 234
randompoints_locationwise <- function(location_row) {

  setTxtProgressBar(pb, location_row)

  one_location <- locations[location_row, ]
  location_seed <- as.integer(one_location$grts_address)

  target_radius <- 10 # m
  n_samples <- 128
  n_points <- 20
  is_forest <- one_location$is_forest
  is_assessed <- assessment_lookup %>%
    filter(grts_address == one_location$grts_address) %>%
    pull(assessed) %>%
    any

  if (is_forest) {
      target_radius <- 18
  }

  current_points <- 0
  limit_count <- 1
  while ((current_points < n_points) && (limit_count < 8)) {

    rnd20_points <- generate_random_points(
      one_location,
      n_points = n_points,
      target_radius = target_radius,
      n_samples = n_samples,
      is_forest = is_forest,
      is_assessed = is_assessed,
      location_seed = location_seed
    )

    current_points <- nrow(rnd20_points)
    n_samples <- n_samples * 2 # just get more samples
    limit_count <- limit_count + 1 # but don't go too big
  }


  rnd20_points <- rnd20_points %>%
    mutate(
      samplelocation_id = one_location$samplelocation_id,
      location_id = one_location$location_id,
      grts_address = one_location$grts_address,
      random_point_rank = 1:nrow(rnd20_points)
    )

  return(rnd20_points)

}


all_points <- lapply(
  1:nrow(locations),
  FUN = randompoints_locationwise
)
close(pb) # close the progress bar
all_points <- bind_rows(all_points)


example_location <- all_points %>%
  filter(grts_address == 23238)

library("cimir")
example_location <- example_location %>%
  mutate(phi2 = -phi + 180, # center right, clockwise 0-360
         phi3 = (phi2 - 90) %% 360, # center DOWN, clockwise 0-360
         phi4 = phi3 - 180, # center DOWN, clockwise 0-360
         phi5 = -(phi+90) %% 360,
         compass = cimir::cimis_degrees_to_compass(phi5)
         )

rndpt <- sf::st_coordinates(example_location)
plot(rndpt)
text(
  rndpt[, 1],
  rndpt[, 2],
  #example_location %>% pull(phi5), # 1:nrow(rndpt)
  example_location %>% pull(compass), # 1:nrow(rndpt)
  pos = 3
)

# https://en.wikipedia.org/wiki/Points_of_the_compass#/media/File:Compass-rose-32-pt.svg

## TODO northing - correct to magnetic north
all_points <- all_points %>%
  mutate(
    randompoint_id = 1:nrow(all_points),
    angle = -(phi+90) %% 360,
    angle_look = (-angle) + 360,
    compass = cimir::cimis_degrees_to_compass(angle),
    distance_m = r
  )

all_points <- all_points %>% sf::st_cast("POINT")

sf::st_geometry(all_points) <- "wkb_geometry"

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.RandomPoints"))

if (TRUE) {
  execute_sql(
    db_connection,
    glue::glue('DELETE FROM "outbound"."RandomPoints";'),
    verbose = TRUE
  )

  append_tabledata(
    db_connection,
    DBI::Id(schema = "outbound", table = "RandomPoints"),
    all_points %>% select(-r, -phi),
    reference_columns = "randompoint_id"
  )

}


# source('230_random_placementpoints.R')
