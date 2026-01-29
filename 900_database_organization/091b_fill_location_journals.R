#!/usr/bin/Rscript

# TODO in case we get to more than two databases,
#      create a central place to store infos
#      and check against that.

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

todays_date <- strftime(as.POSIXct(Sys.time()), "%Y%m%d%H%M%S")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"

mnmgwdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("mnmgwdb{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmgwdb$shellstring)

locevaldb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("loceval{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(locevaldb$shellstring)

#_______________________________________________________________________________
### local replacement conversion

local_replacement_lookup <- mnmgwdb$query_columns(
    "ReplacementData",
    c("grts_address", "type", "grts_address_replacement")
  ) %>%
  rename(grts_address_original = grts_address) %>%
  distinct()


# grts local replacement (1): loceval to mnmgwdb
replacements_to_mnmgwdb <- function(df) {
  df %>%
    left_join(
      local_replacement_lookup,
      by = join_by(
        grts_address == grts_address_original,
        type == type
      )
    ) %>%
    mutate(
      grts_address = coalesce(grts_address_replacement, grts_address)
    ) %>%
    select(-grts_address_replacement) %>%
    return()

}

# grts local replacement (1b): loceval split-up
split_replacements <- function(df) {

  replacements <- bind_rows(
    local_replacement_lookup %>%
      select(grts_address_original, type) %>%
      mutate(grts_address_replacement = grts_address_original) %>%
      mutate(type_is_absent_j = TRUE),
    local_replacement_lookup %>%
      select(grts_address_replacement, type, grts_address_original) %>%
      mutate(type_is_absent_j = FALSE)
  )

  df %>%
    left_join(
      replacements,
      by = join_by(
        grts_address == grts_address_original,
        type == type
      )
    ) %>%
    mutate(
      grts_address = coalesce(grts_address_replacement, grts_address),
      type_is_absent = coalesce(type_is_absent_j, type_is_absent)
    ) %>%
    select(-grts_address_replacement, -type_is_absent_j) %>%
    return()

}


# grts local replacement (2): mnmgwdb to loceval
replacements_to_loceval <- function(df) {

  # special case: column "strata" in "SampleLocations"
  rename_strata <- "strata" %in% names(df)
  if (rename_strata) {
    df <- df %>% rename(stratum = strata)
  }

  df <- df %>%
    left_join(
      local_replacement_lookup %>%
      rename(stratum = type),
      by = join_by(
        grts_address == grts_address_replacement,
        stratum == stratum
      )
    ) %>%
    mutate(
      grts_address = coalesce(grts_address_original, grts_address)
    ) %>%
    select(-grts_address_original)

  # revert rename
  if (rename_strata) {
    df <- df %>% rename(strata = stratum)
  }
  return(df)

}


# test <- locevaldb$query_table("SampleUnits") %>%
#   sf::st_drop_geometry()
# replacements_to_mnmgwdb(test) %>%
#     filter(grts_address %in% c(23238, 6314694, 23091910)) %>%
#     head(5) %>%
#     knitr::kable()

# test <- mnmgwdb$query_table("SampleLocations") %>%
#   sf::st_drop_geometry()
# replacements_to_loceval(test) %>%
#     filter(grts_address %in% c(23238, 6314694, 23091910)) %>%
#     head(5) %>%
#     knitr::kable()


#_______________________________________________________________________________
### Installation Removals (sideload)

# # e.g.
# 15595153 -> WBYP030X -> vandalism 2025-12-19
# 366225 -> WBYP031X -> survived
# 27584145 -> WBYP032X -> vandalism 2025-12-19

installation_removals <- read.csv2(
    file.path("sideload", "vandalism.csv"),
    sep = ","
  ) %>%
  mutate_at(vars(is_planned, is_vandalism), as.logical) %>%
  mutate_at(vars(date), as.Date)

prior_removals <- mnmgwdb$query_table("InstallationRemovals")

new_installation_removals <- installation_removals %>%
  anti_join(
    prior_removals,
    by = join_by(grts_address, date)
  )

removal_lookup <- upload_and_lookup(
  mnmdb = mnmgwdb,
  table_label = "InstallationRemovals",
  data_to_append = new_installation_removals,
  characteristic_columns = c("grts_address", "date"),
  index_columns = "installationremoval_id",
  verbose = TRUE
)

if (nrow(new_installation_removals) > 0) {
  message(glue::glue("Registered {nrow(new_installation_removals)} new installation removals."))
}


#_______________________________________________________________________________
### Data Sources

## location evaluations
load_location_evaluations <- function() {

  locevals <- locevaldb$query_table("Visits") %>%
    filter(visit_done) %>%
    left_join(
      locevaldb$query_columns(
        "SampleUnits",
        c("grts_address", "type", "is_replaced", "type_is_absent")
      ),
      by = join_by(grts_address, type)
    ) %>%
    split_replacements() %>%
    select(
      grts_address,
      date = date_visit,
      activity_group_id,
      type_subset = type,
      loceval_type = type_assessed,
      loceval_replacement = is_replaced,
      loceval_type_absence = type_is_absent
    ) %>%
    mutate(source = "loceval") %>%
    group_by(
      grts_address,
      date,
      source,
      activity_group_id,
      loceval_replacement,
      loceval_type_absence,
      loceval_type
    ) %>%
    reframe(type_subset = stringr::str_c(type_subset, collapse = ",")) %>%
    arrange(date, grts_address)

  no_dates <- locevals %>%
    filter(is.na(date))

  if (nrow(no_dates) > 0) {
    grtsses <- no_dates %>% pull(grts_address) %>% paste0(collapse = "+")
    message(glue::glue("ERROR: date missing on loceval for {grtsses}"))
  }

  locevals <- locevals %>%
    filter(!is.na(date))

  return(locevals)

}

## installation removals
load_installation_removals <- function() {
  removals <- mnmgwdb$query_table("InstallationRemovals") %>%
    select(
      grts_address,
      date,
      is_planned,
      is_vandalism
    ) %>%
    mutate(
      removal_unplanned = (!is_planned) | is_vandalism,
      source = "removal"
    ) %>%
    select(-is_planned, -is_vandalism)

  return(removals)
}

## groundwater work
load_mnmgwdb_visits <- function() {
  gw_visits <- mnmgwdb$query_table("Visits") %>%
    filter(visit_done) %>%
    select(
      grts_address,
      type_subset = stratum,
      date = date_visit,
      activity_group_id,
      issues,
    ) %>%
    mutate(source = "gwdb") %>%
    group_by(
      grts_address,
      date,
      source,
      activity_group_id,
      issues
    ) %>%
    reframe(type_subset = stringr::str_c(type_subset, collapse = ",")) %>%
    arrange(date, grts_address)

  no_dates <- gw_visits %>%
    filter(is.na(date))

  if (nrow(no_dates) > 0) {
    grtsses <- no_dates %>% pull(grts_address) %>% paste0(collapse = "+")
    message(glue::glue("ERROR: date missing on gw activity for {grtsses}"))
  }

  gw_visits <- gw_visits %>%
    filter(!is.na(date))

  return(gw_visits)
}


## join all data sources
location_journals <- bind_rows(
    load_location_evaluations(),
    load_installation_removals(),
    load_mnmgwdb_visits()
  ) %>%
  arrange(date, grts_address, source)


#_______________________________________________________________________________
### Upload and Update Data

# mnmdb <- mnmgwdb
# mnmdb <- locevaldb
upload_LoJos <- function(mnmdb) {

  # join location ID
  location_lookup <- mnmdb$query_columns(
    "Locations",
    c("grts_address", "location_id")
  )


  lojos_prep <- location_journals

  # if (db_is_loceval) {
  #   lojos_prep <- replacements_to_loceval(lojos_prep)
  # }

  lojos <- lojos_prep %>%
    anti_join(
      mnmgwdb$query_table("LocationJournals"),
      by = join_by(date, grts_address, source)
    ) %>%
    left_join(
      location_lookup,
      by = join_by(grts_address)
    )

  upload_and_lookup(
    mnmdb = mnmdb,
    table_label = "LocationJournals",
    data_to_append = lojos,
    characteristic_columns =
      c("grts_address", "date", "source", "activity_group_id"),
    index_columns = "locationjournal_id",
    verbose = TRUE
  )

  if (nrow(lojos) > 0) {
    message(glue::glue("Registered {nrow(lojos)} new journal entries for {mnmdb$database}."))
    lojos %>% knitr::kable()
  }


  # updates

  stitch_table_connection(
    mnmdb = mnmdb,
    table_label = "LocationJournals",
    reference_table = "Locations",
    link_key_column = "location_id",
    lookup_columns = c("grts_address")
  )


  # update "is_latest" via sql `update from`
  table_path <- '"outbound"."LocationJournals"'


  category_command <- glue::glue("
    UPDATE {table_path} AS TRGTAB
    SET
      category = SRCTAB.category
    FROM (
      SELECT
        locationjournal_id,
        CASE
          WHEN
            (source = 'removal') OR
            (source = 'gwdb' AND activity_group_id = 4)
            THEN 'inst'
          WHEN
            (source = 'mhq') OR
            (source = 'loceval' AND activity_group_id = 18)
            THEN 'biot'
          ELSE source
        END AS category
      FROM {table_path}
    ) AS SRCTAB
    WHERE TRGTAB.locationjournal_id = SRCTAB.locationjournal_id
    ;
  ")

  mnmdb$execute_sql(category_command, verbose = FALSE)


  update_command <- glue::glue("
    UPDATE {table_path} AS TRGTAB
    SET
      is_latest = SRCTAB.is_latest
    FROM (
    SELECT locationjournal_id,
      date = (
        MAX(date) OVER (
          PARTITION BY grts_address, category
      )) AS is_latest
    FROM {table_path}
    ) AS SRCTAB
    WHERE TRGTAB.locationjournal_id = SRCTAB.locationjournal_id
    ;
  ")

  mnmdb$execute_sql(update_command, verbose = FALSE)

  ## update `visit_id` for quick linkage
  table_label <- "LocationJournals"
  reference_table <- "Visits"
  trgtab <- mnmdb$get_namestring(table_label)
  srctab <- mnmdb$get_namestring(reference_table)

  # first, reset visit_id
  mnmdb$execute_sql(
    glue::glue("UPDATE {trgtab} SET visit_id = NULL;"),
    verbose = FALSE
  )


  # REJECTED: visit_id link to Visits
  # update_string <- glue::glue("
  # UPDATE {trgtab} AS TRGTAB
  #   SET
  #     visit_id = SRCTAB.visit_id
  #   FROM {srctab} AS SRCTAB
  #   WHERE
  #    ({srctab}.grts_address = {trgtab}.grts_address)
  #    AND ({srctab}.activity_group_id = {trgtab}.activity_group_id)
  #    AND ({srctab}.date_visit = {trgtab}.date)
  # ;")


}


# loceval
upload_LoJos(locevaldb)

# mnmgwdb
upload_LoJos(mnmgwdb)
