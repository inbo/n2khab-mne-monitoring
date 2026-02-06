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

suffix <- "-staging"

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



## ----TODOS--------------------------------------------------------------------
# LocationCells -> via existing script?
