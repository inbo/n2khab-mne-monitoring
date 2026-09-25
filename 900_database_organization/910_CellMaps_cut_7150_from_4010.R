#!/usr/bin/env Rscript

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

database <- "loceval"
suffix <- ""

locevaldb <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("{database}{suffix}")
)

message(glue::glue("\tconnected: psql {locevaldb$shellstring}"))


### download all CellMaps

cellmaps_original <- locevaldb$query_table("CellMaps") %>%
  sf::st_as_sf()


check_empty_geoms <- cellmaps_original %>%
  filter(sf::st_is_empty(wkb_geometry))

if (nrow(check_empty_geoms) > 0) {
  print(check_empty_geoms %>% knitr::kable())
  stop("There are empty geometries in the `Locations` table!")
}


cellmaps_4010 <- cellmaps_original %>%
  filter(type == "4010")
cellmaps_cut <- cellmaps_4010 %>% as_tibble()
m1 <- mapview::mapview(cellmaps_4010, col.regions = "blue")
m1


cellmaps_7150 <- cellmaps_original %>%
  filter(type == "7150")

for (row_4010 in seq_len(nrow(cellmaps_4010))) {
  one_cellmap <- cellmaps_4010[row_4010,]
  one_geometry <- sf::st_geometry(one_cellmap)

  overlaps <- cellmaps_7150 %>% sf::st_intersection(one_cellmap)
  for (row_overlap in seq_len(nrow(overlaps))) {
    one_overlap <- overlaps[row_overlap,]
    one_geometry <- one_geometry %>% sf::st_difference(one_overlap)
  }

  cellmaps_cut[cellmaps_cut$cellmap_id == one_cellmap$cellmap_id, ]$wkb_geometry <- one_geometry
}

m2 <- mapview::mapview(cellmaps_cut %>% sf::st_as_sf(), col.regions = "red")
m1+m2


srctab <- "temp_upd_cellmaps"
trgtab <- locevaldb$get_namestring("CellMaps")

timestamp_types <- c(
  "log_creation" = "timestamp(3)",
  "log_update" = "timestamp(3)"
)


rs <- sf::st_write(
  cellmaps_cut,
  locevaldb$connection,
  srctab,
  row.names = FALSE,
  delete_layer = TRUE, # "overwrite"
  factorsAsCharacter = TRUE,
  binary = TRUE,
  temporary = TRUE,
  field.types = timestamp_types
)

# concat update query
# ogc_fid = SRCTAB.ogc_fid,
update_string <- glue::glue("
   UPDATE {trgtab} AS TRGTAB
     SET
       wkb_geometry = ST_GeomFromText(ST_AsText(SRCTAB.wkb_geometry))
     FROM {srctab} AS SRCTAB
     WHERE
      ( TRGTAB.cellmap_id = SRCTAB.cellmap_id )
      AND ( TRGTAB.type = SRCTAB.type )
   ;")

# -- AND ( TRGTAB.log_creation = SRCTAB.log_creation )

# execute update
locevaldb$execute_sql(update_string, verbose = FALSE)

# drop temptable
locevaldb$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)




# locevaldb$query_table("CellMaps") %>%
#   filter(cellmap_id == 135) %>%
#   sf::st_as_sf() %>% plot()
