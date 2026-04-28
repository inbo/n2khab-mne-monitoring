
## libraries -------------------------------------------------------------------
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")

## database connection ---------------------------------------------------------
config_filepath <- file.path("./mnm_database_connection.conf")

suffix <- "-dev"
mnmsurfdb_mirror <- glue::glue("mnmsurfdb{suffix}")

mnmsurfdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsurfdb_mirror
)

message(glue::glue("connected: psql {mnmsurfdb$shellstring}"))
update_cascade_lookup <- parametrize_cascaded_update(mnmsurfdb)


# to also query latest data from loceval
loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)


## load REP data ---------------------------------------------------------------

tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()

snippet_base_path <<- rprojroot::find_root(rprojroot::is_git_root)
# # TEMPORARY adjustment pointing to adjacent branch (wip)
# snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))

fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
reload_rep_code_snippets(fresh_snippet_path)
message(glue::glue("Good morning!
  Loading the REP data and snippets took {tic(toc)} seconds today."
))

verify_rep_objects()

if (nrow(different_checksums) > 0) {
  knitr::kable(different_checksums)
}


#_______________________________________________________________________________
####   Metadata   ##############################################################

## ----upload-teammembers-------------------------------------------------------
members <- read_csv(
  here::here(mnmsurfdb$folder, "data_TeamMembers.csv"),
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
protocols <- read_csv(
  here::here(mnmsurfdb$folder, "data_Protocols.csv"),
  show_col_types = FALSE
)

protocol_lookup <- update_cascade_lookup(
  table_label = "Protocols",
  new_data = protocols,
  index_columns = c("protocol_id"),
  characteristic_columns = c("protocol_code", "protocol_version"),
  verbose = TRUE
)



## ----prepare-activities-------------------------------------------------------
# # there are some activities with different ranks within a sequence.
# activity_groupcount <- activity_sequences %>%
#   distinct(activity, activity_group, rank) %>%
#   count(activity, activity_group) %>%
#   arrange(desc(n))

activity_group_lookup <- activity_sequences %>%
  distinct(activity_group, activity)

grouped_activities <- activities %>%
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
# grouped_activities %>% distinct(activity_group) %>% knitr::kable()

# SELECT DISTINCT activity_group FROM "metadata"."GroupedActivities" WHERE is_gw_activity;

# tag activities for groundwater monitoring
grouped_activities <- grouped_activities %>%
  mutate(
    is_loceval_activity = activity_group %in% c(
      "LOCEVALAQ",
      "LOCEVALTERR",
      "LSVIAQ",
      "LSVITERR",
      "SURFLENTLOCEVALSAMPLPOINT",
      "SURFLOTLOCEVALSAMPLPOINT"
    ),
    is_gw_activity = activity_group %in% c(
      "GWINSTWELLDIVER",
      "GWINSTPIEZNODIVER",
      "GWINSTPIEZWELL",
      "GWINSTWELLDIVERDEEP",
      "GWLEVREADDIVER",
      "GWLEVREADDIVERMAN",
      "GWLEVREADDIVERDEEP",
      "GWSHALLCLEAN",
      "GWSHALLSAMP",
      "GWSHALLSAMPREADMAN",
      "GWSURFLEVREADDIVERMAN",
      "GWSURFSHALLSAMPREADMAN",
      "SPATPOSITPIPE",
      "SPATPOSITGAUGE",
      "ADHOCDIVERREPLACE",
      "ADHOCPIPEREPLACE"
    ),
    is_surf_activity = activity_group %in% c(
      "ADHOCDIVERREPLACE",
      "ADHOCPIPEREPLACE",
      "GWSURFINSTALLMAT",
      "GWSURFLEVREADDIVERMAN",
      "GWSURFSHALLSAMPREADMAN",
      "SPATPOSITGAUGE",
      "SPATPOSITPIPE",
      "SURFADHOCGAUGEREPLACE",
      "SURFINSTGAUGE",
      "SURFINSTWELLDIVER",
      "SURFLENTDATACOLL",
        "SURFLENTLOCEVALSAMPLPOINT",
      "SURFLEVREADDIVER",
      "SURFLOTDATACOLL",
        "SURFLOTLOCEVALSAMPLPOINT"
    )
  )



## ----upload-grouped-activities------------------------------------------------

# protocol_latest <- protocol_lookup %>%
#   arrange(protocol_version) %>%
#   group_by(protocol_code) %>%
#   dplyr::slice_max(as.numeric(as.factor(protocol_version)))
# grouped_activities %>% distinct(protocol)


protocol_refs <- loceval_connection$query_table("GroupedActivities") %>%
  filter(!is.na(protocol_id)) %>%
  distinct(activity_group, protocol_id, fag_is_auxiliary, fag_is_preponable) %>%
  left_join(
    loceval_connection$query_columns(
      "Protocols",
      c("protocol_id", "protocol_code", "protocol_version"),
    ),
    by = join_by(protocol_id),
    relationship = "many-to-one"
  ) %>%
  select(-protocol_id) %>%
  left_join(
    protocol_lookup,
    by = join_by(protocol_code, protocol_version)
  ) %>%
  select(activity_group, protocol_id)

grouped_activities_upload <- grouped_activities %>%
  left_join(
    protocol_refs,
    by = join_by(activity_group),
    relationship = "many-to-one"
  ) %>%
  left_join(
    loceval_connection$query_columns(
      "GroupedActivities",
      c("activity_group", "activity", "fag_is_auxiliary", "fag_is_preponable"),
    ),
    by = join_by(activity_group, activity),
    relationship = "many-to-one"
  ) %>%
  select(-protocol)


# upload grouped activities
grouped_activity_lookup <- update_cascade_lookup(
  table_label = "GroupedActivities",
  new_data = grouped_activities_upload,
  index_columns = c("grouped_activity_id"),
  characteristic_columns = c("activity_group", "activity"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


# grouped_activities_upload %>% write.csv("dumps/grouped_activities.csv")
surf_field_activities <- grouped_activities_upload %>%
  filter(is_surf_activity) %>%
  distinct(activity_group, activity, fag_is_auxiliary, fag_is_preponable)


## ----upload-n2khabtype--------------------------------------------------------
## n2khab type to stratum (below)

n2khab_strata_upload <- n2khab_types_expanded_properties %>%
  inner_join(
    n2khab_strata,
    by = join_by(type),
    relationship = "many-to-many",
  ) %>%
  arrange(main_type, type, stratum) %>%
  # extra_types
  bind_rows(
    as_tibble(list(
      type = c("gh"),
      typelevel = c("main_type"),
      main_type = c("gh"),
      stratum = c("gh")
    )), .
  )

# # SELECT DISTINCT type FROM "metadata"."N2kHabStrata";
# n2khab_strata_upload %>%
#   select(type, main_type, stratum) %>%
#   knitr::kable()


n2khabstrata_lookup <- update_cascade_lookup(
  table_label = "N2kHabStrata",
  new_data = n2khab_strata_upload,
  index_columns = c("n2khabstratum_id"),
  characteristic_columns = c("stratum"),
  verbose = TRUE
)



## Replacements ----------------------------------------------------------------

replacement_lookup <- loceval_connection$query_table("gwTransfer") %>%
  grts_datatype_to_integer() %>%
  filter(
    eval_source == "loceval",
    grts_address != grts_address_original
  ) %>%
  distinct(grts_address, type, grts_address_original) %>%
  rename(grts_address_replacement = grts_address) %>%
  rename(grts_address = grts_address_original) %>%
  rename(stratum = type)

apply_local_replacement_to_grts <- function(df, typecolumn = "stratum") {
  lookup <- replacement_lookup %>%
    dplyr::mutate(is_replacement = TRUE)
  names(lookup)[names(lookup) == "stratum"] <- typecolumn

  df %>%
    dplyr::left_join(
      lookup,
      by = dplyr::join_by(!!!c("grts_address", typecolumn))
    ) %>%
    dplyr::mutate(
      grts_address = dplyr::coalesce(grts_address_replacement, grts_address),
      is_replacement = dplyr::coalesce(is_replacement, FALSE)
    ) %>%
    dplyr::select(-grts_address_replacement) %>%
    return()
}


## collect sample locations ----------------------------------------------------

sample_unit_columns <- c(
  "grts_address",
  "stratum",
  "schemes",
  # "schemes_served_all", # -> renamed to schemes
  "scheme_ps_targetpanels",
  "domain_part",
  # "sp_poststratum",
  # "grts_join_method",
  # "is_current_occasion", # TODO
  # "schemes_served_all",
  "is_forest",
  "in_mhq_samples",
  # "mhq_assessment_date",
  "has_mhq_assessment",
  # "previous_notes",
  "is_replacement"
)

sample_units_updated <- fag_stratum_grts_calendar_shortterm_attribs %>%
  rename_grts_address_final_to_grts_address(keep_original = FALSE) %>%
  # only retain the activities for this scheme
  # otherwise there are duplicates (schemes filled differently on LOCEVAL)
  semi_join(
    surf_field_activities,
    by = join_by(field_activity_group == activity_group)
  ) %>%
  rename(
    has_mhq_assessment = last_type_assessment_in_field,
    mhq_assessment_date = last_type_assessment,
    schemes = schemes_served_all
  ) %>%
  relocate(grts_address) %>%
  relocate(grts_join_method, .after = grts_address) %>%
  mutate(
    previous_notes = NA # FUTURE TODO
  ) %>%
  apply_local_replacement_to_grts() %>%
  # extract_and_flatten_scheme_from_scheme_ps_targetpanels() %>% # rather take _all
  distinct(!!!rlang::syms(sample_unit_columns)) %>%
  mutate(across(c(
      scheme_ps_targetpanels,
      stratum,
      domain_part
    ), as.character)
  )

# sample_units_updated %>%
#   distinct(scheme_ps_targetpanels) %>%
#   print(n=Inf)


# FREEZE: not applicable for novel database
#
# sample_units_retained <- mnmsurfdb_freeze %>%
#   distinct(!!!rlang::syms(sample_unit_columns)) %>%
#   anti_join(
#     sample_units_updated,
#     by = join_by(grts_address, strata)
#   )


sample_units <- bind_rows(
  # sample_units_retained,
  sample_units_updated
)



## Locations -------------------------------------------------------------------

locations_grts_collection <- bind_rows(
    mnmsurfdb$query_columns("Locations", c("grts_address")),
    sample_units %>% distinct(grts_address),
    mnmsurfdb$query_columns("LocationInfos", c("grts_address")),
    loceval_connection$query_columns("LocationInfos", c("grts_address"))
  ) %>%
  mutate(grts_address = as.integer(grts_address)) %>%
  distinct()

# join geometry column
grts_mh <- n2khab::read_GRTSmh()

grts_mh_index <- dplyr::tibble(
    id = seq_len(terra::ncell(grts_mh)),
    grts_address = values(grts_mh)[, 1]
  ) %>%
  dplyr::filter(!is.na(grts_address))

locations <- locations_grts_collection %>%
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
  verbose = TRUE
)


## LocationCells ---------------------------------------------------------------

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

mnmsurfdb$execute_sql(
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

mnmsurfdb$insert_data(
  table_label = "LocationCells",
  upload_data = location_cells
)



extra_cells <- loceval_connection$query_table("ReplacementCells") %>%
  left_join(
    loceval_connection$query_table("Replacements") %>%
      select(-wkb_geometry),
    by = join_by(replacement_id)
  ) %>%
  select(-grts_address) %>%
  rename(grts_address = grts_address_replacement) %>%
  inner_join(
    locations_lookup,
    by = join_by(grts_address)
  ) %>%
  select(location_id, wkb_geometry) %>%
  distinct %>%
  anti_join(
    location_cells,
    by = join_by(location_id)
  )


mnmsurfdb$insert_data(
  table_label = "LocationCells",
  upload_data = extra_cells
)



## SampleUnits -----------------------------------------------------------------

if ("location_id" %in% names(sample_units)) {
  # should not be the case in a continuous script;
  # this is extra safety for debugging and de-serial execution
  sample_units <- sample_units %>%
    select(-location_id)#, -location_id.x, -location_id.y)
}

sample_units <- sample_units %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  distinct()

# locations_lookup %>%
#   filter(grts_address == 19205238)
sample_units %>%
  filter(grts_address == 19205238) %>%
  distinct(schemes, scheme_ps_targetpanels)

# need to unwrap and re-wrap scheme_ps_targetpanels



















stop("continue here")
sampleunit_characols <- c("grts_address", "stratum")
sample_units %>%
  count(!!!rlang::syms(sampleunit_characols)) %>%
  arrange(desc(n))

sampleunit_lookup <- update_cascade_lookup(
  table_label = "SampleUnits",
  new_data = sample_units,
  index_columns = c("sampleunit_id"),
  characteristic_columns = sampleunit_characols,
  verbose = TRUE
)




## save previous location infos ---------------------------------------------
table_str <- '"outbound"."LocationInfos"'
maintenance_users <- sprintf("'{update,maintenance,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE TRUE
      AND log_user = ANY ({maintenance_users}::varchar[])
      AND (accessibility_inaccessible IS NULL OR (NOT accessibility_inaccessible))
      AND (accessibility_revisit IS NULL)
      AND (recovery_hints IS NULL)
      AND (watina_code_1 IS NULL)
      AND (watina_code_2 IS NULL)
  ;" # landowner will be script-updated (outbound)
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_locinfos <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationInfos"),
  ) %>% collect()



## ----save-previous-extra-visits----------------------------------------------
## NOTE IMPORTANT: First, Visits are pruned and the relevant ones remain.
##                 Then, FieldworkCalendar is pruned, and those which are
##                 still linked to visits remain (even if empty).
# analogous: clean Visits
table_str <- '"inbound"."Visits"'
maintenance_users <- sprintf("'{update,maintenance,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
      AND (teammember_id IS NULL)
      AND (date_visit IS NULL)
      AND (notes IS NULL)
      AND (photo IS NULL)
      AND (lims_code IS NULL)
      AND (NOT issues)
      AND (NOT visit_done)
   ;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_visits <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "inbound", table = "Visits"),
  ) %>% collect()



## ----save-previous-FACs----------------------------------------------

table_str <- '"outbound"."FieldworkCalendar"'
table_str_visits <- '"inbound"."Visits"'
maintenance_users <- sprintf("'{update,maintenance,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
     AND (NOT excluded)
     AND (excluded IS NULL)
     AND (teammember_assigned IS NULL)
     AND (date_visit_planned IS NULL)
     AND (NOT no_visit_planned)
     AND (notes IS NULL)
     AND (NOT done_planning)
     AND (fieldworkcalendar_id NOT IN (
       SELECT DISTINCT fieldworkcalendar_id
       FROM {table_str_visits}
     ))
   ;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_calendar_plans <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "outbound", table = "FieldworkCalendar"),
  ) %>%
  left_join(
    dplyr::tbl(db_connection,
      DBI::Id(schema = "metadata", table = "SSPSTaPas")),
    by = join_by(sspstapa_id)
  ) %>%
  relocate(stratum_scheme_ps_targetpanels, .after = sspstapa_id) %>%
  select(-sspstapa_id) %>%
  collect()

# glimpse(previous_calendar_plans)



## ----previous-activities----------------------------------------------
table_str <- '"inbound"."WellInstallationActivities"'
maintenance_users <- sprintf("'{update,maintenance,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE TRUE
      AND log_user = ANY ({maintenance_users}::varchar[])
      AND (teammember_id IS NULL)
      AND (date_visit IS NULL)
      AND (photo_soil_1_peilbuis IS NULL)
      AND (photo_soil_2_piezometer IS NULL)
      AND (photo_well IS NULL)
      AND (watina_code_used_1_peilbuis IS NULL)
      AND (watina_code_used_2_piezometer IS NULL)
      AND (soilprofile_notes IS NULL)
      AND (soilprofile_unclear IS NULL OR (NOT soilprofile_unclear))
      AND (random_point_number IS NULL)
      AND (no_diver IS NULL OR (NOT no_diver))
      AND (diver_id IS NULL)
      AND (free_diver IS NULL)
      AND (NOT visit_done)
  ;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_wellinstallations <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "inbound", table = "WellInstallationActivities"),
  ) %>%
  mutate(grts_address = as.integer(grts_address)) %>%
  collect()


table_str <- '"inbound"."ChemicalSamplingActivities"'
maintenance_users <- sprintf("'{update,maintenance,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE TRUE
      AND log_user = ANY ({maintenance_users}::varchar[])
      AND (teammember_id IS NULL)
      AND (date_visit IS NULL)
      AND (project_code IS NULL)
      AND (recipient_code IS NULL)
      AND (NOT visit_done)
  ;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_chemicalsamplings <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "inbound", table = "ChemicalSamplingActivities"),
  ) %>%
  mutate(grts_address = as.integer(grts_address)) %>%
  collect()



## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - sample_locations
#    - previous visits
#    - previous calendar plans
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_locations

locations <- bind_rows(
    sample_locations %>% select(grts_address),
    previous_calendar_plans %>% select(grts_address),
    previous_visits %>% select(grts_address),
    previous_locinfos %>% select(grts_address)
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


# TODO problem here if there are `Coordinates` left of locations which get deleted
#      experienced 20250822 when working on `mnmsurfdb_staging` after clone and replacement.

locations_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "Locations",
  new_data = locations,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = TRUE,
  verbose = TRUE
)
# locations_lookup %>% write.csv("dumps/lookup_locations.csv")
# locations are nuique.


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

execute_sql(
  db_connection,
  glue::glue('DELETE  FROM "metadata"."LocationCells";'),
  verbose = TRUE
)

append_tabledata(
  db_connection,
  DBI::Id(schema = "metadata", table = "LocationCells"),
  location_cells,
  reference_columns = "location_id"
)



## ----upload-sample-locations----------------------------------------------

if ("location_id" %in% names(sample_locations)) {
  # should not be the case in a continuous script;
  # this is extra safety for debugging and de-serial execution
  sample_locations <- sample_locations %>%
    select(-location_id)
}
sample_locations <- sample_locations %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>% distinct # TODO remove after stratum is in place


# tabula rasa: might otherwise be duplicated due to missing fk and null constraint
samplelocations_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "SampleLocations",
  new_data = sample_locations,
  index_columns = c("samplelocation_id"),
  characteristic_columns = c("grts_address", "location_id"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


# restore location_id's
# restore_location_id_by_grts(
#   db_connection,
#   dbstructure_folder,
#   target_schema = "outbound",
#   table_key = "SampleLocations",
#   retain_log = FALSE,
#   verbose = TRUE
# )


# samplelocations_lookup %>% nrow()
# samplelocations_lookup %>%
#   select(!!!slocs_refcols) %>%
#   distinct %>%
#   nrow()

## ----location-infos-------------------------------------------------

# assemble new assessments
new_locinfos <- sample_locations %>%
  distinct(
    grts_address
  ) %>%
  mutate(
    log_creator = "maintenance",
    log_creation = as.POSIXct(Sys.time()),
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )

# previous_locinfos %>% write.csv("data/20250704_Wards_LocationAssessments.csv")

new_locinfos <- new_locinfos %>%
  anti_join(
    previous_locinfos,
    by = join_by(grts_address)
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
  )

locationinfo_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "LocationInfos",
  new_data = new_locinfos,
  index_columns = c("locationinfo_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)


## ----fieldwork-calendar-------------------------------------------------

# grouped_activities %>% distinct(activity_group, activity_group_id) %>% count(activity_group) %>% print(n=Inf)


activity_groupid_lookup <-
  dplyr::tbl(
    db_connection,
    DBI::Id(schema = "metadata", table = "GroupedActivities"),
  ) %>%
  distinct(activity_group, activity_group_id) %>%
  collect()

# activity_groupid_lookup %>% distinct(activity_group, activity_group_id) %>% count(activity_group) %>% print(n=Inf)


# prioritization of fieldwork shortterm with stratum collapsed
# (preferred for planning of non-biotic FAGs)

# TODO double check with Floris
surf_field_activities <- grouped_activities %>%
  filter(is_surf_activity, is_field_activity) %>%
  distinct(activity_group)

fieldwork_calendar <-
  fieldwork_shortterm_prioritization_shorter %>%
  rename_grts_address_final_to_grts_address() %>%
  relocate(grts_address) %>%
  semi_join(
    samplelocations_lookup,
    by = join_by(grts_address),
  ) %>%
  rename(
    activity_rank = rank,
    activity_group = field_activity_group
  ) %>%
  semi_join(surf_field_activities, by = join_by(activity_group)) %>%
  left_join(
    activity_groupid_lookup,
    by = join_by(activity_group),
    relationship = "many-to-one"
  ) %>%
  select(-activity_group) %>%
  left_join(
    samplelocations_lookup %>% select(grts_address, samplelocation_id),
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  relocate(samplelocation_id) %>%
  mutate(
    across(c(
        date_interval
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
  ) # ?! %>% glimpse

# fieldwork_calendar %>% glimpse


## SSPSTaPas

sspstapas <- update_cascade_lookup(
  schema = "metadata",
  table_key = "SSPSTaPas",
  new_data = fieldwork_calendar %>%
    distinct(stratum_scheme_ps_targetpanels) %>%
    arrange(stratum_scheme_ps_targetpanels),
  index_columns = c("sspstapa_id"),
  tabula_rasa = TRUE,
  verbose = TRUE
)

replace_sspstapa_by_lookup <- function(df) {
  df_new <- df %>%
    left_join(
      sspstapas,
      by = join_by(stratum_scheme_ps_targetpanels),
      relationship = "many-to-one"
    ) %>%
    relocate(
      sspstapa_id,
      .after = stratum_scheme_ps_targetpanels
    ) %>%
    select(-stratum_scheme_ps_targetpanels)

  return(df_new)
}

fieldcalendar_characols <- c(
    "samplelocation_id",
    "sspstapa_id",
    "grts_address",
    "activity_group_id",
    "date_start"
  )

# previous_calendar_test <- fieldwork_calendar[1:500,]
# glimpse(previous_calendar_plans %>% replace_sspstapa_by_lookup())
# TODO had an issue where sspstapas were lost...

fieldwork_calendar_new <- fieldwork_calendar %>%
  replace_sspstapa_by_lookup() %>%
  anti_join(
    previous_calendar_plans %>% replace_sspstapa_by_lookup(),
    by = join_by(!!!fieldcalendar_characols)
  )
## ----upload-calendar----------------------------------------------

fieldwork_calendar_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "FieldworkCalendar",
  new_data = fieldwork_calendar_new,
  index_columns = c("fieldworkcalendar_id"),
  characteristic_columns = fieldcalendar_characols,
  tabula_rasa = FALSE,
  verbose = TRUE
)

# TODO are previous_calendar_plans retained correctly?
# glimpse(fieldwork_calendar_lookup)


new_visits <- fieldwork_calendar_lookup %>%
  select(
    fieldworkcalendar_id,
    !!!fieldcalendar_characols
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address)
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    issues = FALSE,
    visit_done = FALSE
  )

visits_characols <- c("fieldworkcalendar_id", fieldcalendar_characols)

visits_upload <- new_visits %>%
  anti_join(
    previous_visits,
    by = join_by(!!!visits_characols)
  )


visits_lookup <- update_cascade_lookup(
  schema = "inbound",
  table_key = "Visits",
  new_data = visits_upload,
  index_columns = c("visit_id"),
  characteristic_columns = visits_characols,
  tabula_rasa = FALSE,
  verbose = TRUE
)


### TODO GWSHALLSAMP!!!
if (FALSE) {

  grouped_activities  %>%
    filter(is_gw_activity, grepl("^GW.*SAMP", activity_group)) %>%
    select(
      activity_group,
      activity,
      activity_name
    )

  visits_lookup %>%
    distinct(activity_group_id) %>%
    left_join(
      grouped_activities,
      by = join_by(activity_group_id)
    ) %>%
    select(
      activity_group,
      activity,
      activity_name
    )

  fieldwork_shortterm_prioritization_shorter %>%
    distinct(field_activity_group)
}

## (DONE: LocationEvaluations incl. recovery_hints)

## (DONE sync FreeFieldNotes back and forth (extra script))


## TODO POC update?



## ----collect-location-assessments----------------------------------------------
# load previous in preatorio work from another database
# TODO type_assessed -> must be adjusted upstream in the POC; kept now for double-check


# this is slightly more complex: a UNION view form `loceval` database
#      include `photos` and `recovery_hints`
# TODO include MHQ assessments and other prior visits

locationevaluation_input <- dplyr::tbl(
    loceval_connection,
    DBI::Id("outbound", "gwTransfer")
  ) %>%
  select(-grts_address_original) %>%
  collect() # collecting is necessary to modify offline and to re-upload

locationevaluation_input <- locationevaluation_input %>%
  # relocate_grts_replacements(relationship = "many-to-many") %>%
  distinct

# locationevaluation_input %>% count(eval_source)
# locationevaluation_input %>% distinct(eval_name)

# before we upload, we need to collect all locations
locationevaluations_upload <- locationevaluation_input %>%
  left_join(
    samplelocations_lookup %>% select(grts_address, samplelocation_id),
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  relocate(samplelocation_id) %>%
  mutate(
    eval_name = coalesce(eval_name, log_user)
  )

# locationevaluations_upload %>% filter(is.na(eval_name))

locationevaluation_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "LocationEvaluations",
  new_data = locationevaluations_upload,
  index_columns = c("locationevaluation_id"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


## ----land-use-------------------------------------------------


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
    dplyr::tbl(
      db_connection,
      DBI::Id("outbound", "LocationInfos")
    ) %>%
    distinct(grts_address) %>%
    collect,
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
  seq_len(nrow(landinfo)),
  FUN = get_update_row_string_landuse
)

# spin up a progress bar
pb <- txtProgressBar(
  min = 0, max = nrow(landinfo),
  initial = 0, style = 1
)

# execute the update commands.
for (landinfo_rownr in 1:nrow(landinfo)) {
  setTxtProgressBar(pb, landinfo_rownr)
  cmd <- update_command[[landinfo_rownr]]
  execute_sql(db_connection, cmd, verbose = FALSE)
}

close(pb) # close the progress bar


landuse_reload <- dplyr::tbl(
    db_connection,
    DBI::Id("outbound", "LocationInfos")
  ) %>%
  distinct(grts_address, landowner) %>%
  collect
# landuse_reload %>% write.csv("dumps/landuse.csv")


##//////////////////////////////////////////////////////////////////////////////
#< ACTIVITIES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
##\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

visits_reload <- dplyr::tbl(
    db_connection,
    DBI::Id("inbound", "Visits")
  ) %>%
  mutate(grts_address = as.integer(grts_address)) %>%
  select(
    samplelocation_id,
    fieldworkcalendar_id,
    visit_id,
    grts_address,
    activity_group_id,
    date_start
  ) %>%
  collect()


fieldwork_charcols <- c(
    "samplelocation_id",
    "fieldworkcalendar_id",
    "visit_id",
    "grts_address",
    "activity_group_id",
    "date_start"
  )


## ---- WellInstallationActivities ---------------------------------------------

activity_subset <- grouped_activities_upload %>%
  filter(grepl("^GWINST", activity_group))

# visits_linked <- visits_upload %>%
#   left_join(
#     visits_lookup,
#     by = join_by(!!!visits_characols)
#   )

wellinstallations <- visits_reload %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )


# TODO: re-download previous_wellinstallations?
#       -> check whether duplicates appear due to failed anti-join after id renewal elsewhere

wellinstallations_upload <- wellinstallations %>%
  anti_join(
    previous_wellinstallations,
    by = join_by(!!!fieldwork_charcols)
  ) %>%
  mutate(
    no_diver = FALSE,
    soilprofile_unclear = FALSE,
    visit_done = FALSE,
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )

wellinstallation_lookup <- update_cascade_lookup(
  schema = "inbound",
  table_key = "WellInstallationActivities",
  new_data = wellinstallations_upload,
  index_columns = c("fieldwork_id"),
  characteristic_columns = fieldwork_charcols,
  skip_sequence_reset = TRUE,
  verbose = TRUE
)


## ---- ChemicalSamplingActivities ---------------------------------------------

activity_subset <- grouped_activities_upload %>%
  filter(activity_group %in%
    c(grouped_activities_upload %>%
      filter(grepl("^GW.*SAMP", activity)) %>%
      pull(activity_group))
  )

chemicalsamplings <- visits_reload %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )

chemicalsampling_upload <- chemicalsamplings %>%
  anti_join(
    previous_chemicalsamplings,
    by = join_by(!!!fieldwork_charcols)
  ) %>%
  mutate(
    visit_done = FALSE,
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )

chemicalsampling_lookup <- update_cascade_lookup(
  schema = "inbound",
  table_key = "ChemicalSamplingActivities",
  new_data = chemicalsampling_upload,
  index_columns = c("fieldwork_id"),
  characteristic_columns = fieldwork_charcols,
  skip_sequence_reset = TRUE,
  verbose = TRUE
)



## ----done!----------------------------------------------
message("________________________________________________________________")
message("All done. Hopefully well.")

# python 210_init_mnmgwdb.py 2>&1 | tee dump1.log
# Rscript 220_upload_mnmgwdb.R 2>&1 | tee dump2.log
# source("220_upload_mnmgwdb.R")

# fw_check <- dplyr::tbl(
#   db_connection,
#   DBI::Id("inbound", "FieldWork")
# ) %>% collect
#
# fw_check %>% mutate(fwid_is_null = is.na(fieldwork_id)) %>% count(activity_group_id, fwid_is_null)
