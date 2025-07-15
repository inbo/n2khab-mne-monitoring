TODO: SampleUnits -> SampleLocations


## libraries----------------------------------------------------------------
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

library("configr")
library("DBI")
library("RPostgres")

library("mapview")
# mapviewOptions(platform = "mapdeck")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")
if (FALSE) {
  # testing
  working_dbname <- "mnmgwdb_testing"
  connection_profile <- "mnmgwdb-testing"
  dbstructure_folder <- "./mnmgwdb_db_structure"
} else {
  # dev
  working_dbname <- "mnmgwdb_dev"
  connection_profile <- "mnmgwdb-dev"
  dbstructure_folder <- "./mnmgwdb_dev_structure"
}


# you might want to run the following prior to sourcing or rendering this script:
# keyring::key_set("DBPassword", "db_user_password")
# projroot <- find_root(is_rstudio_project)
# working_dbname <- "loceval"
# config_filepath <- file.path("./inbopostgis_server.conf")
# connection_profile <- "loceval"
# dbstructure_folder <- "./loceval_db_structure"

config <- configr::read.config(file = config_filepath)[[connection_profile]]
source("MNMDatabaseToolbox.R")

# Load some custom GRTS functions
# source(file.path(projroot, "R/grts.R"))
# TODO: rebase once PR#5 gets merged
source(
  "/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R"
)

source(
  "/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R"
)


## ----load-sample-rdata--------------------------------------------------------
# Download and load R objects from the POC into global environment
reload <- FALSE
poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
if (reload || !file.exists(poc_rdata_path)) {

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

  # copy the old file
  if (file.exists(poc_rdata_path)) {
    this_date <- format(Sys.time(), "%Y%m%d")
    backup_path <- file.path("./data", glue::glue("objects_panflpan5_{this_date}.bak"))
    file.copy(from = poc_rdata_path, to = backup_path, overwrite = TRUE)
  }

  googledrive::drive_download(
    as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"),
    path = poc_rdata_path,
    overwrite = reload
  )
}

load(poc_rdata_path)

versions_required <- c(versions_required, "habitatmap_2024_v99_interim")
verify_n2khab_data(n2khab_data_checksums_reference, versions_required)


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
  "snip snap >> `orthophoto grts` not found" =
    exists("orthophoto_2025_type_grts")
)

stopifnot(
  "snip snap >> `fieldwork_2025_prioritization_shorter` not found" =
    exists("fieldwork_2025_prioritization_shorter")
)



## ----establish-connection-config----------------------------------------------
db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)

# to query latest data from loceval
loceval_connection <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  password = NA
)


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update

update_cascade_lookup <- parametrize_cascaded_update(
  config_filepath,
  working_dbname,
  connection_profile,
  dbstructure_folder,
  db_connection
)



#_______________________________________________________________________________
####   Metadata   ##############################################################

## ----upload-teammembers-------------------------------------------------------
members <- read_csv(
  here::here(dbstructure_folder, "data_TeamMembers.csv"),
  show_col_types = FALSE
)
# %>% filter(username != "Yglinga")
# Testing:
#    DELETE FROM "metadata"."TeamMembers" WHERE username LIKE 'all%';

member_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "TeamMembers",
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
  schema = "metadata",
  table_key = "Protocols",
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


# tag activities for groundwater monitoring
grouped_activities <- grouped_activities %>%
  mutate(is_gw_activity =
    activity %in% c(
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
      )
  )


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
  schema = "metadata",
  table_key = "GroupedActivities",
  new_data = grouped_activities_upload,
  index_columns = c("grouped_activity_id"),
  characteristic_columns = c("activity_group", "activity"),
  tabula_rasa = TRUE,
  verbose = TRUE
)



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
n2khab_strata_upload %>%
  select(type, main_type, stratum) %>%
  knitr::kable()


n2khabstrata_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "N2kHabStrata",
  new_data = n2khab_strata_upload,
  index_columns = c("n2khabstratum_id"),
  characteristic_columns = c("stratum"),
  verbose = TRUE
)



## ----collect-location-assessments----------------------------------------------
# load previous in preatorio work from another database

if (FALSE) {
  migrating_schema <- "outbound"
  migrating_table_key <- "LocationEvaluations"
  migrating_table <- DBI::Id(
    schema = migrating_schema,
    table = migrating_table_key
    )

  locationassessments_data <- dplyr::tbl(
      loceval_connection,
      migrating_table
    ) %>%
    collect() # collecting is necessary to modify offline and to re-upload
}

# before we upload, we need to collect all locations


## ----collect-sample-locations----------------------------------------------
# glimpse(fag_stratum_grts_calendar)

# // from "snippets":
# fag_stratum_grts_calendar defines the needed visits of the spatial sampling
# units and is organized at the FAG level. The rank is an indication of the
# needed order of different FAGs at one location, in the same cycle. In some
# cases repetitions do happen for certain FAGs in a scheme, not all FAGs, as
# prescribed by the date interval.

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
  # convert_stratum_to_type() %>%
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
        stratum
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


## ----save-previous-extra-visits----------------------------------------------
# analogous: clean Visits
table_str <- '"inbound"."Visits"'
maintenance_users <- sprintf("'{update,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
      AND (teammember_id IS NULL)
      AND (date_visit IS NULL)
      AND (notes IS NULL)
      AND (photo IS NULL)
      AND (lims_code IS NULL)
      AND (NOT visit_cancelled)
     AND NOT visit_done;"
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

table_str <- '"outbound"."FieldActivityCalendar"'
maintenance_users <- sprintf("'{update,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
     AND (NOT excluded)
     AND (NOT inaccessible)
     AND (teammember_assigned IS NULL)
     AND (date_visit_planned IS NULL)
     AND (NOT no_visit_planned)
     AND (watina_code IS NULL)
     AND (notes IS NULL)
     AND (NOT done_planning)
   ;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_calendar_plans <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "outbound", table = "FieldActivityCalendar"),
  ) %>% collect()





## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - locationassessments_data
#    - sample_units
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_units

locations <- c(
    sample_units %>% pull(grts_address) %>% as.integer(),
    previous_visits %>% pull(grts_address) %>% as.integer(),
    previous_calendar_plans %>% pull(grts_address) %>% as.integer()
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


slocs_refcols <- c(
  "stratum",
  "grts_address",
  "scheme",
  "panel_set",
  "targetpanel"
  # "sp_poststratum"
)

# tabula rasa: might otherwise be duplicated due to missing fk and null constraint
sample_units_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "SampleUnits",
  new_data = sample_units,
  index_columns = c("sampleunit_id"),
  characteristic_columns = slocs_refcols,
  tabula_rasa = TRUE,
  verbose = TRUE
)


# restore location_id's
# restore_location_id_by_grts(
#   db_connection,
#   dbstructure_folder,
#   target_schema = "outbound",
#   table_key = "SampleUnits",
#   retain_log = FALSE,
#   verbose = TRUE
# )


# sample_units_lookup %>% nrow()
# sample_units_lookup %>%
#   select(!!!slocs_refcols) %>%
#   distinct %>%
#   nrow()


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


# prioritization of fieldwork 2025 with stratum collapsed
# (preferred for planning of non-biotic FAGs)
fieldwork_calendar <-
  fieldwork_2025_prioritization_shorter %>%
  rename_grts_address_final_to_grts_address() %>%
  relocate(grts_address) %>%
  left_join(
    sample_units_lookup %>%
      select(grts_address, location_id),
    by = join_by(stratum, grts_address),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  ) %>%
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
        date_interval
      ),
      as.character
    )
  ) %>%
  mutate(
    log_user = "update",
    log_update = as.POSIXct(Sys.time()),
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  )

# fieldwork_calendar %>% glimpse

fieldwork_calendar_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "FieldActivityCalendar",
  new_data = fieldwork_calendar,
  index_columns = c("fieldactivitycalendar_id"),
  characteristic_columns = NULL,
  tabula_rasa = FALSE,
  verbose = TRUE
)


## ----upload-calendar----------------------------------------------


fieldwork_calendar <-
  fag_stratum_grts_calendar %>%
  common_current_calenderfilters() %>%
  select(
    scheme_moco_ps,
    stratum,
    grts_address,
    starts_with("date"),
    field_activity_group,
    rank
  ) %>%
  # move the fieldwork that was kept for 2024, to 2025, since that is indeed
  # its meaning
  mutate(
    across(c(date_start, date_end), \(x) {
      if_else(year(date_start) == 2024, x + years(1), x)
    }),
    date_interval = interval(
      force_tz(date_start, "Europe/Brussels"),
      force_tz(date_end, "Europe/Brussels")
    )
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
  relocate(grts_address_final, .after = grts_address) %>%
  # also join the spatial poststratum, since we need this in setting
  # GRTS-address based priorities
  inner_join(
    scheme_moco_ps_stratum_sppost_spsamples %>%
      unnest(sp_poststr_samples) %>%
      select(-sample_status),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one"
  ) %>%
  select(-module_combo_code) %>%
  common_current_samplefilters() %>%
  nest_scheme_ps_targetpanel() %>%
  prioritize_and_arrange_fieldwork() %>%
  # convert_stratum_to_type() %>%
  rename_grts_address_final_to_grts_address() %>%
  left_join(
    grouped_activities_lookup %>%
      select(activity_group, activity_group_id) %>%
      distinct()
    ,
    by = join_by(field_activity_group == activity_group),
    relationship = "many-to-many"
  ) %>%
  select(-field_activity_group) %>%
  rename(activity_rank = rank) %>%
  relocate(activity_rank, .after = activity_group_id) %>%
  left_join(
    sample_units_lookup,
    by = slocs_refcols,
    relationship = "many-to-one"
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  select(
    -grts_address,
    -type,
    -scheme_ps_targetpanels,
    -scheme,
    -panel_set,
    -sp_poststratum,
    -date_interval,
    -grts_join_method,
    -targetpanel
  )

# glimpse(fieldwork_calendar)

fac_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "outbound", table = "FieldActivityCalendar"),
  fieldwork_calendar,
  ref_cols = c("samplelocation_id", "activity_group_id", "date_start"),
  index_col = "fieldactivitycalendar_id"
)



locationassessments_upload <- locationassessments_data %>%
  select(-location_id) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  )

# Location Assessments: re-link locations
rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "outbound"."LocationAssessments";'
  )

# re-upload
sf::dbWriteTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  locationassessments_upload,
  row.names = FALSE,
  overwrite = FALSE,
  append = TRUE,
  factorsAsCharacter = TRUE,
  binary = TRUE
  )


## TODO POC update?
## TODO Visits from Calendar
