#!/usr/bin/env Rscript

# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

library("magrittr")
library("readr")

#_______________________________________________________________________________
### connect database

config_filepath <- file.path("./mnm_database_connection.conf")
# suffix <- ""
suffix <- "-staging"
# suffix <- "-testing"

# connect mnmsurfdb
mnmsurfdb_mirror <- glue::glue("mnmsurfdb{suffix}")

mnmsurfdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsurfdb_mirror
)


# keyring::keyring_delete(keyring = "mnmdb_temp")
message(glue::glue("connected: psql {mnmsurfdb$shellstring}"))
update_cascade_lookup <- parametrize_cascaded_update(mnmsurfdb)



table_label <- "ChlorophyllMeasurements"
characols <- c("grts_address", "iteration")

test <- mnmsurfdb$query_table("ChlorophyllMeasurements")


#_______________________________________________________________________________
### load updated data

chl_file <- here::here("sideload", "chlorophyll_locations_20260812.csv")
chl_data <- readr::read_delim(
  file = chl_file,
  delim = ",",
  quote = "\"",
  col_types = readr::cols(
    grts_address = readr::col_integer(),
    iteration = readr::col_integer(),
    planned_in_app = readr::col_logical()
  )
)

chl_data %>% glimpse()

# convert pool_in_rep and date_first_visit
chl_data %<>% mutate(
    pool_in_rep = tolower(pool_in_rep) == "meetnet",
    date_first_visit = as.Date(date_first_visit)
  ) %>%
  select(-planned_in_app)

# check locations

grts_valid <- mnmsurfdb$query_table("Locations") %>% distinct(grts_address)

grts_unknown <- chl_data %>%
  anti_join(grts_valid, by = join_by(grts_address)) %>%
  select(grts_address)

if (nrow(grts_unknown) > 0) {

locations_grts_collection <- grts_unknown %>%
  mutate(
    grts_address = as.integer(grts_address),
    is_cell_center = TRUE
  ) %>%
  distinct() %>%
  arrange(grts_address)

load_rep_common_libraries()
load_rep_rdata(reload = FALSE, to_env = globalenv())

# join geometry column
grts_mh <- n2khab::read_GRTSmh()

grts_mh_index <- dplyr::tibble(
    id = seq_len(terra::ncell(grts_mh)),
    grts_address = values(grts_mh)[, 1]
  ) %>%
  dplyr::filter(!is.na(grts_address))

locations_upload <- locations_grts_collection %>%
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(locations_upload) <- "wkb_geometry"

prior_empty <- locations_upload %>%
  filter(sf::st_is_empty(wkb_geometry))

if (nrow(prior_empty) > 0) {
  print(prior_empty %>% knitr::kable())
  stop("There are empty geometries prior to uploading the `Locations` table!")
}


locations_lookup <- update_cascade_lookup(
  table_label = "Locations",
  new_data = locations_upload,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

}


# check strata
n2khabstrata <- mnmsurfdb$query_table("N2kHabStrata") %>% distinct(stratum)

missing_strata <- chl_data %>% anti_join(
  n2khabstrata,
  by = join_by(stratum)
)

if (nrow(missing_strata) > 0) {
  print(missing_strata %>% knitr::kable())
  stop("There are undefined strata!")

}


chl_data %>% glimpse()

#_______________________________________________________________________________
### upload

chlorophyllmeasurements_lookup <- update_cascade_lookup(
  table_label = table_label,
  new_data = chl_data,
  index_columns = c("chlorophyllmeasurement_id"),
  characteristic_columns = characols,
  tabula_rasa = FALSE,
  verbose = TRUE
)
