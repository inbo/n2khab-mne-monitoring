## libraries -------------------------------------------------------------------
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")

## database connection ---------------------------------------------------------
config_filepath <- file.path("./mnm_database_connection.conf")

suffix <- "-staging"
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
  database = glue::glue("loceval{suffix}"),
  user = "monkey",
  password = NA
)


# to also query latest data from mnmsyncdb
mnmsyncdb_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("mnmsyncdb{suffix}"),
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

## Versions --------------------------------------------------------------------

if (nrow(mnmsurfdb$query_table("Versions")) == 0) {

  version_tag <- "mnmsurfdb initialization"
  version_notes <- "REP + snippets v0.16"
  version_date_applied <- as.integer(format(Sys.time(), "%Y%m%d"))
  # version_date_fixing <- as.Date("2025-12-31")

  version_id <- mnmsurfdb$tag_new_version(
    new_version_tag = version_tag,
    new_version_notes =  version_notes,
    new_date_applied = version_date_applied
    # new_date_fixing = version_date_fixing
  )

}

## upload teammembers ----------------------------------------------------------
members <- read_csv(
  here::here(mnmsurfdb$folder, "data_TeamMembers.csv"),
  show_col_types = FALSE
)

mnmsurfdb$insert_data(
  table_label = "TeamMembers",
  upload_data = members %>% select(-starts_with("INSERT INTO"))
)

member_lookup <- mnmsurfdb$query_table("TeamMembers")

## upload protocols ------------------------------------------------------------
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
  filter(!(activity %in% c("SURFLENTSECC", "SURFLOTSECC"))) %>%
  distinct(activity_group, activity)

grouped_activities <- activities %>%
  filter(!(activity %in% c("SURFLENTSECC", "SURFLOTSECC"))) %>%
  left_join(
    activity_group_lookup,
    join_by(activity),
    relationship = "one-to-many"
  )

# grouped_activities %>% distinct(activity) %>% knitr::kable()
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

# tag activities for the different monitoring taskforces
source(here::here(
  "metadata",
  "associate_grouped_activities_with_fieldtaskforces.R"
))

grouped_activities %<>% associate_grouped_activities_with_fieldtaskforces()

# grouped_activities %>%
#   count(is_loceval_activity, is_gw_activity, is_surf_activity)


## upload grouped activities ---------------------------------------------------

# protocol_latest <- protocol_lookup %>%
#   arrange(protocol_version) %>%
#   group_by(protocol_code) %>%
#   dplyr::slice_max(as.numeric(as.factor(protocol_version)))
# grouped_activities %>% distinct(protocol)

# to find the correct fag auxiliary/preponable flags, it is efficient to
# just copy over info from `loceval`.
# This stems from `loceval`, except for `protocol_id`.
protocol_refs <- loceval_connection$query_table("GroupedActivities") %>%
  filter_out(is.na(protocol_id)) %>%
  distinct(activity_group, protocol_id) %>%
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


# protocol info and fag attributes are joined
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


## upload n2khabtype -----------------------------------------------------------
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


#_______________________________________________________________________________
####   Calendar   ##############################################################

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

sample_units <- fag_stratum_grts_calendar_shortterm_attribs %>%
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
# test_units <- sample_units %>%
#   filter(grts_address == 19205238)
# test_units %>% glimpse
# test_units %>%
#   distinct(schemes, scheme_ps_targetpanels)

# need to unwrap and re-wrap scheme_ps_targetpanels

sample_units_upload <- sample_units %>%
  mutate(
    scheme_ps_targetpanels = stringr::str_split(scheme_ps_targetpanels, "\\|")
  ) %>%
  select(-schemes) %>%
  unnest(scheme_ps_targetpanels) %>%
  mutate(
    scheme_ps_targetpanels = stringr::str_trim(scheme_ps_targetpanels, side = "both")
  ) %>%
  tidyr::separate_wider_delim(
    scheme_ps_targetpanels,
    delim = ":",
    names = c("schemes", "ps_targetpanels"),
    cols_remove = FALSE
  ) %>%
  select(-ps_targetpanels) %>%
  group_by(across(c(-schemes, -scheme_ps_targetpanels))) %>%
  summarize(
    schemes = paste0(sort(unique(schemes)), collapse = "|"),
    scheme_ps_targetpanels = paste0(sort(unique(scheme_ps_targetpanels)), collapse = " | "),
    .groups = "drop_last"
  ) %>%
  ungroup() %>%
  rename(
    scheme_ps_targetpanels_served = scheme_ps_targetpanels
  ) %>%
  arrange(grts_address, stratum, schemes)



sampleunit_characols <- c("grts_address", "stratum")
sample_units_upload %>%
  count(!!!rlang::syms(sampleunit_characols)) %>%
  arrange(desc(n)) %>%
  filter(n>1)

sampleunits_lookup <- update_cascade_lookup(
  table_label = "SampleUnits",
  new_data = sample_units_upload,
  index_columns = c("sampleunit_id"),
  characteristic_columns = sampleunit_characols,
  verbose = TRUE
)


## Field Calendar --------------------------------------------------------------

# all technical fields, plus non-null user entry
fieldcalendar_columns <- c(
  "sampleunit_id",
  "grts_address",
  "stratum",
  "activity_group_id",
  "date_start",
  "date_end",
  "date_interval",
  "activity_rank",
  "priority",
  "wait_any",
  "wait_watersurface",
  "wait_3260",
  "wait_7220",
  "wait_floating",
  "wait_obsolete_types",
  "is_sideloaded",
  "is_frozen",
  "excluded",
  "no_visit_planned",
  "done_planning"
)

fieldcalendar_characols <- c(
  "grts_address",
  "stratum",
  "activity_group_id",
  "date_start"
)

activity_groupid_lookup <- mnmsurfdb$query_columns(
    "GroupedActivities",
    c("activity_group", "activity_group_id")
  ) %>%
  distinct()


fieldcalendar_upload <- fieldwork_shortterm_prioritization_by_stratum %>%
  rename_grts_address_final_to_grts_address() %>%
  apply_local_replacement_to_grts() %>%
  inner_join(
    sampleunits_lookup,
    by = join_by(grts_address, stratum),
    relationship = "many-to-one"
  ) %>%
  relocate(grts_address, stratum, sampleunit_id) %>%
  rename(
    activity_rank = rank,
    activity_group = field_activity_group
  ) %>%
  semi_join(
    grouped_activities_upload %>%
      filter(is_surf_activity, is_field_activity),
    by = join_by(activity_group)
  ) %>%
  left_join(
    activity_groupid_lookup,
    by = join_by(activity_group),
    relationship = "many-to-one"
  ) %>%
  select(-activity_group) %>%
  mutate(
    across(c(
        stratum,
        grts_join_method,
        domain_part,
        date_interval
      ),
      as.character
    )
  ) %>%
  mutate(
    is_frozen = FALSE,
    is_sideloaded = FALSE,
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  ) %>%
  distinct(!!!rlang::syms(fieldcalendar_columns)) %>%
  arrange(!!!rlang::syms(fieldcalendar_characols))

# fieldwork_shortterm_prioritization_by_stratum %>%
#   filter(
#     grts_address_final == 1675858,
#     stratum == "3110_1_5",
#     date_start == as.Date("2026-07-01")
#   )


# fieldcalendar_upload %>%
#   count(!!!rlang::syms(fieldcalendar_characols)) %>%
#   filter(n>1) %>%
#   arrange(desc(n))
# fieldcalendar_upload %>%
#   filter(
#     grts_address %in% c(1675858), # , 22021842
#     stratum %in% c("3110_1_5"), # "3110_0_1"
#     activity_group_id %in% c(15, 16),
#     date_start %in% (as.Date("2026-07-01")) #
#   ) %>%
#   knitr::kable()


## Freeze
# fieldcalendar_retained <- mnmsurfdb_freeze %>%
#   select(!!!rlang::syms(c(fieldcalendar_columns, "done_planning"))) %>%
#   anti_join(
#     fieldcalendar_upload,
#     by = join_by(!!!rlang::syms(fieldcalendar_characols))
#   ) %>%
#   select(-is_frozen) %>% mutate(is_frozen = TRUE) %>%
#   left_join(
#     gw_field_activities_db %>%
#       distinct(activity_group) %>%
#       left_join(activity_groupid_lookup, by = join_by(activity_group)) %>%
#       select(activity_group_id) %>%
#       mutate(is_gw_activity = TRUE),
#     by = join_by(activity_group_id)
#   ) %>%
#   filter(done_planning | is_gw_activity) %>%
#   select(-done_planning, -is_gw_activity)

fieldcalendar_new <- bind_rows(
    # fieldcalendar_retained,
    fieldcalendar_upload
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = convert_timestamp_to_ms_character(Sys.time())
  )

stitch_table_connection(
  mnmdb = mnmsurfdb,
  table_label = "FieldCalendar",
  reference_table = "SampleUnits",
  link_key_column = "sampleunit_id",
  lookup_columns = c("grts_address", "stratum")
)

# # sideloading: extra activities e.g. to follow up issues in the field
# calendar_to_sideload <- load_table_sideload_content(
#     mnmdb = mnmsurfdb,
#     table_label = "FieldCalendar",
#     characteristic_columns = fieldcalendar_characols,
#     data_filepath = "sideload/mnmsurfdb_calendars.csv",
#     reload_previous = TRUE
#   ) %>%
#   inner_join(
#     sampleunits_lookup,
#     by = join_by(grts_address, stratum),
#     relationship = "many-to-many", # TODO
#     unmatched = "drop"
#   ) %>%
#   mutate(
#     log_user = "maintenance",
#     log_update = convert_timestamp_to_ms_character(Sys.time()),
#     is_sideloaded = TRUE,
#     excluded = FALSE,
#     no_visit_planned = FALSE,
#     done_planning = FALSE
#   )

fieldcalendar_new <- bind_rows(
    # calendar_to_sideload,
    fieldcalendar_new
  )

# TODO link dates? No, not here -> this script is just an initializer


# There be duplicates. What a great start for a database.
fieldcalendar_new %>%
  count(!!!rlang::syms(fieldcalendar_characols)) %>%
  filter(n > 1) %>%
  arrange(desc(n))

fieldcalendar_new %<>%
  mutate(priority = coalesce(priority, 0))


fieldcalendar_lookup <- update_cascade_lookup(
  table_label = "FieldCalendar",
  new_data = fieldcalendar_new,
  index_columns = c("fieldcalendar_id"),
  characteristic_columns = fieldcalendar_characols,
  verbose = TRUE
)


## Visits ----------------------------------------------------------------------


visits_characols <- fieldcalendar_characols

potential_visits <- fieldcalendar_lookup %>%
  select(
    !!!rlang::syms(c("fieldcalendar_id", visits_characols))
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address)
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = convert_timestamp_to_ms_character(Sys.time()),
    issues = FALSE,
    visit_done = FALSE
  )


visits_upload <- potential_visits %>%
  anti_join(
    mnmsurfdb$query_table("Visits"),
    by = join_by(!!!visits_characols)
  ) %>%
  left_join(
    sampleunits_lookup,#  %>% select(-location_id),
    by = join_by(grts_address, stratum)
  )


surf_field_activities <- grouped_activities %>%
  filter(is_surf_activity, is_field_activity) %>%
  distinct(activity_group_id, activity_group)



# Loop Special Activities
selection_of_activities <- list(
  "LenticVisits" = activity_groupid_lookup %>%
    filter(
      grepl("^SURFLENT", activity_group),
      !grepl("SAMPLPOINT", activity_group)
    ) %>%
    pull(activity_group_id) %>% unique, # /LENTIC
  "LoticVisits" = activity_groupid_lookup %>%
    filter(
      grepl("^SURFLOT", activity_group),
      !grepl("SAMPLPOINT", activity_group)
    ) %>%
    pull(activity_group_id) %>% unique # /LOTIC
)

append_defaults <- list(
  # "InstallationVisits" = function(df) df %>%
  #   mutate(
  #     no_diver = FALSE,
  #     soilprofile_unclear = FALSE
  #   ) # /WIA
)



# Note: "special" Visits must be distributed to the respective tables.
# These tables inherit columns from `Visits`, adding extra ones.

remaining_new_visits <- visits_upload

# table_label <- "LenticVisits"
for (table_label in names(selection_of_activities)) {

  # subset the data by using selection_of_activities -> activity_group_id's
  select_activities <- selection_of_activities[[table_label]]
  special_visits <- remaining_new_visits %>%
    filter(activity_group_id %in% select_activities)

  # extra columns
  if (table_label %in% names(append_defaults)) {
    special_visits <- append_defaults[[table_label]](special_visits)
  }

  # append=upload data to the activity table
  # double-check existing to avoid dups
  # existing <- mnmsurfdb$query_table(table_label)
  sa_lookup <- upload_and_lookup(
    mnmsurfdb,
    table_label = table_label,
    data_to_append = special_visits,
    characteristic_columns = visits_characols,
    index_columns = c("visit_id"),
    verbose = TRUE
  )

  # anti-join remaining_new_visits
  remaining_new_visits <- remaining_new_visits %>%
    anti_join(
      special_visits,
      by = join_by(
        fieldcalendar_id,
        grts_address,
        stratum,
        activity_group_id,
        date_start
      )
    )

}


# remaining visits: the default fallback
other_visits_lookup <- upload_and_lookup(
  mnmsurfdb,
  table_label = "OtherVisits",
  data_to_append = remaining_new_visits,
  characteristic_columns = visits_characols,
  index_columns = c("visit_id"),
  verbose = TRUE
)



mnmsurfdb$query_table("Visits") %>%
  count(
    is.na(location_id),
    is.na(sampleunit_id),
    is.na(fieldcalendar_id)
  ) %>%
  knitr::kable()

# (all `archive_version_id`s should be zero at this point;
#  no archive sync necessary)


#_______________________________________________________________________________
####   Auxiliaries   ###########################################################

## landuse ---------------------------------------------------------------------

# TODO check if new locations arise due to surfdb
update_landuse_in_locationinfos(mnmsurfdb)


## LocationInfos ---------------------------------------------------------------

locationinfos_reference <- mnmsyncdb_connection$query_table("LocationInfos") %>%
  select(tidyselect::any_of(
    mnmsurfdb$load_table_info("LocationInfos") %>% pull(column)
  )) %>%
  select(-locationinfo_id)


new_locinfos <- sample_units %>%
  distinct(
    grts_address
  ) %>%
  mutate(
    log_creator = "maintenance",
    log_creation = convert_timestamp_to_ms_character(Sys.time()),
    log_user = "maintenance",
    log_update = convert_timestamp_to_ms_character(Sys.time())
  ) %>%
  anti_join(
    locationinfos_reference,
    by = join_by(grts_address)
  )


new_locinfos <- bind_rows(
    locationinfos_reference,
    new_locinfos
  ) %>%
  anti_join(
    mnmsurfdb$query_table("LocationInfos"),
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


## location journals -----------------------------------------------------------
lojo_characols <- c(
  "grts_address",
  "date",
  "source",
  "type_subset",
  "activity_group_id"
)

locationjournal_reference <- mnmsyncdb_connection$query_table("LocationJournals") %>%
  select(tidyselect::any_of(
    mnmsurfdb$load_table_info("LocationJournals") %>% pull(column)
  )) %>%
  select(-locationjournal_id)# , -location_id)

locationjournal_reference %>%
  count(!!!rlang::syms(lojo_characols)) %>%
  filter(n > 1) %>%
  knitr::kable()

locationjournal_lookup <- update_cascade_lookup(
  table_label = "LocationJournals",
  new_data = locationjournal_reference,
  index_columns = c("locationjournal_id"),
  characteristic_columns = lojo_characols,
  tabula_rasa = FALSE,
  verbose = TRUE
)

## FreeFieldNotes --------------------------------------------------------------

out <- processx::run(
  "Rscript",
  c("110_sync_FreeFieldNotes.R", suffix),
  spinner = TRUE,
  echo = TRUE
)



## Done! -----------------------------------------------------------------------
message("")
message("________________________________________________________________")
message(" >>>>> Finished SURFDB data upload. ")
message("________________________________________________________________")

# In other scripts:
# - [x] LocationEvaluations
# - [x] CellMaps, TargetPoints
# - [x] ReplacementData
# - [X] Coordinates
# - [X] MHQAreas
#
# Not Relevant (yet):
# - InstallationRemovals -> deleted
# - FieldFollowUps -> retained


# TODO check if new landuse locations arise due to surfdb
