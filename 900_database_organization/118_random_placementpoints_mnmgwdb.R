
source("MNMLibraryCollection.R")
load_database_interaction_libraries()
library("cimir") %>% suppressPackageStartupMessages()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

database_label <- "mnmgwdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}


### special treatment: cell-coupled types
# 1320    | schorren met slijkgras
# 2150    | vastgelegde ontkalkte duinen
# rbbsg   | brem- en gaspeldoornstruweel
# 6210_sk | kalkrijke zomen en struwelen
# 6430_bz | nitrofiele boszoom
# 7150    | pioniervegetaties met snavelbiezen
# rbbsp   | doornstruweel

non_center_coupled_types <- c(
  "1320", "2150", "rbbsg", "6210_sk",
  "6430_bz", "7150", "rbbsp"
)
# if those are present in combination with a cell-center-coupled type,
# the union of cellmap polygons is used




### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmgwdb$shellstring)

# connect loceval, for cellmaps
loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)
# message(loceval_connection$shellstring)


### info from REP
if (TRUE) {

  tic <- function(toc) round(Sys.time() - toc, 1)
  toc <- Sys.time()

  snippet_base_path <<- rprojroot::find_root(rprojroot::is_git_root)
  # TEMPORARY adjustment pointing to adjacent branch (wip)
  snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))

  fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
  reload_rep_code_snippets(fresh_snippet_path)
  message(glue::glue("Good morning!
    Loading the REP data and snippets took {tic(toc)} seconds today."
  ))

  verify_rep_objects()

  if (nrow(different_checksums) > 0) {
    knitr::kable(different_checksums)
  }


}

### MHQ input
# check which cells are subject to MHQ assessment
## not necessary: now stored in SampleLocations
# assessment_lookup <- bind_rows(
#   fag_stratum_grts_calendar %>%
#     distinct(grts_address_final, assessed_in_field) %>%
#     setNames(c("grts_address", "assessed")),
#   stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
#     distinct(grts_address_final, last_type_assessment_in_field) %>%
#     setNames(c("grts_address", "assessed"))
# )


### Geometry helpers
make_a_point <- function (x, y) t(as.matrix(c(x, y), byrows = TRUE, ncol = 2, nrow = 1))

make_polygon <- function(point_matrix, coord_cols = NULL, crs = 31370) {

  if (is.null(coord_cols)) {
    coord_cols <- c("x", "y")
  }

  # print(point_matrix)

  spatial_df <- as.data.frame(point_matrix) %>%
    setNames(coord_cols) %>%
    sf::st_as_sf(coords = coord_cols, crs = crs)

  return(sf::st_combine(spatial_df) %>% sf::st_cast("POLYGON", warn = FALSE))

}



generate_centerweighted_random_sampling <- function(
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

locations_sf <- mnmgwdb$query_table("Locations") %>%
  sf::st_as_sf()

sample_locations <- mnmgwdb$query_table("SampleLocations")


## load cell maps and join them with nearest locations

cellmaps_sf <- loceval_connection$query_table("CellMaps") %>%
  sf::st_as_sf()

nearest <- cellmaps_sf %>%
  sf::st_nearest_feature(locations_sf)

cellmaps_sf$location_id <- locations_sf$location_id[nearest]
cellmaps_sf$unused <- TRUE


locations_all <- locations_sf %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest_previously_for_comparison = stringr::str_detect(strata, "^9|^2180|^rbbppm")
    # is_forest = stringr::str_detect(strata, "^9|^2180|^rbbppm")
  ) %>%
  rename(stratum = strata)

# TODO: work with a subset for testing
locations <- locations_all %>%
  filter(!sf::st_is_empty(wkb_geometry)) # %>%
# filter(grts_address %in% c(131806)) # 83694
#  filter(grts_address %in% c(48897, 1818369))
#  filter(grts_address %in% c(23238, 23091910, 6314694))


## other monitoring
# other institutes are monitoring, and we avoid placing installations in their
# sampling areas.
# cf. `n2khab-mne-designs/100_design_common/010_revisitplan/R/update_vbi_overlaps.R`

drive_download(
  as_id("1pYvpC58-GnUvIWW96hWElUq1D5O9YCg9"),
  path = file.path(tempdir(), "coordinates.tsv")
)
drive_download(
  as_id("1qbpW73audXrDhFtGkYHUhdtrLUIAfbk_"),
  path = file.path(tempdir(), "coordinates.yml")
)
coordinates_monitoring <- git2rdata::read_vc("coordinates", root = tempdir()) %>% as_tibble()

monitoring_areas <-
  coordinates_monitoring %>%
  filter(type_coord == "ingemeten coo") %>%
  filter(vbi_cycle == max(vbi_cycle), .by = plot_id) %>%
  select(plot_id, x, y) %>%
  mutate(plot_id = as.integer(plot_id)) %>%
  st_as_sf(
    coords = c("x", "y"),
    remove = FALSE,
    crs = 31370,
    agr = "identity"
  ) %>%
  st_buffer(18)


grts_addresses_of_monitoring_cells <- locations %>%
  sf::st_buffer(dist = 16, endCapStyle = "SQUARE") %>%
  st_intersection(monitoring_areas) %>%
  st_drop_geometry() %>%
  pull(grts_address)

## random sampling procedure

generate_random_placement_points <- function(
    one_location,
    n_points = 20,
    target_radius = 10,
    n_samples = 256,
    # is_forest = FALSE,
    # is_mhq_samplelocation = FALSE,
    location_seed = 42
  ) {


  cell_center <- sf::st_coordinates(one_location)
  is_forest <- one_location$is_forest
  is_mhq_samplelocation <- one_location$has_mhq_assessment | one_location$in_mhq_samples

  # target_area <- sf::st_buffer(one_location, target_radius)
  target_area <- make_polygon(
      rbind(
        cell_center + make_a_point(16, 16),
        cell_center + make_a_point(16, -16),
        cell_center + make_a_point(-16, -16),
        cell_center + make_a_point(-16, 16),
        cell_center + make_a_point(16, 16)
      )
    )
  # mapview::mapview(target_area)

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
    mhq_safety <- sf::st_buffer(mhq_zone, 1)
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
    mhq_safety <- sf::st_buffer(mhq_zone, 2)
  }


  # the available area with the correct habitat type
  # as indicated by cell mapping
  # see notes on `non_center_coupled_types` above
  # often multiple subparts are chosen
  if (one_location$stratum %in% non_center_coupled_types) {
    # is there a center-coupled reference on this co-location?
    # then skip this one
    center_coupled_reference <- cellmaps_sf %>%
      dplyr::filter(
        location_id == one_location$location_id
      ) %>%
      dplyr::filter_out(
        type %in% c(non_center_coupled_types)
      )
    if (nrow(center_coupled_reference) > 0) return(invisible(NULL))
  }

  # cellmap polygons of this type and co-located non-center-coupled types
  cellmap_polygons <- cellmaps_sf %>%
    dplyr::filter(
      unused,
      location_id == one_location$location_id,
      # type == one_location$stratum
      type %in% c(one_location$stratum, non_center_coupled_types)
    ) %>%
    sf::st_union()


  random_points <- generate_centerweighted_random_sampling(
      target_radius = target_radius,
      n_samples = n_samples,
      location_seed = location_seed
    ) +
    do.call(
      rbind,
      replicate(n_samples, c(cell_center, 0, 0), simplify = FALSE)
    )
  random_points_sf <- sf::st_as_sf(
    random_points,
    coords = c("X", "Y"),
    crs = 31370
  )

  # (1) is point inside the target area = 16x16 cell?
  inside_cell <- random_points_sf[
    sf::st_intersects(random_points_sf, target_area, sparse = FALSE),
    ]

  # (2) filter out candidate points which
  #     fell into the MHQ sampling area
  if (is_forest && isFALSE(is_mhq_samplelocation)) {
    # cell not assessed / not part of MHQ
    outside_mhq <- inside_cell
  } else {
    # cell assessed or assessment planned
    outside_mhq <- inside_cell[
      sf::st_disjoint(inside_cell, mhq_safety, sparse = FALSE)
      , ]
  }

  # (3) likewise exclude other monitoring areas
  if (isFALSE(
    one_location$grts_address %in% grts_addresses_of_monitoring_cells
  )) {
    outside_monitoring <- outside_mhq
  } else {
    outside_monitoring <- outside_mhq[
      sf::st_disjoint(
        outside_mhq,
        target_area %>% sf::st_intersection(monitoring_areas),
        sparse = FALSE
      )
      , ]
  }

  # (4) only keep points in areas indicated by cell mapping
  points_in_habitat <- outside_monitoring[
    sf::st_intersects(outside_monitoring, cellmap_polygons, sparse = FALSE)
    , ]
  if (nrow(points_in_habitat) > n_points) {
    # the sf[1:n, ] syntax will generate `empty` geometries if n<m
    points_in_habitat <- points_in_habitat[seq_len(n_points), ]
  }

  if (FALSE) {
    require("mapview")
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

} # / generate_random_placement_points



### (1) circle of 10 m radius

pb <- txtProgressBar(
  min = 0, max = nrow(locations),
  initial = 0, style = 1
)

# location_row <- 1 # 234
# location_row <- which(locations$grts_address == 83694)
randompoints_locationwise <- function(location_row) {

  setTxtProgressBar(pb, location_row)

  one_location <- locations[location_row, ]
  # TODO convert stratum to type
  # print(one_location$grts_address)
  location_seed <- as.integer(one_location$grts_address)

  is_forest <- one_location$is_forest
  is_mhq_samplelocation <- one_location$has_mhq_assessment | one_location$in_mhq_samples

  target_radius <- sqrt(2 * 16^2) # m
    # NOTE: r>16 because we include points in the whole cell
  n_samples <- 128
  n_points <- 20
  # is_forest <- one_location$is_forest
  # is_mhq_samplelocation <- assessment_lookup %>%
  #   filter(grts_address == one_location$grts_address) %>%
  #   pull(assessed) %>%
  #   any

  # if (is_forest) {
  #     target_radius <- 16 # NOT: 18 m # BUT: 10 is too little
  # }

  # cells without cell mapping will never score
  skip <- 0 == cellmaps_sf %>%
    dplyr::filter(
      location_id == one_location$location_id,
      type == one_location$stratum
    ) %>%
    sf::st_union() %>%
    length()

  if (skip) {
    return(invisible(NULL))
  }


  n_points_currently <- 0
  limit_count <- 1
  while ((n_points_currently < n_points) && (limit_count < 8)) {

    rnd20_points <- generate_random_placement_points(
      one_location,
      n_points = n_points,
      target_radius = target_radius,
      n_samples = n_samples,
      location_seed = location_seed
    )

    if (is.null(rnd20_points)) return(invisible(NULL))

    n_points_currently <- nrow(rnd20_points)
    n_samples <- n_samples * 2 # just get more samples
    limit_count <- limit_count + 1 # but don't go too big
  }


  center_representation_point <- as.data.frame(sf::st_coordinates(one_location)) %>%
    dplyr::mutate(r = 0, phi = 0) %>%
    sf::st_as_sf(coords = c("X", "Y"), crs = sf::st_crs(one_location))

  # some more centers may not be used as placement point
  center_intersects_monitoring <- any(center_representation_point %>%
    sf::st_intersects(vbi_overlaps_sf, sparse = FALSE))

  if (is_forest &&
      isFALSE(is_mhq_samplelocation) &&
      isFALSE(center_intersects_monitoring)
    ) {
    rnd20_points <- dplyr::bind_rows(
      center_representation_point,
      rnd20_points %>% dplyr::filter_out(sf::st_is_empty(.))
    )
  }

  rnd20_points <- rnd20_points %>%
    dplyr::mutate(
      samplelocation_id = one_location$samplelocation_id,
      location_id = one_location$location_id,
      grts_address = one_location$grts_address,
      random_point_rank = seq_len(nrow(rnd20_points))
    )

  return(rnd20_points)

} # /randompoints_locationwise


all_points <- lapply(
  seq_len(nrow(locations)),
  FUN = randompoints_locationwise
)
close(pb) # close the progress bar

all_points <- bind_rows(all_points)
# any(all_points %>% sf::st_is_empty())



if (FALSE) {
  example_location <- all_points %>%
    filter(grts_address == 23238)

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
}

# https://en.wikipedia.org/wiki/Points_of_the_compass#/media/File:Compass-rose-32-pt.svg

## TODO northing - correct to magnetic north
all_points <- all_points %>%
  mutate(
    randompoint_id = seq_len(nrow(all_points)),
    angle = -(phi+90) %% 360,
    # angle_look = (-angle) + 360, # wrong, updated 20250812
    angle_look = (angle + 180) %% 360,
    compass = cimir::cimis_degrees_to_compass(angle),
    distance_m = r
  )

all_points <- all_points %>% sf::st_cast("POINT")

lamberts <- as.data.frame(
    sf::st_coordinates(all_points)
  ) %>%
  setNames(c("lambert_lon", "lambert_lat"))

all_points <- cbind(all_points, lamberts) %>%
  mutate_at(
    vars(
      lambert_lon,
      lambert_lat,
      angle,
      angle_look,
      distance_m
    ), function (x) round(x, 2)
  )

sf::st_geometry(all_points) <- "wkb_geometry"

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.RandomPoints"))

if (TRUE) {
  mnmgwdb$execute_sql(
    glue::glue('DELETE FROM "outbound"."RandomPoints";'),
    verbose = TRUE
  )

  mnmgwdb$insert_data(
    table_label = "RandomPoints",
    upload_data = all_points %>% select(-r, -phi)
  )

}


# source('118_random_placementpoints_mnmgwdb.R')

message("")
message("________________________________________________________________")
message(" >>>>>  Finished updating random placement points. ")
message("________________________________________________________________")


if (FALSE) {

# """
# \COPY (
#   SELECT samplelocation_id,
#     location_id,
#     grts_address,
#     random_point_rank,
#     compass,
#     angle,
#     angle_look,
#     distance_m,
#     lambert_lon,
#     lambert_lat
#   FROM "outbound"."RandomPoints"
#   WHERE angle IS NOT NULL
#   ORDER BY grts_address ASC, random_point_rank ASC
# ) TO '/data/mnm_db_backups/randompoints.csv' With CSV DELIMITER ',' HEADER
# ;
# """

}
