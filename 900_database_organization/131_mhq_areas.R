
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
working_dbname <- "loceval"
connection_profile <- "loceval"

db_using_locations <- grepl("mnmgwdb", working_dbname)

config <- configr::read.config(file = config_filepath)[[connection_profile]]
source("MNMDatabaseToolbox.R")

# database connection
db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = connection_profile,
  database = working_dbname
)


if (TRUE){
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



## load SampleLocations

locations_sf <- sf::st_read(
  db_connection,
  DBI::Id("metadata", "Locations")
  ) %>%
  select(-ogc_fid) %>%
  collect

if (db_using_locations){
sample_locations <- dplyr::tbl(
  db_connection,
  DBI::Id("outbound", "SampleLocations")
  ) %>%
  collect

## load cell maps and join them with nearest locations


locations_all <- locations_sf %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest = stringr::str_detect(strata, "^9|^2180|^rbbppm")
  )

} else {
sample_locations <- dplyr::tbl(
  db_connection,
  DBI::Id("outbound", "SampleUnits")
  ) %>%
  collect

## load cell maps and join them with nearest locations
locations_all <- locations_sf %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest = stringr::str_detect(type, "^9|^2180|^rbbppm")
  )
}



# TODO: work with a subset for testing
locations <- locations_all # %>%
  # filter(grts_address %in% c(23238, 23091910, 6314694))

## random sampling procedure

generate_mhq_polygon <- function(
    one_location,
    is_forest = FALSE,
    is_assessed = FALSE
  ) {


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


  if (is_forest && !is_assessed) {
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
mhq_locationwise <- function(location_row) {

  setTxtProgressBar(pb, location_row)

  one_location <- locations[location_row, ]

  is_forest <- one_location$is_forest
  is_assessed <- assessment_lookup %>%
    filter(grts_address == one_location$grts_address) %>%
    pull(assessed) %>%
    any

  mhq_safety <- generate_mhq_polygon(
    one_location,
    is_forest = is_forest,
    is_assessed = is_assessed
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
  1:nrow(locations),
  FUN = mhq_locationwise
)
close(pb) # close the progress bar
mhq_polygons <- bind_rows(mhq_polygons)



## TODO northing - correct to magnetic north
mhq_polygons <- mhq_polygons %>%
  mutate(
    mhqpolygon_id = 1:nrow(mhq_polygons)
  )

mhq_polygons <- mhq_polygons %>% sf::st_cast("POLYGON")


sf::st_geometry(mhq_polygons) <- "wkb_geometry"

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.MHQPolygons"))

if (TRUE) {
  execute_sql(
    db_connection,
    glue::glue('DELETE FROM "outbound"."MHQPolygons";'),
    verbose = TRUE
  )

  append_tabledata(
    db_connection,
    DBI::Id(schema = "outbound", table = "MHQPolygons"),
    mhq_polygons,
    reference_columns = "mhqpolygon_id"
  )

}


# source('230_random_placementpoints.R')
