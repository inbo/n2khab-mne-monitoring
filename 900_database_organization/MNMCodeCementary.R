#!/usr/bin/env Rscript

# Too good to be thrown away. Yet.


#_______________________________________________________________________________
# SPATIAL DATA EXCEPTION

# convert a spatial data frame to tibble df by cbinding coords
sf_to_df_obsolete <- function(spatial_df, coord_names = NA) {
  # spatial_df <- prior_content
  # spatial_df <- old_data

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("sf" = require("sf"))

  if (is.na(coord_names)){
    coord_names <- c("x", "y")
  }

  df <- cbind(
    sf::st_drop_geometry(spatial_df),
    sf::st_coordinates(spatial_df) %>%
      as_tibble(.name_repair = "minimal") %>%
      setNames(coord_names)
   )

  return(df)
}

# convert a dataframe to spatial, please provide coords and crs!
df_to_sf_obsolete <- function(df, ...) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("sf" = require("sf"))

  spatial_df <- sf::st_as_sf(
    df,
    ... # coords, crs
  )

  return(spatial_df)
}


#_______________________________________________________________________________
# DATABASE STRUCTURE

# the first entry is the table itself
# find_dependent_tables("mnmgwdb_db_structure", "Visits")
obsolete_find_dependent_tables <- function(dbstructure_folder = "db_structure", table_key) {
  # dbstructure_folder <- "./mnmgwdb_db_structure"
  # table_key <- "Visits"

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, schema, geometry, excluded)

  ### (2) load current data
  excluded_tables <- schemas %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)

  table_relations <- read_table_relations_config(
    storage_filepath = here::here(dbstructure_folder, "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key),
      !(dependent_table %in% excluded_tables)
    )

  dependent_tables <- c(
    table_key,
    table_relations %>% pull(dependent_table)
    )

  create_dbi_identifier <- function(tabkey) {
    schema <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(schema)
    tkey_right <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(table)
    return(DBI::Id(schema, tkey_right))
  }

  table_ids <- lapply(dependent_tables, FUN = create_dbi_identifier)

  return(table_ids)

} # /find_dependent_tables


# store the content of a table in memory
obsolete_load_table_content <- function(
    db_connection,
    dbstructure_folder,
    table_id
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))

  is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, geometry) %>%
    filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
    pull(geometry) %>% is.na

  if (is_spatial) {
    data <- sf::st_read(db_connection, table_id) %>% collect
  } else {
    data <- dplyr::tbl(db_connection, table_id) %>% collect
  }

  return(list("id" = table_id, "data" = data))

} # /load_table_content


# push table from memory back to the server
obsolete_restore_table_data_from_memory <- function(
    db_target,
    content_list,
    dbstructure_folder = "db_structure",
    verbose = TRUE
  ) {
  # content_list <- table_content_storage[[3]]

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  table_id <- content_list$id
  table_key <- attr(table_id, "name")
  table_lable <- glue::glue('"{table_key[[1]]}"."{table_key[[2]]}"')
  table_data <- content_list$data


  if (is.scalar.na(table_data) || (nrow(table_data) < 1)) {
    message("no data to restore.")
    return(invisible(NA))
  }

  # restore data
  pk <- mnmdb$get_primary_key(table_key[[2]])

  # TODO need to branch geometry tables?
  # is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  #   select(table, geometry) %>%
  #   filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
  #   pull(geometry) %>% is.na

  # using dplyr/DBI to upload has the usual issues of deletion/restroation,
  # i.e. that user roles are not persistent.
  # Hence, the usual trick of "empty/append".

  # Note that I neglect dependent table here, since they will be re-uploaded after
  ## delete from table
  execute_sql(
    db_target,
    glue::glue("DELETE FROM {table_lable};"),
    verbose = verbose
  )

  ## reset the sequence
  sequence_key <- glue::glue('"{table_key[[1]]}".seq_{pk}')
  nextval_query <- glue::glue("SELECT last_value FROM {sequence_key};")

  current_highest <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]

  execute_sql(
    db_target,
    glue::glue('ALTER SEQUENCE {sequence_key} RESTART WITH 1;'),
    verbose = verbose
  )

  ## append the table data
  append_tabledata(db_target, table_id, table_data)

  ## restore sequence
  nextval <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]
  nextval <- max(c(nextval, current_highest, table_data %>% pull(pk)))

  execute_sql(
    db_target,
    glue::glue("SELECT setval('{sequence_key}', {nextval});"),
    verbose = verbose
  )

  return(invisible(NULL))

} # /restore_table_data_from_memory



dump_all_obsolete <- function() {
  # what wonce worked with all attributes,
  # now exploits the "beauty" and "simplicity" of the db$list.

  # # profile (section within the config file)
  # if (is.null(profile)) {
  #   profile <- 1 # use the first profile by default
  # }

  # read connection info from a config file,
  # unless user provided different credentials
  config <- configr::read.config(file = config_filepath)[[profile]]

  if (is.null(host)) {
    stopifnot("host" %in% attributes(config)$names)
    host <- config$host
  }

  if (is.null(port)) {
    if ("port" %in% attributes(config)$names) {
      port <- config$port
    } else {
      port <- 5439
    }
  }

  if (is.null(user)) {
    stopifnot("user" %in% attributes(config)$names)
    user <- config$user
  }

}

#_______________________________________________________________________________
# fieldwork calendar update procedure

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
      mnmgwdb$query_table("SSPSTaPas"),
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

# all_calendar_modifications <- lapply(
#   samplelocations,
#   FUN = classify_calendar_events
# )
#
# to_upload <- bind_rows(lapply(
#   seq_len(length(all_calendar_modifications)),
#   FUN = function(elm) all_calendar_modifications[[elm]]$to_upload
#   ))
# obsolete <- bind_rows(lapply(
#   seq_len(length(all_calendar_modifications)),
#   FUN = function(elm) all_calendar_modifications[[elm]]$obsolete
#   ))
# to_update <- bind_rows(lapply(
#   seq_len(length(all_calendar_modifications)),
#   FUN = function(elm) all_calendar_modifications[[elm]]$to_update
#   ))


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
    mnmgwdb$execute_sql(
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

    mnmgwdb$execute_sql(
      glue::glue("
        DELETE FROM {mnmgwdb$get_namestring(target_label)}
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


  sspstapas <- mnmgwdb$query_table("SSPSTaPas")

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

  locations_lookup <- mnmgwdb$query_columns(
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
    visits_lookup <- mnmgwdb$query_columns(
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
