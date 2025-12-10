
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

database_label <- "loceval"
db_using_locations <- FALSE

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}


### connect to database
mnmdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmdb$shellstring)

### connect to databases
loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)
# message(loceval_connection$shellstring)


if (TRUE){
### info from POC
load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())

# ... and code snippets.
snippets_path <- rprojroot::find_root(rprojroot::is_git_root)
load_poc_code_snippets(snippets_path)

verify_poc_objects()

}


# assessment_lookup <- bind_rows(
#   fag_stratum_grts_calendar %>%
#     distinct(grts_address_final, assessed_in_field) %>%
#     setNames(c("grts_address", "assessed")),
#   stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
#     distinct(grts_address_final, last_type_assessment_in_field) %>%
#     setNames(c("grts_address", "assessed"))
# )



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



## load SampleLocations

locations_sf <- mnmdb$query_table("Locations") %>%
  sf::st_as_sf()

if (db_using_locations) {
  sample_locations <- mnmdb$query_table("SampleLocations")
  type_col <- "strata"

} else {
  sample_locations <- mnmdb$query_table("SampleUnits")
  type_col <- "type"

}

## load cell maps and join them with nearest locations
locations_all <- locations_sf %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest_previously_for_comparison = stringr::str_detect(!!!type_col, "^9|^2180|^rbbppm")
  )


# TODO: work with a subset for testing
locations <- locations_all %>%
  filter(!sf::st_is_empty(wkb_geometry)) # %>%
  # filter(grts_address %in% c(23238, 23091910, 6314694))

## random sampling procedure
# location_row <- 42
# one_location <- locations[location_row, ]

generate_mhq_polygon <- function(
    one_location #,
    # is_forest = FALSE,
    # is_mhq_samplelocation = FALSE
  ) {


  cell_center <- sf::st_coordinates(one_location)
  is_forest <- one_location$is_forest
  is_mhq_samplelocation <- one_location$has_mhq_assessment | one_location$in_mhq_samples

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


  if (is_forest && isFALSE(is_mhq_samplelocation)) {
    return(NA)
  } else {
    return(sf::st_as_sf(mhq_safety, crs = 31370))
  }


} # / generate mhq safety polygon



### (1) circle of 10 m radius

pb <- txtProgressBar(
  min = 0, max = nrow(locations),
  initial = 0, style = 1
)

# location_row <- 234
# one_location <- locations[location_row, ]
mhq_locationwise <- function(location_row) {

  setTxtProgressBar(pb, location_row)

  one_location <- locations[location_row, ]

  # is_forest <- one_location$is_forest
  # is_mhq_samplelocation <- assessment_lookup %>%
  #   filter(grts_address == one_location$grts_address) %>%
  #   pull(assessed) %>%
  #   any

  mhq_safety <- generate_mhq_polygon(
    one_location #,
    # is_forest = is_forest,
    # is_mhq_samplelocation = is_mhq_samplelocation
  )
  if (is.na(mhq_safety)) return(NULL)


  if (db_using_locations){
  mhq_safety <- mhq_safety %>%
    mutate(
      samplelocation_id = one_location$samplelocation_id,
      location_id = one_location$location_id,
      grts_address = one_location$grts_address,
    )
  } else {
  mhq_safety <- mhq_safety %>%
    mutate(
      sampleunit_id = one_location$sampleunit_id,
      location_id = one_location$location_id,
      grts_address = one_location$grts_address,
    )
  }

  return(mhq_safety)

}


mhq_polygons <- lapply(
  seq_len(nrow(locations)),
  FUN = mhq_locationwise
)
close(pb) # close the progress bar
mhq_polygons <- bind_rows(mhq_polygons)



## TODO northing - correct to magnetic north
mhq_polygons <- mhq_polygons %>%
  mutate(
    mhqpolygon_id = seq_len(nrow(mhq_polygons))
  )

mhq_polygons <- mhq_polygons %>% sf::st_cast("POLYGON")


sf::st_geometry(mhq_polygons) <- "wkb_geometry"

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.MHQPolygons"))

if (TRUE) {
  mnmdb$execute_sql(
    glue::glue('DELETE FROM "outbound"."MHQPolygons";'),
    verbose = TRUE
  )

  mnmdb$insert_data(
    table_label = "MHQPolygons",
    upload_data = mhq_polygons
  )

}


# source('230_random_placementpoints.R')
