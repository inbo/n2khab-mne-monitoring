## libraries----------------------------------------------------------------
# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()
load_poc_common_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


## ----------loading-poc-data-----------------------------------

tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()
load_poc_rdata(reload = FALSE, to_env = parent.frame())
message(glue::glue("Good morning!
  Loading the POC data took {tic(toc)} seconds today."
))


## ----------loading-snippets-----------------------------------

# TODO: rebase once PR#5 gets merged
snippets_path <- "/data/git/n2khab-mne-monitoring_support"

toc <- Sys.time()
load_poc_code_snippets(snippets_path)
message(glue::glue(
  "... loading/executing the code snippets took {tic(toc)}s."
))


verify_poc_objects()


## ----establish-connection-config----------------------------------------------
config_filepath <- file.path("./inbopostgis_server.conf")

# keyring::key_set("DBPassword", "db_user_password") # <- for source database

loceval_db <- connect_mnm_database(
  config_filepath,
  database_mirror = "loceval-dev"
)


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update

update_cascade_lookup <- parametrize_cascaded_update(loceval_db)


## ----upload-teammembers-------------------------------------------------------
members <- read_csv(
  here::here(loceval_db$folder, "data_TeamMembers.csv"),
  show_col_types = FALSE
)

member_lookup <- update_cascade_lookup(
  table_label = "TeamMembers",
  new_data = members,
  index_columns = c("teammember_id"),
  characteristic_columns = c("username"),
  verbose = TRUE
)


## ----upload-protocols---------------------------------------------------------
protocols <- activities %>%
  select(protocol) %>%
  distinct() %>%
  arrange(protocol) %>%
  filter(!is.na(protocol)) %>%
  mutate(
    protocol_id = 1:n(),
    protocol = as.character(protocol),
    description = NA
  )

protocol_lookup <- update_cascade_lookup(
  table_label = "Protocols",
  new_data = protocols,
  index_columns = c("protocol_id"),
  characteristic_columns = c("protocol"),
  verbose = TRUE
)


## ----prepare-activities-------------------------------------------------------
# # there are some activities with different ranks within a sequence.
# activity_groupcount <- activity_sequences %>%
#   distinct(activity, activity_group, rank) %>%
#   count(activity, activity_group) %>%
#   arrange(desc(n))

activity_group_lookup <-
  activity_sequences %>%
    distinct(activity_group, activity)

grouped_activities <-
  activities %>%
  left_join(
    activity_group_lookup,
    join_by(activity),
    relationship = "one-to-many"
  )

# knitr::kable(grouped_activities %>% distinct(activity_group, activity))

# replace group non-sequenced activities with activity name
grouped_activities <- grouped_activities %>%
  mutate_at(
    vars(activity_group, activity, activity_name, protocol),
    as.character
  ) %>%
  mutate(
    activity_group = ifelse(is.na(activity_group), activity, activity_group)
  )
# %>% select(activity, activity_group) %>% tail(10) %>% knitr::kable()


grouped_activities <- grouped_activities %>%
  arrange(activity) %>%
  group_by(activity) %>%
  mutate(activity_id = cur_group_id()) %>%
  ungroup %>%
  arrange(activity_group) %>%
  group_by(activity_group) %>%
  mutate(activity_group_id = cur_group_id()) %>%
  ungroup %>%
  arrange(activity_group, activity) %>%
  group_by(
    activity_group,
    activity
  ) %>%
  mutate(grouped_activity_id = cur_group_id()) %>%
  ungroup %>%
  relocate(
    grouped_activity_id,
    activity_group_id,
    activity_group,
    activity_id,
    activity,
    .before = 1
  )


# grouped_activities %>%
#   filter(is.na(activity_group_id))
#   filter(activity_group == "GWINSTPIEZWELL")
# knitr::kable(grouped_activities %>% distinct(activity_group, activity, activity_name))

# glimpse(grouped_activities)

# tag activities for biotic location evaluation
grouped_activities <- grouped_activities %>%
  mutate(
    is_loceval_activity =
      activity_group %in% c(
        "LOCEVALAQ",
        "LOCEVALTERR",
        "LSVIAQ",
        "LSVITERR",
        "SURFLENTLOCEVALSAMPLPOINT",
        "SURFLOTLOCEVALSAMPLPOINT",
        "SURFLENTSAMPLPOINT",
        "SURFLOTSAMPLPOINT"
        )
  )
#    , wrong_loceval_activity =
#       activity %in% c(
#         "LOCEVALAQ",
#         "LOCEVALAQ",
#         "LOCEVALAQ",
#         "LOCEVALTERR",
#         "LSVIAQ",
#         "LSVITERR",
#         "SURFLENTSAMPLPOINT",
#         "SURFLOTSAMPLPOINT"
#         )
# knitr::kable(grouped_activities %>%
#   filter(is_loceval_activity != wrong_loceval_activity) %>%
#   select(-grouped_activity_id, -activity_id, -activity_group_id, -protocol, -is_lab_activity, -is_prep_activity)
#   )

## ----upload-grouped-activities------------------------------------------------

grouped_activities_upload <- grouped_activities %>%
  lookup_join(protocol_lookup, "protocol")

# NOT append_tabledata(
#   db_connection,
#   DBI::Id(schema = "metadata", table = "GroupedActivities"),
#   grouped_activities_upload,
#   reference_columns = "grouped_activity_id"
# )

# -> done manually to get multiple columns as unique lookup

grouped_activity_lookup <- update_cascade_lookup(
  table_label = "GroupedActivities",
  new_data = grouped_activities_upload,
  index_columns = c("grouped_activity_id"),
  characteristic_columns = c("activity_group", "activity"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


## ----upload-n2khabtype--------------------------------------------------------
## n2khab type to stratum (below)

## already included "out-of-the-snippet"
extra_types <- n2khab_strata %>%
  distinct(type) %>%
  expand_types(mark = TRUE) %>%
  filter(added_by_expansion) %>%
  select(type) %>%
  inner_join(
    read_types() %>%
      select(1:3) %>%
      filter(typelevel == "subtype"),
    join_by(type)
  )

n2khab_types_upload <- bind_rows(
  as_tibble(list(
    type = c("gh"),
    typelevel = c("main_type"),
    main_type = c("gh")
  )),
  n2khab_types_expanded_properties
  # extra_types
  ) %>%
  arrange(main_type, type)

# n2khab_types_upload %>%
#   count(main_type, type) %>%
#   arrange(desc(n))

n2khabtype_lookup <- update_cascade_lookup(
  table_label = "N2kHabTypes",
  new_data = n2khab_types_upload,
  index_columns = c("n2khabtype_id"),
  characteristic_columns = c("type"),
  verbose = TRUE
)


# SELECT DISTINCT type FROM "metadata"."N2kHabTypes" ORDER BY type;
n2khab_strata %>% filter(grepl('91[6E]0.*', type))

n2khab_strata_upload <- bind_rows(
  as_tibble(list(
    type = c("gh"),
    stratum = c("gh")
  )),
    n2khab_strata
  ) %>%
  left_join(
    n2khabtype_lookup,
    by = join_by(type),
    relationship = "many-to-one",
  ) %>%
  select(-type)


n2khabstrata_lookup <- update_cascade_lookup(
  table_label = "N2kHabStrata",
  new_data = n2khab_strata_upload,
  index_columns = c("n2khabstratum_id"),
  characteristic_columns = c("stratum"),
  verbose = TRUE
)



## ----collect-sample-locations----------------------------------------------
# glimpse(fag_stratum_grts_calendar)

sample_units <-
  fag_stratum_grts_calendar %>%
  common_current_calenderfilters() %>%
  distinct(
    scheme_moco_ps,
    stratum,
    grts_address
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      select(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ) %>%
      # deduplicating 7220:
      distinct(),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  common_current_samplefilters() %>%
  # also join the spatial poststratum, since we need this in setting
  # GRTS-address based priorities
  inner_join(
    scheme_moco_ps_stratum_sppost_spsamples %>%
      unnest(sp_poststr_samples) %>%
      select(-sample_status),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  select(-module_combo_code) %>%
  nest_scheme_ps_targetpanel() %>%
  # add MHQ assessment metadata
  inner_join(
    stratum_grts_n2khab_phabcorrected_no_replacements %>%
      select(stratum, grts_address, assessed_in_field, assessment_date),
    join_by(stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  distinct() %>%
  convert_stratum_to_type() %>%
  rename_grts_address_final_to_grts_address() %>%
  rename(
    assessment = assessed_in_field,
    assessment_date = assessment_date # triv.
  ) %>%
  relocate(grts_address) %>%
  relocate(grts_join_method, .after = grts_address) %>%
  mutate(
    previous_notes = NA # FUTURE TODO
  ) %>%
  mutate(
    across(c(
        grts_join_method,
        scheme_ps_targetpanels,
        sp_poststratum,
        type
      ),
      as.character
    )
  )

# glimpse(sample_units)

# still need to join the location, below
# TODO in the FUTURE, make sure `type` is
#      correctly filled from LOCEVAL
#      "previous_assessment" -> "assessment"
#      and add previous_notes


## ----save-previous-location-infos----------------------------------------------
table_label <- "LocationInfos"
filter_unused <- "
      ((accessibility_inaccessible IS NULL) OR (NOT accessibility_inaccessible))
  AND (accessibility_revisit IS NULL)
  AND (recovery_hints IS NULL)
"
loceval_db$delete_unused(table_label, filter_unused)

previous_locationinfos <- loceval_db$query_table(table_label)


## ----save-previous-location-assessments----------------------------------------------

table_label <- "LocationAssessments"
filter_unused <- "
      ((cell_disapproved IS NULL) OR (cell_disapproved))
  AND (revisit_disapproval IS NULL)
  AND (disapproval_explanation IS NULL)
  AND (type_suggested IS NULL)
  AND ((implications_habitatmap IS NULL) OR (implications_habitatmap IS FALSE))
  AND (feedback_habitatmap IS NULL)
  AND (notes IS NULL)
  AND NOT assessment_done
"
loceval_db$delete_unused(table_label, filter_unused)

previous_location_assessments <- loceval_db$query_table(table_label)
# nrow(previous_location_assessments)


## ----save-previous-extra-visits----------------------------------------------
# analogous: clean Visits
table_label <- "Visits"
filter_unused <- "
      (grouped_activity_id IS NULL)
  AND (teammember_id IS NULL)
  AND (date_visit IS NULL)
  AND (type_assessed IS NULL)
  AND (notes IS NULL)
  AND (photo IS NULL)
  AND NOT visit_done
"
loceval_db$delete_unused(table_label, filter_unused)

previous_visits <- loceval_db$query_table(table_label)


## ----save-previous-FACs----------------------------------------------

table_label <- "FieldActivityCalendar"
filter_unused <- "
      (NOT excluded)
  AND (excluded_reason IS NULL)
  AND (teammember_assigned IS NULL)
  AND (date_visit_planned IS NULL)
  AND ((no_visit_planned IS NULL) OR (no_visit_planned IS FALSE))
  AND (notes IS NULL)
  AND NOT done_planning
"

loceval_db$delete_unused(table_label, filter_unused)

previous_calendar_plans <- loceval_db$query_table(table_label)


## ----replacement-archive-------------------------------------------

# store replacement information of previous visits

previous_sampleunits <- loceval_db$query_table("SampleUnits") %>%
  select(
    sampleunit_id,
    grts_address,
    grts_join_method,
    scheme,
    panel_set,
    targetpanel,
    scheme_ps_targetpanels,
    sp_poststratum,
    type,
    replacement_reason,
    replacement_permanence
  )


previous_replacements <- loceval_db$query_table("Replacements") %>%
  select(-wkb_geometry) %>%
  filter(
    is_inappropriate
    | is_selected
    | (implications_habitatmap)
    | (!is.na(notes))
  ) %>%
  left_join(
    previous_sampleunits,
    by = join_by(sampleunit_id)
  )

if (nrow(previous_replacements) > 0) {
  replacement_archive_lookup <- update_cascade_lookup(
    table_label = "ReplacementArchives",
    new_data = previous_replacements,
    index_columns = c("replacementarchive_id"),
    characteristic_columns = c(
      "scheme_ps_targetpanels",
      "type",
      "grts_address",
      "grts_address_replacement",
      "replacement_rank"
    ),
    tabula_rasa = FALSE,
    verbose = TRUE
  )
}


## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - locationassessments_data
#    - sample_units
#    - TODO previous visits even in case of replacement
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_units

# sample_units %>% pull(grts_address) %>% write.csv("dumps/sample_units.csv")
# previous_location_assessments %>% pull(grts_address) %>% write.csv("dumps/location_assessments.csv")
# 15937

locations <- bind_rows(
    sample_units %>% select(grts_address),
    previous_locationinfos %>% select(grts_address),
    previous_location_assessments %>% select(grts_address),
    previous_visits %>% select(grts_address)
  ) %>%
  mutate(grts_address = as.integer(grts_address)) %>%
  distinct() %>%
  # count(grts_address) %>%
  # arrange(desc(n))
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(locations) <- "wkb_geometry"


locations_lookup <- update_cascade_lookup(
  table_label = "Locations",
  new_data = locations,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = TRUE,
  verbose = TRUE
)
# locations_lookup %>% write.csv("dumps/lookup_locations.csv")
# locations are nuique.

# **Upload Location Cells as polygons:**

units_cell_polygon[["grts_address_final"]] <-
  as.integer(units_cell_polygon[["grts_address_final"]])

# unit geometries (cells):
location_cells <-
  units_cell_polygon %>%
  inner_join(
    locations_lookup,
    by = join_by(grts_address_final == grts_address),
    relationship = "one-to-many",
    unmatched = "drop"
  ) %>%
  select(-grts_address_final) %>%
  relocate(geometry, .after = last_col())

sf::st_geometry(location_cells) <- "wkb_geometry"
# glimpse(location_cells)

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of metadata.LocationCells"))

loceval_db$execute_sql(
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

loceval_db$insert(
 table_label = "LocationCells",
 new_data = location_cells
)

# SELECT LC.ogc_fid, LC.location_id, LOC.grts_address
# FROM "metadata"."LocationCells" AS LC
# LEFT JOIN "metadata"."Locations" AS LOC ON LOC.location_id = LC.location_id
# WHERE grts_address IS NULL;


## ----upload-sample-locations----------------------------------------------

if ("location_id" %in% names(sample_units)) {
  # should not be the case in a continuous script;
  # this is extra safety for debugging and de-serial execution
  sample_units <- sample_units %>%
    select(-location_id)
}
sample_units <- sample_units %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  )


samuns_refcols <- c(
  "type",
  "grts_address",
  "scheme",
  "panel_set",
  "targetpanel"
  # "sp_poststratum"
)

# tabula rasa: might otherwise be duplicated due to missing fk and null constraint
sample_units_lookup <- update_cascade_lookup(
  table_label = "SampleUnits",
  new_data = sample_units,
  index_columns = c("sampleunit_id"),
  characteristic_columns = samuns_refcols,
  tabula_rasa = TRUE,
  verbose = TRUE
)


# restore location_id's
# restore_location_id_by_grts(
#   loceval_db,
#   table_label = "SampleUnits",
#   retain_log = FALSE,
#   verbose = TRUE
# )


# sample_units_lookup %>% nrow()
# sample_units_lookup %>%
#   select(!!!samuns_refcols) %>%
#   distinct %>%
#   nrow()



## ----polygons-------------------------------------------------


sample_units_for_polygons <- sample_units_lookup %>%
  select(type, grts_address, sampleunit_id)

sampleunit_grts_cellcenters_for_polygons <- sample_units_for_polygons %>%
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

habmap_unique_polygons <- vect(file.path(
    locate_n2khab_data(),
    "10_raw/habitatmap/habitatmap.gpkg"
  )) %>%
  .[vect(sampleunit_grts_cellcenters_for_polygons)] %>%
  as.polygons() %>%
  sf::st_as_sf() %>%
  select(geometry)

# note that polygons are multiplicated with this method if
# they contain multiple sample units.
sample_polygons <- cbind(
  sampleunit_grts_cellcenters_for_polygons %>%
    sf::st_drop_geometry(),
  habmap_unique_polygons[
  sampleunit_grts_cellcenters_for_polygons %>%
    sf::st_nearest_feature(habmap_unique_polygons)
  , ]
  ) %>%
  # (FM just copied this from FV)
  # to prefer the tibble approach in sf, we need to convert forth and back
  as_tibble() %>%
  # it appears that the CRS is actually retrieved from the tibble, but I don't
  # understand how (so the crs argument below isn't needed)
  st_as_sf(crs = "EPSG:31370") %>%
  select(sampleunit_id)


sf::st_geometry(sample_polygons) <- "wkb_geometry"
# mapview(sample_polygons)


message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.SampleUnitPolygons"))

loceval_db$execute_sql(
  glue::glue('DELETE  FROM "outbound"."SampleUnitPolygons";'),
  verbose = TRUE
)

loceval_db$insert(
  table_label = "SampleUnitPolygons",
  new_data = sample_polygons
)


## ----location-infos-------------------------------------------------

# assemble new assessments
new_locinfos <- sample_units %>%
  distinct(
    grts_address
  ) %>%
  mutate(
    log_creator = "maintenance",
    log_creation = as.POSIXct(Sys.time()),
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )

# previous_locationinfos %>% write.csv("data/20250704_Wards_LocationAssessments.csv")

new_locinfos <- new_locinfos %>%
  anti_join(
    previous_locationinfos,
    by = join_by(grts_address)
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
  )

locationinfo_lookup <- update_cascade_lookup(
  table_label = "LocationInfos",
  new_data = new_locinfos,
  index_columns = c("locationinfo_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)


## ----fieldwork-calendar-------------------------------------------------

# grouped_activities %>% distinct(activity_group, activity_group_id) %>% count(activity_group) %>% print(n=Inf)


activity_groupid_lookup <- loceval_db$query_columns(
    table_label = "GroupedActivities",
    select_columns = c("activity_group", "activity_group_id")
    ) %>%
  distinct()

# activity_groupid_lookup %>% distinct(activity_group, activity_group_id) %>% count(activity_group) %>% print(n=Inf)


fieldwork_calendar <-
  fieldwork_2025_prioritization_by_stratum %>%
  rename_grts_address_final_to_grts_address() %>%
  relocate(grts_address) %>%
  relocate(grts_join_method, .after = grts_address) %>%
  select(
    -scheme_ps_targetpanels
  ) %>%
  inner_join(
    n2khab_strata,
    join_by(stratum),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  left_join(
    sample_units_lookup %>%
      select(type, grts_address, sampleunit_id),
    by = join_by(type, grts_address),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  ) %>%
  select(-type) %>%
  rename(activity_rank = rank) %>%
  left_join(
    activity_groupid_lookup,
    by = join_by(field_activity_group == activity_group),
    relationship = "many-to-one"
  ) %>%
  select(-field_activity_group) %>%
  mutate(
    across(c(
        stratum,
        grts_join_method,
        date_interval,
        domain_part
      ),
      as.character
    )
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  )

# fieldwork_calendar %>% glimpse

fieldwork_calendar_lookup <- update_cascade_lookup(
  table_label = "FieldActivityCalendar",
  new_data = fieldwork_calendar,
  index_columns = c("fieldactivitycalendar_id"),
  characteristic_columns = c(
    "sampleunit_id",
    "stratum",
    "grts_address",
    "priority",
    "date_start",
    "grts_join_method",
    "activity_group_id",
    "activity_rank"
  ),
  tabula_rasa = FALSE,
  verbose = TRUE
)


## ----replacements-------------------------------------------------

#| eval: true
# glimpse(stratum_schemepstargetpanel_spsamples_terr_replacementcells)

# (DONE: store previous replacement info to another table)

replacements <-
  stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
  select(stratum, grts_address, replacement_cells) %>%
  unnest(replacement_cells) %>%
  filter(!is.na(cellnr_replac)) %>%
  left_join(
    n2khab_strata,
    by = join_by(stratum),
    relationship = "many-to-many" # TODO
  ) %>%
  select(-stratum) %>%
  rename(
    cellnr_replacement = cellnr_replac,
    grts_address_replacement = grts_address_replac,
    replacement_rank = ranknr
  ) %>%
  left_join(
    sample_units_lookup %>%
      select(type, grts_address, sampleunit_id),
    by = join_by(type, grts_address),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  )

replacements_upload <- replacements %>%
  select(
    -type,
    -grts_address,
    -cellnr_replacement
  ) %>%
  filter(!is.na(sampleunit_id)) %>%
  add_point_coords_grts(
    grts_var = "grts_address_replacement",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(replacements_upload) <- "wkb_geometry"

# glimpse(replacements_upload)


# upload new replacements, TABULA RASA
replacements_lookup <- update_cascade_lookup(
  table_label = "Replacements",
  new_data = replacements_upload,
  index_columns = c("replacement_id"),
  characteristic_columns = c("sampleunit_id", "grts_address_replacement"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


## ----replacement-cells-------------------------------------------------
# cell square polygons for replacement cells

replacement_cell_rast <- replacements %>%
  pull(grts_address_replacement) %>%
  filter_grtsraster_by_address(spatrast = grts_mh, spatrast_index = grts_mh_index)
set.names(replacement_cell_rast, "grts_address_replacement")

replacement_cell_polygons <-
  replacement_cell_rast %>%
  as.polygons(aggregate = FALSE) %>%
  sf::st_as_sf()

replacement_cells <- replacement_cell_polygons %>%
  # to prefer the tibble approach in sf, we need to convert forth and back
  as_tibble() %>%
  mutate(grts_address_replacement = as.integer(grts_address_replacement)) %>%
  # it appears that the CRS is actually retrieved from the tibble, but I don't
  # understand how (so the crs argument below isn't needed)
  st_as_sf(crs = "EPSG:31370")

replacement_cells <-
  replacement_cells %>%
  inner_join(
    replacements_lookup,
    by = join_by(grts_address_replacement),
    relationship = "one-to-many",
    unmatched = "drop"
  ) %>%
  select(replacement_id)

sf::st_geometry(replacement_cells) <- "wkb_geometry"

message("________________________________________________________________")
message(glue::glue("DELETE/INSERT of outbound.ReplacementCells"))

loceval_db$execute_sql(
  glue::glue('DELETE  FROM "outbound"."ReplacementCells";'),
  verbose = TRUE
)

loceval_db$insert(
  table_label = "ReplacementCells",
  new_data = replacement_cells
)



## ----restore-assessments-------------------------------------------------

# Here, we want to keep existing location assessments,
# UNLESS they never happened:
#  - imagine a sample unit X coming into the sample, then it will get a
#    prepared row for LocationAssessment
#  - however, if that sample unit is removed upon POC update without ever being
#    assessed, we remove it before.


# assemble new assessments
new_location_assessments <- sample_units %>%
  distinct(
    grts_address,
    type
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    cell_disapproved = FALSE,
    assessment_done = FALSE
  )

# previous_location_assessments %>% write.csv("data/20250704_Wards_LocationAssessments.csv")

new_location_assessments <- new_location_assessments %>%
  anti_join(
    previous_location_assessments,
    by = join_by(type, grts_address)
  ) %>%
  # select(-location_id) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
  )

# SELECT DISTINCT log_user, assessment_done, count(*) FROM "outbound"."LocationAssessments" GROUP BY log_user, assessment_done;
# SELECT DISTINCT type, grts_address, COUNT(*) AS n FROM "outbound"."LocationAssessments" GROUP BY type, grts_address ORDER BY n DESC;

# upload_location_assessments <- bind_rows(
#   previous_location_assessments,
#   new_location_assessments
#   ) %>%
#   select(-locationassessment_id)
# # nrow(upload_location_assessments)


# append the LocationAssessments with empty lines for new sample units
locationassessment_lookup <- update_cascade_lookup(
  table_label = "LocationAssessments",
  new_data = new_location_assessments,
  index_columns = c("locationassessment_id"),
  characteristic_columns = c("type", "grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

# DONE the "old" ones also require a new location_id
#    -> write a function to UPDATE the lookup key by grts_address
#
## TODO trigger warning
# # DROP TRIGGER IF EXISTS log_assessments ON "outbound"."LocationAssessments";
# # CREATE TRIGGER log_assessments
# # BEFORE UPDATE ON "outbound"."LocationAssessments"
# # FOR EACH ROW EXECUTE PROCEDURE sync_mod();

# restore location_id's
restore_location_id_by_grts(
  loceval_db,
  table_label = "LocationAssessments",
  retain_log = TRUE,
  verbose = TRUE
)



## ----extra-visits-------------------------------------------------
##

new_visits <- sample_units_lookup %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  select(sampleunit_id, location_id, grts_address) %>%
  mutate(
    grouped_activity_id = NA,
    teammember_id = NA,
    date_visit = as.Date(NA),
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    visit_done = FALSE
  )

# new_visits %>%
#   count(location_id, grts_address) %>%
#   arrange(desc(n))


# NOTE the location is still not unique?!
# -> Of course:
#     There are multiple sample units with different `type`
#     on identical locations.

# append the LocationAssessments with empty lines for new sample units
visits_lookup <- update_cascade_lookup(
  table_label = "Visits",
  new_data = new_visits,
  index_columns = c("visit_id"),
  characteristic_columns = c("grts_address", "sampleunit_id"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

# restore location_id's
restore_location_id_by_grts(
  loceval_db,
  table_label = "Visits",
  retain_log = TRUE,
  verbose = TRUE
)


## ----land-use-------------------------------------------------


# locs <- sf::st_read(
#   db_connection,
#   DBI::Id(schema = "metadata", table = "Locations"),
#   ) %>% collect()
# locations_lookup <- locs %>% select(grts_address, location_id)
# locations_lookup <- locations_lookup %>% sf::st_drop_geometry()

landuse <- readRDS("data/landuse_export.rds")

# forestry_area, # bosbeheerregio
# fores_naam, # bosbeheer
# np_type, # natuurpunt
# lila_statuut,
# durme_reservaat,
# perc_rbh, # percelen // rbh
# perc_naameig, # naam eigenaar
# nbhp_type, # natuurbeheerplan
# gewasgroep, # landbouw
# lblhfdtlt # landbouw

landinfo <- landuse %>%
  mutate(anb = stringr::str_c("ANB: ", anb_rights)) %>%
  mutate(mil = stringr::str_c("MIL: ", mdbd_naam, " (", mdbd_inbo, ")")) %>%
  mutate(bos = stringr::str_c("BOS: ", forestry_area, " (", fores_naam, ")")) %>%
  mutate(np = stringr::str_c("NP: ", np_type)) %>%
  mutate(lila = stringr::str_c("LILA: ", lila_statuut)) %>%
  mutate(durme = stringr::str_c("DURME: ", durme_reservaat)) %>%
  mutate(perc = stringr::str_c("PERC: ", perc_rbh, " (", perc_naameig, ")")) %>%
  mutate(nbhp = stringr::str_c("NBHP: ", nbhp_type)) %>%
  mutate(lb = stringr::str_c("LB: ", gewasgroep, " (", lblhfdtlt, ")")) %>%
  tidyr::unite(landuse, c(
      anb, mil, bos,
      np, lila, durme,
      perc, nbhp, lb
    ),
    sep = ", ",
    na.rm = TRUE
  ) %>%
  distinct(
    # schemegroup,
    # stratum,
    grts_address,
    landuse
  ) %>%
  semi_join(
    loceval_db$query_columns("SampleUnits", c("grts_address")) %>%
    distinct(),
    by = join_by(grts_address)
  )

glimpse(landinfo)


get_update_row_string_landuse <- function(landinfo_rownr){

  grts <- landinfo[landinfo_rownr, "grts_address"]
  info <- landinfo[landinfo_rownr, "landuse"]
  if (is.na(info)) {
    info <- "NULL"
  }

  info <- glue::glue("'{info}'")

  target_namestring <- '"outbound"."LocationInfos"'
  update_string <- glue::glue("
    UPDATE {target_namestring}
      SET landowner = {info}
    WHERE grts_address = {grts}
    ;
  ")

  return(update_string)
}

# concatenate update rows
update_command <- lapply(
  1:nrow(landinfo),
  FUN = get_update_row_string_landuse
)

# spin up a progress bar
pb <- txtProgressBar(
  min = 0, max = nrow(landinfo),
  initial = 0, style = 1
)

# execute the update commands.
for (landinfo_rownr in seq_len(nrow(landinfo))) {
  setTxtProgressBar(pb, landinfo_rownr)
  loceval_db$execute_sql(update_command[[landinfo_rownr]], verbose = FALSE)
}

close(pb) # close the progress bar


landuse_reload <- loceval_db$query_columns(
  "FieldActivityCalendar",
  c("grts_address", "landowner")
  ) %>%
  distinct()
landuse_reload %>% write.csv("dumps/LocationInfos.csv")

# TODO some have an empty string, find source.


## ----done--time-for-some-checks!-------------------------------------------------

### check upload

samuns <- loceval_db$query_table(table_label = "SampleUnits")

locs <- loceval_db$query_table(table_label = "Locations")

locs %>% anti_join(
  samuns,
  by = join_by(location_id)
  )


locass <- loceval_db$query_table(table_label = "LocationAssessments")

samuns %>% left_join(
    locs,
    by = join_by(location_id),
    relationship = "many-to-many",
    suffix = c("", "_LOC")
  ) %>% left_join(
    locass,
    by = join_by(type, location_id),
    relationship = "many-to-many",
    suffix = c("", "_ASS")
  ) %>%
  count(log_user, assessment_done)

# SELECT DISTINCT assessment_done, cell_disapproved, count(*) FROM "outbound"."LocationAssessments" GROUP BY assessment_done, cell_disapproved;
