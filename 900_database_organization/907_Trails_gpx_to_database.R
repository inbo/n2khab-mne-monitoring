
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

require("magrittr") %>% suppressPackageStartupMessages() # for the `%>%`

#_______________________________________________________________________________
### load trail

new_trail <- sf::st_read("./data/routes/July 10, 2026 at 645 PM.geojson") %>%
  sf::st_transform(31370)

xyz <- sf::st_coordinates(new_trail)

new_trail <- as_tibble(xyz) %>%
  select(X, Y) %>%
  sf::st_as_sf(coords = c("X", "Y"), crs = 31370) %>%
  rename(wkb_geometry = geometry) %>%
  mutate(
    trail_name = "insectenronde",
    trail_note = "door het Groen Neerland",
    location = "Park van Eden",
    photo = as.character(NA)
  ) %>%
  relocate(wkb_geometry) %>%
  dplyr::summarize(
    do_union = FALSE,
    .by = c(trail_name, trail_note, location, photo)
  ) %>%
  sf::st_cast("LINESTRING")

sf::st_geometry(new_trail) <- "wkb_geometry"

# mapview::mapview(new_trail)




#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

db_label <- "loceval"
suffix <- "-staging"
# suffix <- ""

mnmdb_mirror <- glue::glue("{db_label}{suffix}")

mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmdb_mirror
)

message(glue::glue("\tconnected: psql {mnmdb$shellstring}"))


#_______________________________________________________________________________
### upload data

mnmdb$insert_data(
  table_label = "Trails",
  upload_data = new_trail
)
