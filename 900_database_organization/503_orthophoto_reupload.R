# View: "outbound"."OrthofotoAssessment"
# -> Table: "outbound"."LocationAssessments"
# also relies on "Locations" and "SampleUnits"
# NOTE: SampleUnits normally stem from `fag_stratum_grts_calendar`
# required fields:
#     grts_address           <- grts_address_final
#     grts_join_method       <- grts_join_method
#     schemes
#     scheme_ps_targetpanels <- scheme_ps_targetpanels
#     type                   <- stratum
#     domain_part            <- domain_part
#     is_forest              <- is_forest
#     in_mhq_samples         <- in_mhq_samples
#     has_mhq_assessment
#     mhq_assessment_date    <- last_type_assessment


# $ date_start             <date> n.rel.
# $ date_end               <date> n.rel.
# $ date_interval          <dbl> n.rel.
# $ grts_address           <int> n.rel.
# $ field_activity_group   <chr> n.rel.
#
# $ wait_any               <lgl>
# $ wait_watersurface      <lgl>
# $ wait_3260              <lgl>
# $ wait_7220              <lgl>
# $ wait_floating          <lgl>
# $ geom                   <POINT [m]>
#
# TODO: the "wait"s!?


source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")



## ----database-connection------------------------------------------------------
# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# orthophoto-evaluation happens on `loceval`-db
database_label <- "loceval"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}


### connect to database
locevaldb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(locevaldb$shellstring)

update_cascade_lookup <- parametrize_cascaded_update(locevaldb)

## ----poc-data-----------------------------------------------------------------
# side-load future POC data

data_source <- "data/20260114_loceval_planning.gpkg"
layer_name <- "loceval_planning_2930"

ofo_locations <- sf::st_read(data_source, layer = layer_name)

ofo_locations <- ofo_locations %>%
  select(
    grts_address = grts_address_final,
    grts_join_method,
    # schemes,
    scheme_ps_targetpanels,
    type = stratum,
    domain_part,
    is_forest,
    in_mhq_samples,
    # has_mhq_assessment,
    mhq_assessment_date = last_type_assessment
  ) %>%
  mutate(
    schemes = stringr::str_extract(scheme_ps_targetpanels, "^[^:]+"),
    has_mhq_assessment = !is.na(mhq_assessment_date)
  ) %>%
  relocate(schemes, .before = scheme_ps_targetpanels) %>%
  relocate(has_mhq_assessment, .before = mhq_assessment_date)

## ----Locations----------------------------------------------------------------

locations <- ofo_locations %>%
  select(grts_address) %>%
  dplyr::distinct()

sf::st_geometry(locations) <- "wkb_geometry"

new_locations <- locations %>%
  anti_join(
    locevaldb$query_table("Locations"),
    by = join_by(grts_address)
  )

# mapview::mapview(new_locations)

locations_lookup <- update_cascade_lookup(
  table_label = "Locations",
  new_data = new_locations,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

if (is.null(locations_lookup)) {
  locations_lookup <- locevaldb$query_columns(
      "Locations",
      c("grts_address", "location_id")
    ) %>%
    grts_datatype_to_integer()

}


## ----SampleUnits--------------------------------------------------------------

sample_units <- ofo_locations %>%
  sf::st_drop_geometry() %>%
  as_tibble() %>%
  left_join(locations_lookup, by = join_by(grts_address))

new_sample_units <- sample_units %>%
  anti_join(
    locevaldb$query_table("SampleUnits"),
    by = join_by(grts_address, type)
  ) %>%
  mutate(
    # log_user = "maintenance",
    # log_update = as.POSIXct(Sys.time()),
    replacement_ongoing = FALSE,
    is_replaced = FALSE,
    type_is_absent = FALSE
  )


sampleunits_lookup <- update_cascade_lookup(
  table_label = "SampleUnits",
  new_data = new_sample_units,
  index_columns = c("sampleunit_id"),
  characteristic_columns = c("grts_address", "type"),
  tabula_rasa = FALSE,
  verbose = TRUE
)


if (is.null(sampleunits_lookup)) {
  locations_lookup <- locevaldb$query_columns(
      "SampleUnits",
      c("grts_address", "type", "sampleunit_id")
    ) %>%
    grts_datatype_to_integer()

}

## ----LocationAssessments------------------------------------------------------

new_ofos <- sample_units %>%
  left_join(sampleunits_lookup, by = join_by(grts_address, type)) %>%
  anti_join(
    locevaldb$query_table("LocationAssessments"),
    by = join_by(grts_address, type)
  ) %>%
  distinct(grts_address, type, location_id, sampleunit_id) %>%
  mutate(
    cell_disapproved = FALSE,
    assessment_done = FALSE,
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
  )

# new_ofos %>%
#   count(grts_address, type) %>%
#   arrange(desc(n))

ofos_lookup <- update_cascade_lookup(
  table_label = "LocationAssessments",
  new_data = new_ofos,
  index_columns = c("locationassessment_id"),
  characteristic_columns = c("grts_address", "type"),
  tabula_rasa = FALSE,
  verbose = TRUE
)


## ----location cells-----------------------------------------------------------
# finally, we require the POC

load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())
snippets_path <- rprojroot::find_root(rprojroot::is_git_root)
load_poc_code_snippets(snippets_path)

verify_poc_objects()


locations_grts <- locevaldb$query_columns(
    table_label = "Locations",
    select_columns = c("grts_address", "location_id")
  )

units_cell_polygon[["grts_address_final"]] <-
  as.integer(units_cell_polygon[["grts_address_final"]])
# units_cell_polygon %>% filter(grts_address_final == 922230)

# unit geometries (cells):
location_cells <-
  units_cell_polygon %>%
  inner_join(
    locations_grts %>% distinct,
    by = join_by(grts_address_final == grts_address),
    relationship = "one-to-many",
    unmatched = "drop"
  ) %>%
  select(-grts_address_final) %>%
  relocate(geometry, .after = last_col())


message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of metadata.LocationCells"))

locevaldb$execute_sql(
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

locevaldb$insert_data(
  table_label = "LocationCells",
  upload_data = location_cells
)

extra_cells <- locevaldb$query_table("ReplacementCells") %>%
  left_join(
    locevaldb$query_table("Replacements") %>%
      select(-wkb_geometry),
    by = join_by(replacement_id)
  ) %>%
  select(-grts_address) %>%
  rename(grts_address = grts_address_replacement) %>%
  inner_join(
    locations_grts,
    by = join_by(grts_address)
  ) %>%
  select(location_id, wkb_geometry) %>%
  distinct %>%
  anti_join(
    location_cells,
    by = join_by(location_id)
  )

locevaldb$insert_data(
  table_label = "LocationCells",
  upload_data = extra_cells
)



## ----FK linkage---------------------------------------------------------------

if (locevaldb$mirror_short == "") {
  source(glue::glue('102_re_link_foreign_keys.R'))
} else {
  system(glue::glue(
    "Rscript 102_re_link_foreign_keys.R -{locevaldb$mirror_short}"
  ))
}



## ----TODOS--------------------------------------------------------------------
# LocationCells -> via existing script?
# LocationAssessments to link_id script
