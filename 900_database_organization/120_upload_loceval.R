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
library("glue")
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

# # you might want to run the following prior to sourcing or rendering this script:
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
  "snip snap >> `orthophoto grts` not found" =
    exists("orthophoto_2025_type_grts")
)

## ----establish-connection-config----------------------------------------------
db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update
update_cascade_lookup <- function(
    schema,
    table_key,
    new_data,
    index_columns,
    tabula_rasa = FALSE,
    characteristic_columns = NULL,
    verbose = TRUE
  ) {

  db_table <- DBI::Id(schema = schema, table = table_key)

  if (verbose) {
    message("________________________________________________________________")
    message(glue::glue("Cascaded update of {schema}.{table_key}"))
  }

  # characteristic columns := columns which uniquely define a data row,
  # but which are not the primary key.
  if (is.null(characteristic_columns)) {
    # in case no char. cols provided, just take all columns.
    characteristic_columns <- names(new_data)
  }

  ## (0) check that characteristic columns are UNIQUE:
  # the char. columns of the data to upload
  new_characteristics <- new_data %>%
    select(!!!characteristic_columns) %>%
    distinct()
  stopifnot("Error: characteristic columns are not characteristic!" =
    nrow(new_data) == nrow(new_characteristics))


  to_upload <- new_data

  # existing content
  prior_content <- dplyr::tbl(
    db_connection,
    db_table
  ) %>% collect()
  # head(prior_content)


  ## (1) optionally append
  if (!tabula_rasa) {

    existing_characteristics <- prior_content %>%
      select(!!!characteristic_columns) %>%
      distinct()

    # refcol <- enquo(characteristic_columns)
    existing_unchanged <- existing_characteristics %>%
      anti_join(
        new_characteristics,
        by = join_by(!!!characteristic_columns)
      ) %>%
      left_join(
        prior_content,
        by = join_by(!!!characteristic_columns)
      )

    if (verbose) {
      message(glue::glue("  {nrow(existing_unchanged)} rows will be retained."))
    }

    # combine existing and new data
    to_upload <- bind_rows(
      existing_unchanged,
      to_upload
    )
  } else {
      message(glue::glue("  Tabula rasa: no rows will be retained."))
  }

  ## do not upload index columns
  retain_cols <- names(to_upload)
  retain_cols <- retain_cols[!(retain_cols %in% index_columns)]
  to_upload <- to_upload %>% select(!!!retain_cols)

  ## update datatable, propagating/cascading new keys to other's fk
  update_datatable_and_dependent_keys(
    config_filepath = config_filepath,
    working_dbname = working_dbname,
    table_key = table_key,
    new_data = to_upload,
    profile = connection_profile,
    dbstructure_folder = dbstructure_folder,
    db_connection = db_connection,
    characteristic_columns = characteristic_columns,
    verbose = verbose
  )
  # TODO rename_characteristics = rename_characteristics,

  lookup <- dplyr::tbl(
      db_connection,
      db_table
    ) %>%
    select(!!!c(characteristic_columns, index_columns)) %>%
    collect

  if (verbose){
    message(sprintf(
      "%s: %i rows uploaded, were %i existing judging by '%s'.",
      toString(db_table),
      nrow(to_upload),
      nrow(prior_content),
      paste0(characteristic_columns, collapse = ", ")
    ))
  }

  return(lookup)

} # /update_cascade_lookup



## ----upload-teammembers-------------------------------------------------------
members <- read_csv(
  here::here(dbstructure_folder, "data_TeamMembers.csv"),
  show_col_types = FALSE
)
# %>% filter(username != "Yglinga")



## THIS can go WRONG!
## ... because if members change, dependent table foreign keys are unaffected.
# member_lookup <- upload_and_lookup(
#   db_connection,
#   DBI::Id(schema = "metadata", table = "TeamMembers"),
#   members,
#   ref_cols = "username",
#   index_col = "teammember_id"
# )

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

grouped_activity_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "GroupedActivities",
  new_data = grouped_activities_upload,
  index_columns = c("grouped_activity_id", "activity_group_id", "activity_id"),
  characteristic_columns = c("activity_group", "activity"),
  verbose = TRUE
)


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

n2khabtype_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "N2kHabTypes",
  new_data = n2khab_types_upload,
  index_columns = c("n2khabtype_id"),
  characteristic_columns = c("type"),
  verbose = TRUE
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


n2khabstrata_lookup <- update_cascade_lookup(
  schema = "metadata",
  table_key = "lut_N2kHabStrata",
  new_data = n2khab_strata_upload,
  index_columns = c("n2khabstratum_id"),
  characteristic_columns = c("stratum"),
  verbose = TRUE
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

table_str <- '"outbound"."LocationAssessments"'
maintenance_users <- sprintf("'{update,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
     AND NOT assessment_done;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_location_assessments <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  ) %>% collect()
# nrow(previous_location_assessments)


## ----save-previous-extra-visits----------------------------------------------
# analogous: clean ExtraVisits
table_str <- '"inbound"."ExtraVisits"'
maintenance_users <- sprintf("'{update,%s}'", config$user)
cleanup_query <- glue::glue(
  "DELETE FROM {table_str}
    WHERE log_user = ANY ({maintenance_users}::varchar[])
     AND NOT visit_done;"
)
execute_sql(
  db_connection,
  cleanup_query,
  verbose = TRUE
)

previous_extra_visits <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "inbound", table = "ExtraVisits"),
  ) %>% collect()



## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - locationassessments_data
#    - sample_locations
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_locations

# sample_locations %>% pull(grts_address) %>% write.csv("dumps/sample_locations.csv")
# previous_location_assessments %>% pull(grts_address) %>% write.csv("dumps/location_assessments.csv")
# 15937

locations <- bind_rows(
    sample_locations %>% select(grts_address),
    previous_location_assessments %>% select(grts_address),
    previous_extra_visits %>% select(grts_address)
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






# OBSOLETE first, delete locations to prevent the `ogc_fid` duplicate error
# rs <- DBI::dbExecute(
#   db_connection,
#   'DELETE FROM "metadata"."Locations";'
#   )
#
# locations_lookup <- upload_and_lookup(
#   db_connection,
#   DBI::Id(schema = "metadata", table = "Locations"),
#   locations,
#   ref_cols = "grts_address",
#   index_col = "location_id"
# )


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
  )


slocs_refcols <- c(
  "type",
  "grts_address",
  "scheme",
  "panel_set",
  "targetpanel"
  # "sp_poststratum"
)

# tabula rasa: might otherwise be duplicated due to missing fk and null constraint
sample_locations_lookup <- update_cascade_lookup(
  schema = "outbound",
  table_key = "SampleLocations",
  new_data = sample_locations,
  index_columns = c("samplelocation_id"),
  characteristic_columns = slocs_refcols,
  tabula_rasa = TRUE,
  verbose = TRUE
)


# sample_locations_lookup %>% nrow()
# sample_locations_lookup %>%
#   select(!!!slocs_refcols) %>%
#   distinct %>%
#   nrow()


## ----restore-assessments-------------------------------------------------

# Here, we want to keep existing location assessments,
# UNLESS they never happened:
#  - imagine a sample unit X coming into the sample, then it will get a
#    prepared row for LocationAssessment
#  - however, if that sample unit is removed upon POC update without ever being
#    assessed, we remove it before.


# assemble new assessments
new_location_assessments <- sample_locations %>%
  distinct(
    grts_address,
    type
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
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
  ) %>%
  select(-location_id) %>%
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
  schema = "outbound",
  table_key = "LocationAssessments",
  new_data = new_location_assessments,
  index_columns = c("locationassessment_id"),
  characteristic_columns = c("type", "grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

# TODO the "old" ones also require a new location_id
#    -> write a function to UPDATE the lookup key by grts_address


## ----extra-visits-------------------------------------------------
##

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
    date_visit = as.Date(NA),
    log_user = "update",
    log_update = as.POSIXct(Sys.time()),
    visit_done = FALSE
  )

# new_extra_visits %>%
#   count(location_id, grts_address) %>%
#   arrange(desc(n))


# NOTE the location is still not unique?!
# -> Of course:
#     There are multiple sample units with different `type`
#     on identical locations.

# append the LocationAssessments with empty lines for new sample units
extravisits_lookup <- update_cascade_lookup(
  schema = "inbound",
  table_key = "ExtraVisits",
  new_data = new_extra_visits,
  index_columns = c("extravisit_id"),
  characteristic_columns = c("grts_address", "samplelocation_id"),
  tabula_rasa = FALSE,
  verbose = TRUE
)



## ----done-checks!-------------------------------------------------

### check upload

slocs <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "outbound", table = "SampleLocations"),
  ) %>% collect()

locs <- sf::st_read(
  db_connection,
  DBI::Id(schema = "metadata", table = "Locations"),
  )

locs %>% anti_join(
  slocs,
  by = join_by(location_id)
  )

locs %>% anti_join(
  slocs,
  by = join_by(grts_address)
  )

# SELECT DISTINCT assessment_done, cell_disapproved, count(*) FROM "outbound"."LocationAssessments" GROUP BY assessment_done, cell_disapproved;
