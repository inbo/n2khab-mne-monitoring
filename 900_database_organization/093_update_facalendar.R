
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# TODO this does not yet work for `loceval` (based on SampleLocations)
database_label <- "mnmgwdb"

testing <- TRUE
if (testing) {
  suffix <- "-staging" # "-testing"
} else {
  suffix <- ""
  keyring::key_set("DBPassword", "db_user_password") # <- for source database

}


### connect to database
mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
message(mnmdb$shellstring)

## ----poc-data-----------------------------------------------------------------
# re-load POC data
load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())

# ... and code snippets.
snippets_path <- "/data/git/n2khab-mne-monitoring_support"
load_poc_code_snippets(snippets_path)

verify_poc_objects()


## ----update-propagate-lookup--------------------------------------------------
# just a convenience function to pass arguments to recursive update

update_cascade_lookup <- parametrize_cascaded_update(mnmdb)


### query true activity calendar

# TODO anti-join to find missing slocs
samplelocations_lookup <- mnmdb$query_columns(
    table_label = "SampleLocations",
    select_columns = c("samplelocation_id", "grts_address")
  )


grouped_activities <- mnmdb$query_table("GroupedActivities")


gw_field_activities <- grouped_activities %>%
  filter(is_gw_activity, is_field_activity) %>%
  distinct(activity_group)

activity_groupid_lookup <- mnmdb$query_columns(
    table_label = "GroupedActivities",
    select_columns = c("activity_group", "activity_group_id")
  ) %>% distinct()


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

fieldwork_calendar_raw <-
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
  sspstapas_values <- fieldwork_calendar_raw %>%
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
      mnmdb$query_table("SSPSTaPas"),
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

# fieldwork_calendar_raw %>%
#   filter(grts_address == 23238)
# fieldwork_2025_prioritization_by_stratum %>%
#   filter(grts_address == 23238) %>%
#   select(stratum, field_activity_group, rank, priority, date_interval, scheme_ps_targetpanels)


# check errors in the sample units
if(FALSE) {
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

previous_calendar_plans <- mnmdb$query_table("FieldworkCalendar") %>%
  left_join(
    mnmdb$query_table("SSPSTaPas"),
    by = join_by(sspstapa_id)
  ) %>%
  relocate(stratum_scheme_ps_targetpanels, .after = sspstapa_id) %>%
  select(-sspstapa_id)

# glimpse(previous_calendar_plans)

# previous_calendar_plans %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()

### select only replaced locations
replacements <- mnmdb$query_table("ReplacementData") %>%
  rename(c("stratum" = "type"))

# replacements %>%
#   filter(grts_address_replacement == 871030)
# fieldwork_calendar_raw %>%
#   filter(grts_address == 84598, activity_group_id == 4) %>%
#   t() %>% knitr::kable()
# --> NOT fine here -> coupled to wrong stratum
# replacements %>% filter(grts_address_replacement == 871030) %>% t() %>% knitr::kable()

fieldwork_calendar <- fieldwork_calendar_raw %>%
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


### find calendar entries which are not in the calendar any more
# example *was*:
# fieldwork_calendar %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()
# previous_calendar_plans %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()

obsolete_nonplans <- previous_calendar_plans %>%
  filter(!done_planning) %>%
  semi_join(
    replacements %>%
      select(-grts_address) %>%
      rename(
        grts_address = grts_address_replacement,
        samplelocation_id = new_samplelocation_id
      ),
    by = join_by(grts_address, samplelocation_id)
  ) %>%
  anti_join(
    fieldwork_calendar,
    by = join_by(
      samplelocation_id,
      grts_address,
      activity_group_id,
      date_start
    )
  )

if (nrow(obsolete_nonplans) > 0) {
  message(glue::glue(">>> The following {nrow(obsolete_nonplans)} plans have become obsolete prior to execution; they will be deleted:"))
  obsolete_nonplans %>% t() %>% knitr::kable()
}

# TODO remove `stratum_scheme_ps_targetpanels` on switch to SampleUnits

sspstapas <- update_cascade_lookup(
  table_label = "SSPSTaPas",
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
    "sspstapa_id",
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
    log_user %in% c("update", "maintenance", mnmdb$user),
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


prior_visits <- mnmdb$query_table("Visits") %>%
  filter(visit_done) %>%
  select(fieldworkcalendar_id)

# prior_visits %>% filter(!is.na(fieldworkcalendar_id))

# mnmdb$query_table("FieldworkCalendar") %>% head(2) %>% t() %>% knitr::kable()
# mnmdb$query_table("FieldworkCalendar") %>%
#   filter(is.na(samplelocation_id))
# mnmdb$query_table("FieldworkCalendar") %>%
#   filter(is.na(sspstapa_id))
#
# mnmdb$query_table("FieldworkCalendar") %>%
#   filter(is.na(fieldworkcalendar_id)) %>%
#   select(visit_id, samplelocation_id, fieldworkcalendar_id)
# mnmdb$query_table("Visits") %>%
#   filter(is.na(fieldworkcalendar_id)) %>%
#   select(visit_id, samplelocation_id, fieldworkcalendar_id)


# prior_visits %>% filter(fieldworkcalendar_id %in% c(1161, 1201))

### TODO loop
# testing
# replacements %>% filter(grts_address == 769793)
# sloc <- fieldwork_calendar %>% filter(grts_address == 23238) %>% pull(samplelocation_id) %>% unique
# sloc <- fieldwork_calendar %>% filter(grts_address == 253621) %>% pull(samplelocation_id) %>% unique
# and a great example:
# sloc <- fieldwork_calendar %>% filter(grts_address == 1818369) %>% pull(samplelocation_id) %>% unique
# sloc = 860 # potential duplicate 20250821
# # real duplicate 20250827 -> grts 871030 (repl for 84598; only FA on 7150 and none on 4010)
# sloc <- fieldwork_calendar %>% filter(grts_address == 871030) %>% pull(samplelocation_id) %>% unique
# fieldwork_calendar %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()

# sloc <- 857

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

# to_upload %>%
#   filter(grts_address == 871030) %>%
#   t() %>% knitr::kable()
# --> no duplicate yet

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
    mnmdb$execute_sql(
      update_commands[[rownr]],
      verbose = TRUE
    )
  }
}

glimpse(to_update)
# to_update %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
update_fieldwork_calendar(to_update)


## (II) DELETE obsolete CASCADE

delete_obsolete_calendar_entries <- function(obsolete) {
  target_namestring <- '"outbound"."FieldworkCalendar"'
  ids_to_delete <- paste0(
    obsolete %>%
    pull(fieldworkcalendar_id),
    collapse = ','
  )

  # dependent tables must all be cleaned
  for (target_label in
       c(
         "ChemicalSamplingActivities",
         "WellInstallationActivities",
         "Visits",
         "FieldworkCalendar"
      )) {

    message(ids_to_delete)
    if ((length(ids_to_delete) == 0) || (ids_to_delete == "")) next

    mnmdb$execute_sql(
      glue::glue("
        DELETE FROM {mnmdb$get_namestring(target_label)}
        WHERE fieldworkcalendar_id IN ({ids_to_delete});
        "),
      verbose = TRUE
    )
  }
}

glimpse(obsolete)
# obsolete %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()
delete_obsolete_calendar_entries(obsolete)

# also delete the ones which were never planned, from above:
delete_obsolete_calendar_entries(obsolete_nonplans)
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
  # new_fieldwork_upload %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()


  sspstapas <- mnmdb$query_table("SSPSTaPas")

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
  # fieldwork_calendar_upload %>% filter(grts_address == 871030) %>% t() %>% knitr::kable()

  if (nrow(fieldwork_calendar_upload) > 0) {
    fieldwork_calendar_lookup <- update_cascade_lookup(
      table_label = "FieldworkCalendar",
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

  locations_lookup <- mnmdb$query_columns(
      table_label = "Locations",
      select_columns = c("grts_address", "location_id")
    )

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
  visits_characols <- c(fieldcalendar_characols, "fieldworkcalendar_id")

  visits_upload <- new_visits
  visits_upload %>% print(n=Inf)
  # visits_upload %>% count(fieldworkcalendar_id)



  # NOTE 20250826 that the "new" visits to upload here already have
  # rows in the Visits table, which somehow lost link to FwCal

  if (nrow(visits_upload) > 0) {
    visits_lookup <- update_cascade_lookup(
      table_label = "Visits",
      new_data = visits_upload,
      index_columns = c("visit_id"), # "fieldworkcalendar_id",
      characteristic_columns = visits_characols,
      tabula_rasa = FALSE,
      verbose = TRUE
    )
  } else {
    visits_lookup <- mnmdb$query_columns(
        table_label = "Visits",
        select_columns = c(visits_characols, "fieldworkcalendar_id", "visit_id")
      )

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
      table_label = "WellInstallationActivities",
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
      table_label = "ChemicalSamplingActivities",
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
# insert_new_fieldwork(to_upload)
insert_new_fieldwork(to_upload %>% select(-domain_part))


# SELECT * FROM "outbound"."FieldworkCalendar" WHERE grts_address IN (1818369, 769793);

message("________________________________________________________________")
message("  Finished. Make sure to inspect the log.  ")
message("________________________________________________________________")


# RECOVER / correct missing fieldworkcalendar_ids in "Visits"
if (TRUE) {

  fieldwork_calendar_lookup <- mnmdb$query_columns(
    table_label = "FieldworkCalendar",
    select_columns = c(fieldcalendar_characols, "fieldworkcalendar_id")
    )

  visits_existing <- mnmdb$query_table("Visits")

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

    mnmdb$execute_sql(
      glue::glue('DELETE FROM "inbound"."Visits" WHERE fieldworkcalendar_id IS NULL;'),
      verbose = TRUE
    )

    mnmdb$insert_data(
      table_label = "Visits",
      upload_data = recovered_visits
    )

# SELECT * FROM "inbound"."Visits" WHERE fieldworkcalendar_id IS NULL;

} # /RECOVER visits
