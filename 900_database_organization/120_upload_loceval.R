## ----libraries----------------------------------------------------------------
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
library("rprojroot")
library("keyring")

library("configr")
library("DBI")
library("RPostgres")

library("mapview")
# mapviewOptions(platform = "mapdeck")

projroot <- find_root(is_rstudio_project)
working_dbname <- "loceval_dev"
config_filepath <- file.path("./inbopostgis_server.conf")
connection_profile <- "loceval-dev"
dbstructure_folder <- "./loceval_dev_structure"

# you might want to run the following prior to sourcing or rendering this script:
# keyring::key_set("DBPassword", "db_user_password")

source("MNMDatabaseToolbox.R")

# Load some custom GRTS functions
# source(file.path(projroot, "R/grts.R"))
# TODO: rebase once PR#5 gets merged
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")





## ----load-sample-rdata--------------------------------------------------------
# Download and load R objects from the POC into global environment
reload <- FALSE
poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
if (reload || !file.exists(poc_rdata_path)){

  # Setup for googledrive authentication. Set the appropriate env vars in
  # .Renviron and make sure you ran drive_auth() interactively with these settings
  # for the first run (or to renew an expired Oauth token).
  # See ?gargle::gargle_options for more information.
  if (Sys.getenv("GARGLE_OAUTH_EMAIL") != "") {
    options(gargle_oauth_email = Sys.getenv("GARGLE_OAUTH_EMAIL"))
  }
  if (Sys.getenv("GARGLE_OAUTH_CACHE") != "") {
    options(gargle_oauth_cache = Sys.getenv("GARGLE_OAUTH_CACHE"))
  }

  googledrive::drive_download(
    as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"),
    path = poc_rdata_path,
    overwrite = reload
  )
}

load(poc_rdata_path)


## ----check-loading-snippets-----------------------------------

invisible(capture.output(source("050_snippet_selection.R")))
source("051_snippet_transformation_code.R")

stopifnot(
  "NOT FOUND: snip snap >> `grts_mh_index`" = exists("grts_mh_index")
)

stopifnot(
  "NOT FOUND: snip snap >> `scheme_moco_ps_stratum_targetpanel_spsamples`" =
    exists("scheme_moco_ps_stratum_targetpanel_spsamples")
)

stopifnot(
  "NOT FOUND: snip snap >> `stratum_schemepstargetpanel_spsamples`" =
    exists("stratum_schemepstargetpanel_spsamples")
)

stopifnot(
  "NOT FOUND: snip snap >> `units_cell_polygon`" =
    exists("units_cell_polygon")
)

stopifnot(
  "NOT FOUND: RData >> `activities`" =
    exists("activities")
)

stopifnot(
  "NOT FOUND: RData >> `activity_sequences`" =
    exists("activity_sequences")
)

stopifnot(
  "NOT FOUND: RData >> `n2khab_strata`" =
    exists("n2khab_strata")
)

stopifnot(
  "snip snap >> `orthophoto grts` not found" = exists("orthophoto_2025_type_grts")
)

## ----load-config--------------------------------------------------------------
db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)



## ----upload-teammembers-------------------------------------------------------
members <- read_csv(
  here::here(dbstructure_folder, "data_TeamMembers.csv"),
  show_col_types = FALSE
)

member_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "TeamMembers"),
  members,
  ref_cols = "username",
  index_col = "teammember_id"
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

protocol_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "Protocols"),
  protocols,
  ref_cols = "protocol",
  index_col = "protocol_id"
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

# knitr::kable(grouped_activities %>% distinct(activity_group, activity, activity_name))

# glimpse(grouped_activities)


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

db_table <- DBI::Id(schema = "metadata", table = "GroupedActivities")
ga_content <- DBI::dbReadTable(db_connection, db_table)

existing <- ga_content %>%
  select(activity_group, activity, activity_group_id, activity_id)
to_upload <- grouped_activities_upload %>%
  anti_join(
    existing,
    join_by(activity_group, activity, activity_group_id, activity_id)
)

if (nrow(to_upload) > 0){
  rs <- DBI::dbWriteTable(
    db_connection,
    db_table,
    to_upload,
    overwrite = FALSE,
    append = TRUE
  )
  # DBI::dbClearResult(rs)
}

grouped_activity_lookup <-
  dplyr::tbl(db_connection, db_table) %>%
  select(activity_group, activity, grouped_activity_id, activity_group_id, activity_id) %>%
  collect


## ----upload-n2khabtype--------------------------------------------------------
## n2khab type to stratum (below)

n2khab_types_upload <- bind_rows(
  as_tibble(list(
    type = c("gh"),
    typelevel = c("main_type"),
    main_type = c("gh")
  )),
  n2khab_types_expanded_properties
  )

n2khabtype_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "N2kHabTypes"),
  n2khab_types_upload,
  ref_cols = "type",
  index_col = "n2khabtype_id"
)



# SELECT DISTINCT type FROM "metadata"."N2kHabTypes" ORDER BY type;

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

DBI::dbWriteTable(
  db_connection,
  DBI::Id(schema = "metadata", table = "lut_N2kHabStrata"),
  n2khab_strata_upload,
  overwrite = TRUE
  )




## ----collect-sample-locations----------------------------------------------
# glimpse(fag_stratum_grts_calendar)

sample_locations <-
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

# glimpse(sample_locations)

# still need to join the location, below
# TODO in the future, make sure `type` is
#      correctly filled from LOCEVAL
#      "previous_assessment" -> "assessment"
#      and add previous_notes

## ----save-previous-location-assessments----------------------------------------------
previous_location_assessments <- DBI::dbReadTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  ) %>% collect()
# nrow(previous_location_assessments)


## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - locationassessments_data
#    - sample_locations
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_locations

locations <- c(
    sample_locations %>% pull(grts_address) %>% as.integer(),
    previous_location_assessments %>% pull(grts_address) %>% as.integer()
  ) %>%
  tibble(grts_address = .) %>%
  distinct() %>%
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(locations) <- "wkb_geometry"


# TODO first, delete locations to prevent the `ogc_fid` duplicate error

rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "metadata"."Locations";'
  )

locations_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "Locations"),
  locations,
  ref_cols = "grts_address",
  index_col = "location_id"
)


# **Upload Location Polygons:**

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
  )

# might otherwise be duplicated due to missing fk and null constraint
rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "outbound"."SampleLocations";'
  )

slocs_refcols <- c(
  "type",
  "grts_address",
  "scheme",
  "panel_set",
  "targetpanel"
  # "sp_poststratum"
)
sample_locations_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "outbound", table = "SampleLocations"),
  sample_locations,
  ref_cols = slocs_refcols,
  index_col = "samplelocation_id"
)

# sample_locations_lookup %>% nrow()
# sample_locations_lookup %>%
#   select(!!!slocs_refcols) %>%
#   distinct %>%
#   nrow()


## ----restore-assessments-------------------------------------------------

# orthophoto_prior_data <- dplyr::tbl(
#     db_connection,
#     DBI::Id(schema = "outbound", table = "LocationAssessments")
#   ) %>%
#   collect() # collecting is necessary to modify offline and to re-upload
#
# # orthophoto_upload <-


new_location_assessments <- sample_locations %>%
  select(
    location_id,
    grts_address,
    type
  ) %>%
  mutate(
    log_user = "update",
    log_update = as.POSIXct(Sys.time()),
    cell_disapproved = FALSE,
    assessment_done = FALSE
  )

new_location_assessments <- new_location_assessments %>%
  anti_join(
    previous_location_assessments,
    by = join_by(type, grts_address)
  )

location_assessments <- bind_rows(
  previous_location_assessments,
  new_location_assessments
  ) %>%
  select(-locationassessment_id)
# nrow(location_assessments)


# # append the LocationAssessments with empty lines for new sample units
# append_tabledata(
#   db_connection,
#   DBI::Id(schema = "outbound", table = "LocationAssessments"),
#   location_assessments,
#   reference_columns =
#     c("type", "grts_address")
# )

rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "outbound"."LocationAssessments";'
  )

# re-upload
sf::dbWriteTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  location_assessments,
  row.names = FALSE,
  overwrite = FALSE,
  append = TRUE,
  factorsAsCharacter = TRUE,
  binary = TRUE
  )

# conn <- db_connection
# db_table <- DBI::Id(schema = "outbound", table = "LocationAssessments")
# data_to_append <- new_location_assessments



## ----extra-visits-------------------------------------------------

previous_extra_visits <- DBI::dbReadTable(
  db_connection,
  DBI::Id(schema = "inbound", table = "ExtraVisits"),
  ) %>% collect()

new_extra_visits <- sample_locations_lookup %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  select(samplelocation_id, location_id, grts_address) %>%
  mutate(
    grouped_activity_id = NA,
    teammember_id = NA,
    date_visit = NA,
    log_user = "update",
    log_update = as.POSIXct(Sys.time()),
    visit_done = FALSE
  )

new_extra_visits <- new_extra_visits %>%
  anti_join(
    previous_extra_visits,
    by = join_by(samplelocation_id, grts_address)
  )

extra_visits_upload <- bind_rows(
  previous_extra_visits,
  new_extra_visits
  ) %>%
  select(-extravisit_id)

append_tabledata(
  db_connection,
  DBI::Id(schema = "inbound", table = "ExtraVisits"),
  extra_visits_upload,
  reference_columns = c("grts_address", "grouped_activity_id", "teammember_id", "date_visit")
)
