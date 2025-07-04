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
  "NOT FOUND: RData >> `activity_sequences`" =
      exists("activity_sequences")
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




## ----load-config--------------------------------------------------------------
config_filepath <- file.path("./inbopostgis_server.conf")

if (working_dbname == "loceval") {
  db_connection <- connect_database_configfile(
    config_filepath,
    database = "loceval",
    profile = "inbopostgis"
  )

} else {
  db_connection <- connect_database_configfile(
    config_filepath,
    database = working_dbname,
    profile = "inbopostgis-dev"
  )

}



## ----upload-teammembers-------------------------------------------------------
members <- read_csv(here::here("db_structure", "data_TeamMembers.csv"))

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


## ----upload-grouped-activities------------------------------------------------

grouped_activities_upload <- grouped_activities %>%
  lookup_join(protocol_lookup, "protocol")

# append_tabledata(
#   db_connection,
#   DBI::Id(schema = "metadata", table = "GroupedActivities"),
#   grouped_activities_upload,
#   reference_columns = "grouped_activity_id"
# )

# done manually to get multiple columns as unique lookup

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

## ----TODO restore-assessments-------------------------------------------------





## ----upload-sample-locations--------------------------------------------------
# glimpse(orthophoto_2025_type_grts)
stopifnot(
  "snip snap >> `orthophoto grts` not found" = exists("orthophoto_2025_type_grts")
)

sample_locations <- orthophoto_2025_type_grts %>%
  select(-grts_address) %>%
  rename(
    grts_address = grts_address_final,
    previous_assessment = assessed_in_field,
    previous_assessment_date = assessment_date
  ) %>%
  mutate(
    across(c(
        type,
        grts_join_method,
        sp_poststratum,
        scheme_ps_targetpanels
      ),
      as.character
    )
  )

# glimpse(sample_locations)



# clean up LocationAssessments
verb <- "DELETE "
sql_command <- glue::glue(
  '{verb} FROM "outbound"."LocationAssessments"
    WHERE ((log_user = \'yoda\') OR (log_user = \'falk\') OR (log_user = \'update\'))
      AND (NOT cell_disapproved)
      AND (revisit_disapproval IS NULL)
      AND (disapproval_explanation IS NULL)
      AND (type_suggested IS NULL)
      AND (implications_habitatmap IS NULL)
      AND (feedback_habitatmap IS NULL)
      AND (notes IS NULL)
      AND (NOT assessment_done)
    ;')
# print(sql_command)
rs <- DBI::dbExecute(
  db_connection,
  sql_command
  )
# print(rs)

# DBI::dbReadTable(
#   db_connection,
#   DBI::Id(schema = "outbound", table = "LocationAssessments"),
#   ) %>% collect() %>%
#     head() %>% knitr::kable()

# add location for previous LocationAssessment

previous_locations <- DBI::dbReadTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  ) %>% collect() %>%
  pull("grts_address") %>%
  as.integer()


# **Upload Spatial Locations:**
locations <- c(
    sample_locations %>% pull(grts_address) %>% as.integer(),
    previous_locations
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


# **Upload Sample Locations:**

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

append_tabledata(
  db_connection,
  DBI::Id(schema = "outbound", table = "SampleLocations"),
  sample_locations,
  reference_columns =
    c("type", "grts_address", "scheme_ps_targetpanels", "loceval_year")
)



# **Append Location Assessments:**

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

previous_location_assessments <- DBI::dbReadTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  ) %>% collect()
# nrow(previous_location_assessments)

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
