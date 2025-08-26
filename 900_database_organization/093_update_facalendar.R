
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

source("MNMDatabaseToolbox.R")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")

testing <- TRUE
if (testing) {
  suffix <- "staging" # "testing"
  working_dbname <- glue::glue("mnmgwdb_{suffix}")
  connection_profile <- glue::glue("mnmgwdb-{suffix}")
  dbstructure_folder <- "./mnmgwdb_db_structure"
} else {
  # source("094_replaced_LocationCells.R")
  keyring::key_set("DBPassword", "db_user_password") # <- for source database
  working_dbname <- "mnmgwdb"
  connection_profile <- "mnmgwdb"
  dbstructure_folder <- "./mnmgwdb_db_structure"
}


### connect to database
config <- configr::read.config(file = config_filepath)[[connection_profile]]
db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


# re-load POC data
poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)

# re-run code
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R")
invisible(capture.output(source("050_snippet_selection.R")))
source("051_snippet_transformation_code.R")


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update

update_cascade_lookup <- parametrize_cascaded_update(
  config_filepath,
  working_dbname,
  connection_profile,
  dbstructure_folder,
  db_connection
)


### query true activity calendar

# TODO anti-join to find missing slocs
samplelocations_lookup <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "outbound", table = "SampleLocations")
  ) %>%
  select(samplelocation_id, grts_address) %>%
  collect


grouped_activities <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "metadata", table = "GroupedActivities")
  ) %>% collect


gw_field_activities <- grouped_activities %>%
  filter(is_gw_activity, is_field_activity) %>%
  distinct(activity_group)

activity_groupid_lookup <-
  dplyr::tbl(
    db_connection,
    DBI::Id(schema = "metadata", table = "GroupedActivities"),
  ) %>%
  distinct(activity_group, activity_group_id) %>%
  collect()


# fieldwork_2025_prioritization_by_stratum %>%
# fieldwork_calendar %>%
# samplelocations_lookup %>%
#   filter(grts_address == 871030)

fieldwork_calendar <-
  fieldwork_2025_prioritization_by_stratum %>%
  rename_grts_address_final_to_grts_address() %>%
  relocate(grts_address) %>%
  left_join(
    samplelocations_lookup %>%
      select(grts_address),
    by = join_by(grts_address),
    relationship = "many-to-one",
    unmatched = "drop"
  ) %>%
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
  left_join(
    samplelocations_lookup,
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
  )


### quick fix: restore SSPSTaPas link (20250825)
if (FALSE) {
  sspstapas_values <- fieldwork_calendar %>%
    mutate(
      stratum_scheme_ps_targetpanels = str_c(
          stratum,
          " (",
          grts_join_method,
          ") ",
          " [",
          scheme_ps_targetpanels,
          "]"
        )
    ) %>%
    select(samplelocation_id, stratum_scheme_ps_targetpanels) %>%
    left_join(
      dplyr::tbl(
        db_connection,
        DBI::Id(schema = "metadata", table = "SSPSTaPas")
      ) %>% collect(),
      by = join_by(stratum_scheme_ps_targetpanels)
    ) %>%
    distinct()

  update_sspstapas_restore <- function(row_nr, target_namestring) {
    row <- sspstapas_values[row_nr, ]
    if (is.na(row[[1]])){
        return(invisible(NA))
    }

    if (is.na(row[[3]])){
        return(invisible(NA))
    }

    update_string <- glue::glue("
       UPDATE {target_namestring}
         SET sspstapa_id = '{row[[3]]}'
       WHERE samplelocation_id = {row[[1]]}
       ;
     ")

    execute_sql(
      db_connection,
      update_string,
      verbose = TRUE
    )
  }
  for (row_nr in 1:nrow(sspstapas_values)){
    targettable_namestring <- glue::glue('"outbound"."FieldworkCalendar"')
    targettable_namestring <- glue::glue('"inbound"."Visits"')
    update_sspstapas_restore(row_nr, targettable_namestring)
  }

}

fieldwork_calendar %>%
  filter(grts_address == 23238)
# fieldwork_2025_prioritization_by_stratum %>%
#   filter(grts_address == 23238) %>%
#   select(stratum, field_activity_group, rank, priority, date_interval, scheme_ps_targetpanels)


# check errors in the sample units
if(FALSE){
sample_units <-
  fag_stratum_grts_calendar %>%
  distinct(
    scheme_moco_ps,
    stratum,
    grts_address
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      distinct( # <- deduplicating 7220
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  )

sample_units %>% filter(grts_address == 23238)
}

### query previous calendar
## ----save-previous-FACs----------------------------------------------

table_str <- '"outbound"."FieldworkCalendar"'
# table_str_visits <- '"inbound"."Visits"'

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



### select only replaced locations

replacements <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "archive", table = "ReplacementData")
  ) %>%
  rename(c("stratum" = "type")) %>%
  collect


fieldwork_calendar <- fieldwork_calendar %>%
  semi_join(
    replacements,
    by = join_by(grts_address, stratum)
  ) %>%
  inner_join(
    replacements %>%
      select(
        grts_address, stratum, new_samplelocation_id, grts_address_replacement
      ),
    by = join_by(grts_address, stratum),
    relationship = "many-to-many"
  ) %>%
  mutate(
    samplelocation_id = new_samplelocation_id,
    grts_address = grts_address_replacement,
    stratum_scheme_ps_targetpanels = str_c(
        stratum,
        " (",
        grts_join_method,
        ") ",
        " [",
        scheme_ps_targetpanels,
        "]"
      )
  ) %>%
  select(-new_samplelocation_id, grts_address_replacement)


# TODO remove `stratum_scheme_ps_targetpanels` on switch to SampleUnits

sspstapas <- update_cascade_lookup(
  schema = "metadata",
  table_key = "SSPSTaPas",
  new_data = fieldwork_calendar %>%
    distinct(stratum_scheme_ps_targetpanels) %>%
    arrange(stratum_scheme_ps_targetpanels),
  index_columns = c("sspstapa_id"),
  tabula_rasa = FALSE,
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
    # "sspstapa_id",
    "grts_address",
    "activity_group_id",
    "date_start"
  )

# previous_calendar_test <- fieldwork_calendar[1:500,]
# glimpse(previous_calendar_plans %>% replace_sspstapa_by_lookup())
# TODO had an issue where sspstapas were lost...

# only prev activities in the new replaced locations are considered
previous_calendar_plans <- previous_calendar_plans %>%
  semi_join(
    fieldwork_calendar,
    by = join_by(samplelocation_id)
  ) # %>% glimpse


# find the ones where nothing has been planned
previous_non_activities <- previous_calendar_plans %>%
  filter(
    log_user %in% c("update", "maintenance", config$user),
    !excluded,
    is.na(teammember_assigned),
    is.na(date_visit_planned),
    !no_visit_planned,
    is.na(notes),
    !done_planning
  )

# the complement are previous plans by Tom
previous_calendar_planned <-
  previous_calendar_plans %>%
  anti_join(
    previous_non_activities,
    by = join_by(fieldworkcalendar_id)
  )

# nrow(previous_calendar_plans) == nrow(previous_non_activities) + nrow(previous_calendar_planned)
# glimpse(fieldwork_calendar)
# glimpse(previous_calendar_planned)



samplelocations <- fieldwork_calendar %>%
  pull(samplelocation_id) %>%
  unique


prior_visits <- dplyr::tbl(
  db_connection,
  DBI::Id(schema = "inbound", table = "Visits"),
  ) %>%
  filter(visit_done) %>%
  select(fieldworkcalendar_id) %>%
  collect()


### TODO loop
# testing
# replacements %>% filter(grts_address == 769793)
# sloc <- fieldwork_calendar %>% filter(grts_address == 23238) %>% pull(samplelocation_id) %>% unique
# sloc <- fieldwork_calendar %>% filter(grts_address == 253621) %>% pull(samplelocation_id) %>% unique
# and a great example:
# sloc <- fieldwork_calendar %>% filter(grts_address == 1818369) %>% pull(samplelocation_id) %>% unique
# sloc = 860 # potential duplicate 20250821

classify_calendar_events <- function(sloc) {
  calendar <- fieldwork_calendar %>%
    filter(samplelocation_id == sloc) %>%
    mutate(temp_idx = seq_len(n()))
  prior_plans <- previous_calendar_planned %>%
    filter(samplelocation_id == sloc)
  obsolete <- previous_non_activities %>%
    filter(samplelocation_id == sloc)

  # glimpse(calendar)
  # glimpse(prior_plans)
  # glimpse(obsolete)

  # for every new `calendar` item, looped by samplelocation_id:
  # - if prior plans, update selectively (done_planning? visit_done?)
  # - if obsolete, simply replace
  # concrete steps:
  # - separate obsoletes and priors
  # - find missed ones = novel activities
  # - update to_update
  # - delete obsoletes
  # - upload to_upload

  to_update <- calendar %>%
    inner_join(
      prior_plans %>% select(
        activity_group_id,
        activity_rank,
        date_start,
        fieldworkcalendar_id
        ),
      by = join_by(
        activity_group_id,
        activity_rank,
        date_start
      )
    )

  to_upload <- calendar %>%
    semi_join(
      obsolete,
      by = join_by(
        activity_group_id,
        activity_rank,
        date_start
      )
    )

  # find missed ones
  novel <- calendar %>%
    anti_join(to_upload, by = join_by(temp_idx)) %>%
    anti_join(to_update, by = join_by(temp_idx))
  # novel ones should all be
  # completely new activity groups, changed ranks, or dates.

  to_upload <- to_upload %>% bind_rows(novel) %>% distinct()

  return(list(
    "to_upload" = to_upload,
    "obsolete" = obsolete,
    "to_update" = to_update
  ))

} # /classify_calendar_events

all_calendar_modifications <- lapply(
  samplelocations,
  FUN = classify_calendar_events
)

to_upload <- bind_rows(lapply(
  seq_len(length(all_calendar_modifications)),
  FUN = function(elm) all_calendar_modifications[[elm]]$to_upload
  ))
obsolete <- bind_rows(lapply(
  seq_len(length(all_calendar_modifications)),
  FUN = function(elm) all_calendar_modifications[[elm]]$obsolete
  ))
to_update <- bind_rows(lapply(
  seq_len(length(all_calendar_modifications)),
  FUN = function(elm) all_calendar_modifications[[elm]]$to_update
  ))

## (I) UPDATE existing fwcal
# CASES:
# - if visit_done: do not change
# - if not visit_done: update and unset done_planning

update_fieldwork_calendar <- function(to_update) {

  really_update <- to_update %>%
    anti_join(prior_visits, by = join_by(fieldworkcalendar_id))

  if (nrow(really_update) == 0) {
    message("nothing to update.")
    return(invisible(NA))
  }

  not_updated_because_already_done <- to_update %>%
    anti_join(really_update, by = join_by(samplelocation_id, temp_idx)) %>%
    pull(fieldworkcalendar_id)

  if (0 < length(not_updated_because_already_done)) {
    ids_to_message <- paste0(not_updated_because_already_done, collapse = ", ")
    message(glue::glue(
      "fieldworkcalendar_id's not updated / prior visits found:
       .   {ids_to_message}"
      ))
  }


  get_update_row_string <- function(rownr) {
    # rownr = 1 # testing
    fwcal_id <- as.integer(really_update[rownr, "fieldworkcalendar_id"])

    prior_calendar <- previous_calendar_plans %>%
      filter(fieldworkcalendar_id == fwcal_id)
    common_columns <- really_update %>% names
    common_columns <- common_columns[
        common_columns %in% (prior_calendar %>% names)
      ]
    common_columns <- common_columns[
        !startsWith(common_columns, 'log_')
      ]

    if(FALSE) {
      # for debugging
      bind_rows(
        prior_calendar %>% select(!!!common_columns),
        really_update %>% select(!!!common_columns)
      ) %>% glimpse
    }

    if (0 <
      prior_calendar %>%
        semi_join(
          really_update,
          by = join_by(!!!common_columns)
        ) %>%
        nrow
      ) {
      message(glue::glue("no changes on fieldworkcalendar_id == {fwcal_id}"))
      return(invisible(NA))
    }

    # note: date_start was used for matching above.
    date_end <- format(really_update[rownr, "date_end"][[1]], "%Y-%m-%d")
    date_interval <- really_update[rownr, "date_interval"]
    priority <- really_update[rownr, "priority"]
    wait_watersurface <- toupper(sprintf("%s", really_update[rownr, "wait_watersurface"]))
    wait_3260 <- really_update[rownr, "wait_3260"]
    wait_7220 <- really_update[rownr, "wait_7220"]
    done_planning <- "FALSE"


    target_namestring <- '"outbound"."FieldworkCalendar"'
    update_string <- glue::glue("
      UPDATE {target_namestring}
        SET
         date_end = '{date_end}',
         date_interval = '{date_interval}',
         priority = {priority},
         wait_watersurface = {wait_watersurface},
         wait_3260 = {wait_3260},
         wait_7220 = {wait_7220},
         done_planning = {done_planning}
      WHERE fieldworkcalendar_id = {fwcal_id}
      ;
    ")

    return(update_string)
  }

  update_commands <- lapply(
    1:nrow(really_update),
    FUN = get_update_row_string
  )
  update_commands <- update_commands[!is.na(update_commands)]

  # execute the update commands.
  for (rownr in seq_len(length(update_commands))) {
    execute_sql(
      db_connection,
      update_commands[[rownr]],
      verbose = TRUE
    )
  }
}

glimpse(to_update)
update_fieldwork_calendar(to_update)


## (II) DELETE obsolete CASCADE

delete_obsolete_calendar_entries <- function(obsolete) {
  target_namestring <- '"outbound"."FieldworkCalendar"'
  ids_to_delete <- paste0(obsolete %>% pull(fieldworkcalendar_id), collapse = ',')

  # dependent tables must all be cleaned
  for (target_namestring in
       c(
         '"inbound"."ChemicalSamplingActivities"',
         '"inbound"."WellInstallationActivities"',
         '"inbound"."Visits"',
         '"outbound"."FieldworkCalendar"'
      )) {

    execute_sql(
      db_connection,
      glue::glue("DELETE FROM {target_namestring} WHERE fieldworkcalendar_id IN ({ids_to_delete});"),
      verbose = TRUE
    )
  }
}

glimpse(obsolete)
delete_obsolete_calendar_entries(obsolete)

## (III) INSERT to_upload

insert_new_fieldwork <- function(to_upload) {
  new_fieldwork_upload <- to_upload %>%
    select(
      -scheme_ps_targetpanels,
      -stratum,
      -grts_join_method,
      -grts_address_replacement,
      -temp_idx
    )


  sspstapas <- dplyr::tbl(
      db_connection,
      DBI::Id(schema = "metadata", table = "SSPSTaPas")
    ) %>% collect

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


  fieldwork_calendar_upload <- new_fieldwork_upload %>%
    replace_sspstapa_by_lookup()

  if (nrow(fieldwork_calendar_upload) > 0) {
    fieldwork_calendar_lookup <- update_cascade_lookup(
      schema = "outbound",
      table_key = "FieldworkCalendar",
      new_data = fieldwork_calendar_upload,
      index_columns = c("fieldworkcalendar_id"),
      characteristic_columns = fieldcalendar_characols,
      tabula_rasa = FALSE,
      verbose = TRUE
    )
    # fieldwork_calendar_upload %>%
    #   count(grts_address, samplelocation_id, sspstapa_id, activity_group_id, date_start)
  }

  ## append new visits

  locations_lookup <- dplyr::tbl(
      db_connection, DBI::Id("metadata", "Locations")
    ) %>%
    select(grts_address, location_id) %>%
    collect

  new_visits <- fieldwork_calendar_lookup %>%
    select(
      fieldworkcalendar_id,
      !!!fieldcalendar_characols
    ) %>%
    semi_join(
      fieldwork_calendar_upload,
      by = join_by(!!!fieldcalendar_characols)
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

  # visits_characols <- c("fieldworkcalendar_id", fieldcalendar_characols) # some fwcal_id were NULL at this point
  visits_characols <- fieldcalendar_characols

  visits_upload <- new_visits
  visits_upload %>% print(n=Inf)
  # visits_upload %>% count(fieldworkcalendar_id)


  # RECOVER / correct missing fieldworkcalendar_ids in "Visits"
  if (FALSE) {

    fieldwork_calendar_lookup <- dplyr::tbl(
        db_connection,
        DBI::Id(schema = "outbound", table = "FieldworkCalendar")
      ) %>%
      select(
        !!!c(fieldcalendar_characols, "fieldworkcalendar_id")
      ) %>%
      collect


    visits_existing <- dplyr::tbl(
      db_connection,
      DBI::Id(schema = "inbound", table = "Visits")
      ) %>% collect

    visits_to_recover <- visits_existing %>%
      filter(is.na(fieldworkcalendar_id)) %>%
      select(-fieldworkcalendar_id)

    recovered_visits <- visits_to_recover %>%
      left_join(
        fieldwork_calendar_lookup %>%
          select(samplelocation_id, activity_group_id, date_start, fieldworkcalendar_id),
        by = join_by(samplelocation_id, activity_group_id, date_start)
      ) %>%
      relocate(fieldworkcalendar_id) %>%
      select(-log_user, -log_update, -visit_id) %>%
      distinct()
      # %>% write.csv(glue::glue("dumps/recovering_visits.csv"), row.names = FALSE)

      execute_sql(
        db_connection,
        glue::glue('DELETE FROM "inbound"."Visits" WHERE fieldworkcalendar_id IS NULL;'),
        verbose = verbose
      )

      rs <- DBI::dbWriteTable(
        db_connection,
        DBI::Id(schema = "inbound", table = "Visits"),
        recovered_visits,
        overwrite = FALSE,
        append = TRUE
      )

     visits_upload <- visits_upload %>%
       anti_join(
          recovered_visits,
          by = join_by(
            fieldworkcalendar_id,
            samplelocation_id,
            grts_address,
            activity_group_id,
            date_start
          )
       )
  } # /RECOVER visits

  # NOTE 20250826 that the "new" visits to upload here already have
  # rows in the Visits table, which somehow lost link to FwCal

  if (nrow(visits_upload) > 0) {
    visits_lookup <- update_cascade_lookup(
      schema = "inbound",
      table_key = "Visits",
      new_data = visits_upload,
      index_columns = c("fieldworkcalendar_id", "visit_id"),
      characteristic_columns = visits_characols,
      tabula_rasa = FALSE,
      verbose = TRUE
    )
  } else {
    visits_lookup <- dplyr::tbl(
        db_connection,
        DBI::Id(schema = "inbound", table = "Visits")
      ) %>%
      select(
        !!!c(visits_characols, "fieldworkcalendar_id", "visit_id")
      ) %>%
      collect

  }

  ### fieldwork activity special tables

  visits_reload <- visits_upload %>%
    select(!!!visits_characols) %>%
    inner_join(
      visits_lookup,
      by = join_by(!!!visits_characols)
    ) %>%
    select(-sspstapa_id)

  fieldwork_charcols <- c(
      "samplelocation_id",
      "fieldworkcalendar_id",
      "visit_id",
      "grts_address",
      "activity_group_id",
      "date_start"
    )


  ## ---- WellInstallationActivities ---------------------------------------------

  activity_subset <- grouped_activities %>%
    filter(grepl("^GWINST", activity_group))

  wellinstallations <- visits_reload %>%
    semi_join(
      activity_subset,
      by = join_by(activity_group_id)
    )

  wellinstallations_upload <- wellinstallations %>%
    mutate(
      no_diver = FALSE,
      visit_done = FALSE,
      soilprofile_unclear = FALSE,
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    )

  if (nrow(wellinstallations_upload) > 0) {
    wellinstallation_lookup <- update_cascade_lookup(
      schema = "inbound",
      table_key = "WellInstallationActivities",
      new_data = wellinstallations_upload,
      index_columns = c("fieldwork_id"),
      characteristic_columns = fieldwork_charcols,
      skip_sequence_reset = TRUE,
      verbose = TRUE
    )
  }


  ## ---- ChemicalSamplingActivities ---------------------------------------------

  activity_subset <- grouped_activities %>%
    filter(activity_group %in%
      c(grouped_activities %>%
        filter(grepl("^GW.*SAMP", activity)) %>%
        pull(activity_group))
    )

  chemicalsamplings <- visits_reload %>%
    semi_join(
      activity_subset,
      by = join_by(activity_group_id)
    )

  chemicalsampling_upload <- chemicalsamplings %>%
    mutate(
      visit_done = FALSE,
      log_user = "maintenance",
      log_update = as.POSIXct(Sys.time())
    )


  if (nrow(chemicalsampling_upload) > 0) {
    chemicalsampling_lookup <- update_cascade_lookup(
      schema = "inbound",
      table_key = "ChemicalSamplingActivities",
      new_data = chemicalsampling_upload,
      index_columns = c("fieldwork_id"),
      characteristic_columns = fieldwork_charcols,
      skip_sequence_reset = TRUE,
      verbose = TRUE
    )
  }

} # /insert_new_fieldwork

to_upload %>% filter(grts_address == 871030) %>% knitr::kable()

glimpse(to_upload)
insert_new_fieldwork(to_upload)


# SELECT * FROM "outbound"."FieldworkCalendar" WHERE grts_address IN (1818369, 769793);
