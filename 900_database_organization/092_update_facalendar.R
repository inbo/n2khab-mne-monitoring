#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

## ----database-connection------------------------------------------------------
# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# TODO this does not yet work for `loceval` (based on SampleLocations)
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

## ----poc-data-----------------------------------------------------------------
# re-load POC data
load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())

# ... and code snippets.
snippets_path <- rprojroot::find_root(rprojroot::is_git_root)
load_poc_code_snippets(snippets_path)

verify_poc_objects()


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update

update_cascade_lookup <- parametrize_cascaded_update(mnmgwdb)


### query true activity calendar
activity_groupid_lookup <- mnmgwdb$query_columns(
    table_label = "GroupedActivities",
    c("activity_group", "activity_group_id")
  ) %>%
  distinct()

gw_field_activities <- mnmgwdb$query_table("GroupedActivities") %>%
  filter(is_gw_activity, is_field_activity) %>%
  distinct(activity_group, activity)


locations_lookup <- mnmgwdb$query_columns(
    table_label = "Locations",
    select_columns = c("location_id", "grts_address")
  )

# TODO anti-join to find missing slocs
samplelocations_lookup <- mnmgwdb$query_columns(
    table_label = "SampleLocations",
    select_columns = c("samplelocation_id", "grts_address", "strata")
  )


# requires 092 to be run / ReplacementData up to date
replacement_lookup <- mnmgwdb$query_columns(
    "ReplacementData",
    c(
      "grts_address",
      "type",
      "grts_address_replacement"
    )
  ) %>%
  rename(stratum = type)


replace_grts_local <- function(df, typecolumn = "stratum") {

  stopifnot("dplyr" = require("dplyr"))

  lookup <- replacement_lookup
  names(lookup)[names(lookup) == "stratum"] <- typecolumn

  df %>%
    dplyr::left_join(
      lookup,
      by = dplyr::join_by(!!!c("grts_address", typecolumn))
    ) %>%
    dplyr::mutate(
      grts_address = dplyr::coalesce(grts_address_replacement, grts_address)
    ) %>%
    dplyr::select(-grts_address_replacement) %>%
    return()
}


### Locations - restoring
# seems to be the new thing.

locations <- bind_rows(
    mnmgwdb$query_columns("Locations", c("grts_address")),
    # sample_units %>% select(grts_address),
    mnmgwdb$query_columns("LocationInfos", c("grts_address")),
    mnmgwdb$query_columns("ReplacementData", c("grts_address")),
    mnmgwdb$query_columns("ReplacementData", c("grts_address_replacement")) %>%
      rename(grts_address = grts_address_replacement),
    mnmgwdb$query_columns("FieldworkCalendar", c("grts_address")),
    mnmgwdb$query_columns("Visits", c("grts_address"))
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


table_label <- "Locations"
data_nouveau <- locations %>% sf::st_drop_geometry()# %>% select(-wkb_geometry)
index_column <- mnmgwdb$get_primary_key(table_label)
characteristic_columns <- c("grts_address")

distribution <- categorize_data_update(
  mnmdb = mnmgwdb,
  table_label = table_label,
  data_future = data_nouveau,
  input_precedence_columns = precedence_columns[[table_label]],
  characteristic_columns = characteristic_columns,
  exclude_columns = c("wkb_geometry")
)
print_category_count(distribution, table_label)

locations_lookup <- redistribute_calendar_data(
  mnmdb = mnmgwdb,
  table_label = table_label,
  distribution = distribution,
  index_columns = c(index_column),
  characteristic_columns = characteristic_columns,
  skip = list("update" = FALSE, "upload" = FALSE, "archive" = TRUE)
)


# fieldwork_2025_prioritization_by_stratum %>%
# fieldwork_calendar %>%
# samplelocations_lookup %>%
#   filter(grts_address == 871030)

# fieldwork_2025_prioritization_by_stratum %>%
#   filter(grts_address == 84598, field_activity_group == "LOCEVALTERR") %>%
#   t() %>% knitr::kable()
#
# fieldwork_2025_prioritization_by_stratum %>%
#   filter(grts_address == 84598, field_activity_group != "LOCEVALTERR") %>%
#   t() %>% knitr::kable()

fieldwork_calendar <-
  fieldwork_2025_prioritization_by_stratum %>%
  common_current_calenderfilters() %>% # should be filtered already!
  rename_grts_address_final_to_grts_address() %>%
  replace_grts_local() %>%
  relocate(grts_address) %>%
  inner_join(
    samplelocations_lookup %>% rename(stratum = strata),
    by = join_by(grts_address, stratum),
    relationship = "many-to-one"
  ) %>%
  relocate(samplelocation_id) %>%
  rename(
    activity_rank = rank,
    activity_group = field_activity_group
  ) %>%
  semi_join(gw_field_activities, by = join_by(activity_group)) %>%
  left_join(
    activity_groupid_lookup,
    by = join_by(activity_group),
    relationship = "many-to-one"
  ) %>%
  select(-activity_group) %>%
  mutate(
    across(c(
        date_interval
      ),
      as.character
    )
  ) %>%
  rename(stratum_scheme_ps_targetpanels = scheme_ps_targetpanels) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    is_sideloaded = FALSE,
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  )


# fieldwork_calendar %>%
#   filter(grts_address %in% c(2137206, 49692341)) %>%
#   t() %>% knitr::kable()
# fieldwork_2025_prioritization_by_stratum %>%
#   filter(grts_address_final %in% c(2137206, 49692341)) %>%
#   t() %>% knitr::kable()

### query previous calendar
## ----save-previous-FACs----------------------------------------------

# previous_calendar_plans <- mnmgwdb$query_table("FieldworkCalendar") %>%
#   left_join(
#     mnmgwdb$query_table("SSPSTaPas"),
#     by = join_by(sspstapa_id)
#   ) %>%
#   relocate(stratum_scheme_ps_targetpanels, .after = sspstapa_id) %>%
#   select(-sspstapa_id)

# glimpse(previous_calendar_plans)

# previous_calendar_plans %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()

replace_sspstapa_by_lookup <- function(df) {
  df_new <- df %>%
    mutate(sspstapa_id = NA) %>%
    # left_join(
    #   sspstapas,
    #   by = join_by(stratum_scheme_ps_targetpanels),
    #   relationship = "many-to-one"
    # ) %>%
    relocate(
      sspstapa_id,
      .after = stratum_scheme_ps_targetpanels
    ) %>%
    select(-stratum_scheme_ps_targetpanels)

  return(df_new)
}

fieldwork_calendar_new <- fieldwork_calendar %>%
  replace_sspstapa_by_lookup() %>%
  select(
    # -location_id,
    -grts_join_method,
    -domain_part,
    -is_forest,
    -in_mhq_samples,
    -last_type_assessment_in_field
  )

fieldcalendar_characols <- c(
    "grts_address",
    "stratum",
    "activity_group_id",
    "date_start"
  )


# sideloading: extra activities e.g. to follow up issues in the field
calendar_to_sideload <- load_table_sideload_content(
    mnmdb = mnmgwdb,
    table_label = "FieldworkCalendar",
    characteristic_columns = fieldcalendar_characols,
    data_filepath = "sideload/mnmgwdb_calendars.csv",
    reload_previous = TRUE
  ) %>%
  inner_join(
    samplelocations_lookup %>% rename(stratum = strata),
    by = join_by(grts_address, stratum),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  ) %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    is_sideloaded = TRUE,
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  )

fieldwork_calendar_new <- bind_rows(
  fieldwork_calendar_new,
  calendar_to_sideload %>%
    anti_join(
      fieldwork_calendar_new,
      by = join_by(!!!rlang::syms(fieldcalendar_characols))
    )
  )



table_label <- "FieldworkCalendar"
data_nouveau <- fieldwork_calendar_new
characteristic_columns <- fieldcalendar_characols
index_column <- mnmgwdb$get_primary_key(table_label)

# fieldwork_calendar_new %>%
#   filter(grts_address %in% c(2137206, 49692341)) %>%
#   t() %>% knitr::kable()


# link start dates of old and new plans by shifting old plans
startdate_updates_happened <- associate_and_shift_start_dates(
  mnmdb = mnmgwdb,
  table_label = table_label,
  data_future = data_nouveau,
  characteristic_columns = characteristic_columns,
  other_table_labels = c(
    "Visits",
    "WellInstallationActivities",
    "ChemicalSamplingActivities"
  )
)

# attention: do NOT use `previous_calendar_plans` any more


distribution <- categorize_data_update(
  mnmdb = mnmgwdb,
  table_label = table_label,
  data_future = data_nouveau,
  input_precedence_columns = precedence_columns[[table_label]],
  characteristic_columns = characteristic_columns,
  archive_flag_column = "archive_version_id"
)
print_category_count(distribution, table_label)



if (FALSE) {
# manual checks

current_calendar_db <- mnmgwdb$query_table("FieldworkCalendar") %>%
  left_join(
    mnmgwdb$query_table("SSPSTaPas"),
    by = join_by(sspstapa_id)
  ) %>%
  relocate(stratum_scheme_ps_targetpanels, .after = sspstapa_id) %>%
  select(-sspstapa_id)


distribution$reactivate %>%
  count(grts_address, stratum) %>%
  print(n = Inf)

distribution$to_archive %>%
  count(grts_address, stratum) %>%
  print(n = Inf)

# select_grts <- 871030
# select_stratum <- "4010"
select_grts <- 9262
select_stratum <- "9120"
select_grts <- 32213266
select_stratum <- "7140_mrd"


check <- function(df, ...) {
  df %>%
    filter(...) %>%
    select(
      samplelocation_id,
      grts_address,
      stratum,
      date_start,
      activity_group_id,
      priority
    ) %>%
    arrange(grts_address, stratum, date_start, activity_group_id) %>%
    return()
}

current_calendar_db %>%
# data_previous %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()


data_future %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()


message("##### ARCHIVE ####")
distribution$to_archive %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()

message("##### UNCHANGED ####")
distribution$unchanged %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()

message("##### REACTIVATE ####")
distribution$reactivate %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()

message("##### CHANGED ####")
distribution$changed %>%
  check(grts_address == select_grts, stratum == select_stratum) %>%
  t() %>% knitr::kable()

distribution$changed %>%
  filter(
    grts_address == select_grts,
    stratum == select_stratum,
    activity_group_id == 4
  ) %>%
  t() %>% knitr::kable()

current_calendar_db %>%
  filter(
    grts_address == select_grts,
    stratum == select_stratum,
    activity_group_id == 4
  ) %>%
  t() %>% knitr::kable()


} # /checking intervention

# GOOD TO KNOW:
#   - Entries can be reactivated AND changed in the same round.
#   - In the case of date adjustments: `date_end` was updated afterwards.


distribution$to_upload <- distribution$to_upload %>%
  mutate(
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time()),
    excluded = FALSE,
    no_visit_planned = FALSE,
    done_planning = FALSE
  )


fieldworkcalendar_lookup <- redistribute_calendar_data(
  mnmdb = mnmgwdb,
  table_label = table_label,
  distribution = distribution,
  index_columns = c(index_column),
  characteristic_columns = characteristic_columns,
  skip = list("update" = FALSE, "upload" = FALSE, "archive" = FALSE)
)


mnmgwdb$query_table("FieldworkCalendar") %>%
  count(is.na(samplelocation_id)) %>%
  knitr::kable()



#_______________________________________________________________________________


visits_characols <- c("fieldworkcalendar_id", fieldcalendar_characols)

new_visits <- fieldworkcalendar_lookup %>%
  select(
    !!!visits_characols
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


visits_upload <- new_visits %>%
  anti_join(
    mnmgwdb$query_table("Visits"),
    by = join_by(!!!fieldcalendar_characols)
  )

visits_lookup <- update_cascade_lookup(
  table_label = "Visits",
  new_data = visits_upload,
  index_columns = c("visit_id"),
  characteristic_columns = visits_characols,
  tabula_rasa = FALSE,
  verbose = TRUE
)


mnmgwdb$query_table("Visits") %>%
  count(is.na(fieldworkcalendar_id)) %>%
  knitr::kable()


# archive visits of archived FWCals

trgtab <- mnmgwdb$get_namestring("Visits")
srctab <- mnmgwdb$get_namestring("FieldworkCalendar")
link_key_column <- "archive_version_id"
lookup_criteria <- c("TRGTAB.fieldworkcalendar_id = SRCTAB.fieldworkcalendar_id")

update_string <- glue::glue("
  UPDATE {trgtab} AS TRGTAB
    SET
      {link_key_column} = SRCTAB.{link_key_column}
    FROM {srctab} AS SRCTAB
    WHERE
     ({paste0(lookup_criteria, collapse = ') AND (')})
  ;")

mnmgwdb$execute_sql(update_string)

mnmgwdb$query_table("FieldworkCalendar") %>%
  anti_join(
    mnmgwdb$query_table("Visits"),
    by = join_by(fieldworkcalendar_id, archive_version_id)
  ) %>% nrow()



#_______________________________________________________________________________
# Fieldwork Activity Tables

selection_of_activities <- list(
  "WellInstallationActivities" = function(df) df %>%
    filter(grepl("^GWINST", activity_group)), # /WIA
  "ChemicalSamplingActivities" = function(df) df %>%
    filter(activity_group %in%
      c(gw_field_activities %>%
        filter(grepl("^GW.*SAMP", activity)) %>%
        pull(activity_group))
      ) # /CSA
)

empty_init <- list(
  "WellInstallationActivities" = function(df) df %>%
    mutate(
      no_diver = FALSE,
      soilprofile_unclear = FALSE,
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    ), # /WIA
  "ChemicalSamplingActivities" = function(df) df %>%
    mutate(
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    ) # /CSA
)


visits_redownload <- mnmgwdb$query_table("Visits") %>%
  filter(is.na(archive_version_id)) %>%
  select(-archive_version_id)

visits_redownload <- visits_redownload %>%
  left_join(
    mnmgwdb$query_columns(
        "GroupedActivities",
        c("activity_group_id", "activity_group")) %>%
      distinct(),
    by = join_by(activity_group_id)
  )


speciact_characols <- c(
  "grts_address",
  "stratum",
  "activity_group_id",
  "date_start"
)
# "samplelocation_id",
# "fieldworkcalendar_id",
# "visit_id",

# table_label <- "WellInstallationActivities"
# table_label <- "ChemicalSamplingActivities"


for (table_label in c("WellInstallationActivities", "ChemicalSamplingActivities")) {

  special_activities <- visits_redownload %>%
    selection_of_activities[[table_label]]()

  existing <- mnmgwdb$query_table(table_label)

  # no archiving necessary on these - they 1:1 depend on Visits
  novel <- special_activities %>%
    anti_join(
      existing,
      by = join_by(
        grts_address,
        stratum,
        activity_group_id,
        date_start
      )
    ) %>%
    select(!!!speciact_characols) %>%
    empty_init[[table_label]]()

  lookup <- update_cascade_lookup(
    table_label = table_label,
    new_data = novel,
    index_columns = c("fieldwork_id"),
    characteristic_columns = speciact_characols,
    tabula_rasa = FALSE,
    skip_sequence_reset = TRUE, # fieldwork_id is tricky
    verbose = TRUE
  )

}


#-------------------------------------------------------------------------------
# exclude those where type was absent

absent_type_fwcals <- mnmgwdb$query_table("LocationEvaluations") %>%
  filter(
    eval_source == "loceval",
    type_is_absent
  ) %>%
  select(
    grts_address, type
  ) %>%
  rename(stratum = type) %>%
  left_join(
    mnmgwdb$query_columns(
      "FieldworkCalendar",
      c("grts_address", "stratum", "fieldworkcalendar_id")
    ) %>% distinct(),
    by = join_by(grts_address, stratum)
  ) %>%
  filter(!is.na(fieldworkcalendar_id)) %>%
  pull(fieldworkcalendar_id)


present_type_fwcals <- mnmgwdb$query_table("FieldworkCalendar") %>%
  filter(
    excluded,
    grepl("type_is_absent", excluded_reason),
    !(fieldworkcalendar_id %in% absent_type_fwcals)
  ) %>%
  select(fieldworkcalendar_id, grts_address, excluded_reason)


# exclude cells where the expected type was not found
absent_type_fwcals <- paste0(
  absent_type_fwcals[],
  collapse = ", "
)
message(glue::glue("excluding: fwcal ⊆ {absent_type_fwcals}"))

mnmgwdb$execute_sql(
  glue::glue("
    UPDATE {mnmgwdb$get_namestring('FieldworkCalendar')}
    SET excluded = TRUE, excluded_reason = 'loceval: type_is_absent'
    WHERE fieldworkcalendar_id IN ({absent_type_fwcals})
    ;
  ")
)



if (nrow(present_type_fwcals) > 0) {
  restore_type_fwcals <- paste0(present_type_fwcals$fieldworkcalendar_id, collapse = ", ")
  message(glue::glue("reverting exclusion: fwcal ⊆ {restore_type_fwcals}"))

  # restore "non-absent type" cells
  for (row_nr in seq_len(nrow(present_type_fwcals))) {
    fwcal_id <- present_type_fwcals[row_nr, ][["fieldworkcalendar_id"]]
    excluded_reason <- present_type_fwcals[row_nr, ][["excluded_reason"]]
    excluded_reason <- gsub("loceval: type_is_absent", "", excluded_reason)

    mnmgwdb$execute_sql(
      glue::glue("
        UPDATE {mnmgwdb$get_namestring('FieldworkCalendar')}
        SET excluded = FALSE, excluded_reason = '{excluded_reason}'
        WHERE fieldworkcalendar_id = {fwcal_id}
        ;
      ")
    )

  }
}


message("")
message("  Finished. Make sure to inspect the log.  ")
message("________________________________________________________________")

