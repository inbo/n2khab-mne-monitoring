#!/usr/bin/env Rscript

# to lookup:
#  samplelocation_id
#  location_id
#
# given:
# | grts_address | activity_group_id | date_start | stratum  |
# |     21323197 |                 4 | 2026-07-01 | 1310_pol |
# was replacement 49896893 -> 21323197

# search info in calendar:
# fag_stratum_grts_calendar %>%
# fag_stratum_grts_calendar_2025_attribs %>%
#   filter(
#     grts_address %in% c(49896893, 21323197),
#     field_activity_group == "GWINSTPIEZWELL"
#   ) %>% t() %>% knitr::kable()
# NOTE that `date_start` may not same as the original! (uniqueness constraint)


message("._______________________________________________________________.")
message("|  sideloading outbound.FieldworkCalendar and depdc to mnmgwdb  |")
message("._______________________________________________________________.")


source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# These replacements are injected to `loceval`, then transferred to `mnmgwdb`
database_label <- "mnmgwdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}

### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(mnmgwdb$shellstring)


update_cascade_lookup <- parametrize_cascaded_update(mnmgwdb)

#_______________________________________________________________________________

load_poc_common_libraries()

tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()
load_poc_rdata(reload = FALSE, to_env = parent.frame())
message(glue::glue("Good morning!
  Loading the POC data took {tic(toc)} seconds today."
))


snippets_path <- "/data/git/n2khab-mne-monitoring_support"

toc <- Sys.time()
load_poc_code_snippets(snippets_path)
message(glue::glue(
  "... loading/executing the code snippets took {tic(toc)}s."
))

verify_poc_objects()


#_______________________________________________________________________________

calendar_characols <- c(
    "grts_address",
    "stratum",
    "date_start",
    "activity_group_id"
  )

# load the rows to sideload
calendar_to_sideload <- load_table_sideload_content(
  mnmdb = mnmgwdb,
  table_label = "FieldworkCalendar",
  characteristic_columns = calendar_characols,
  data_filepath = "sideload/mnmgwdb_calendars.csv"
)


samplelocations_lookup <- mnmgwdb$query_columns(
  "SampleLocations", c("grts_address", "strata", "samplelocation_id", "location_id")
) %>% rename(stratum = strata)


calendar_upload <- calendar_to_sideload %>%
  inner_join(
    samplelocations_lookup,
    by = join_by(grts_address, stratum),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE,
    is_sideloaded = TRUE
  )

calendar_upload %>% t() %>% knitr::kable()


calendar_lookup <- update_cascade_lookup(
  table_label = "FieldworkCalendar",
  new_data = calendar_upload %>% select(-location_id),
  index_columns = c("fieldworkcalendar_id"),
  characteristic_columns = calendar_characols,
  tabula_rasa = FALSE, # !!!
  verbose = TRUE
)

fwcalendar_upload <- calendar_upload %>%
  left_join(
    calendar_lookup,
    by = join_by(!!!rlang::syms(calendar_characols))
  )

#_______________________________________________________________________________

visits_characols <- c("fieldworkcalendar_id", calendar_characols)


visits_upload <- fwcalendar_upload %>%
  select(
    fieldworkcalendar_id,
    samplelocation_id,
    location_id,
    grts_address,
    stratum,
    activity_group_id,
    date_start
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    issues = FALSE,
    visit_done = FALSE
  )


visits_upload %>% t() %>% knitr::kable()


visits_lookup <- update_cascade_lookup(
  table_label = "Visits",
  new_data = visits_upload,
  index_columns = c("visit_id"),
  characteristic_columns = visits_characols,
  tabula_rasa = FALSE, # !!!
  verbose = TRUE
)



#_______________________________________________________________________________

# SELECT DISTINCT activity_group, activity_group_id FROM "metadata"."GroupedActivities" WHERE activity_group LIKE 'GW%SAMP%';

speacial_activity_basecols <- c(
  "samplelocation_id",
  "fieldworkcalendar_id",
  "visit_id",
  "grts_address",
  "stratum",
  "activity_group_id",
  "date_start"
)

selection_of_activities <- list(
  "WellInstallationActivities" = function(df) df %>%
    filter(activity_group_id == 4)
, # /WIA
  "ChemicalSamplingActivities" = function(df) df %>%
    filter(activity_group_id %in% c(12, 13, 16))
 # /CSA
)

empty_init <- list(
  "WellInstallationActivities" = function(df) df %>%
    select(!!!rlang::syms(speacial_activity_basecols)) %>%
    mutate(
      no_diver = FALSE,
      soilprofile_unclear = FALSE,
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    ), # /WIA
  "ChemicalSamplingActivities" = function(df) df %>%
    select(!!!rlang::syms(speacial_activity_basecols)) %>%
    mutate(
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    )
 # /CSA
)

activities_upload <- fwcalendar_upload %>%
  left_join(
    visits_lookup,
    by = join_by(!!!rlang::syms(visits_characols))
  )


# table_label <- "WellInstallationActivities"
for (table_label in c("WellInstallationActivities", "ChemicalSamplingActivities")) {

  special_activities_upload <- activities_upload %>%
    selection_of_activities[[table_label]]() %>%
    empty_init[[table_label]]()
  # special_activities_upload %>% t() %>% knitr::kable()

  if (nrow(special_activities_upload) == 0) next


  lookup <- update_cascade_lookup(
    table_label = table_label,
    new_data = special_activities_upload,
    index_columns = c("fieldwork_id"),
    characteristic_columns = speacial_activity_basecols,
    tabula_rasa = FALSE,
    skip_sequence_reset = TRUE,
    verbose = TRUE
  )

}
