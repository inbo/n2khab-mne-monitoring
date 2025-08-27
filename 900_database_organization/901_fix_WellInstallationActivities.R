
library("dplyr")
library("DBI")
library("tidyr")
library("glue")
library("keyring")

source("MNMDatabaseToolbox.R")

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


### connect to databases
db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


grouped_activities <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "metadata", table = "GroupedActivities")
  ) %>% collect
activity_subset <- grouped_activities %>%
  filter(grepl("^GWINST", activity_group))


### fieldwork activity special tables
recovery_characols <- c(
  "samplelocation_id",
  "grts_address",
  "activity_group_id",
  "date_start"
)
lookup_columns <- c(
  "visit_id",
  "fieldworkcalendar_id"
)


visits_lookup <- dplyr::tbl(
    db_connection,
    DBI::Id("inbound", "Visits")
  ) %>%
  select(!!!c(recovery_characols, lookup_columns)) %>%
  distinct() %>%
  collect()
check <- visits_lookup %>%
  count(!!!rlang::syms(recovery_characols)) %>%
  filter(n > 1)

stopifnot(nrow(check) == 0)


## ---- WellInstallationActivities ---------------------------------------------

activity_subset <- grouped_activities %>%
  filter(grepl("^GWINST", activity_group))

wellinstallations_lookup <- visits_lookup %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )

wellinstallations_existing <- dplyr::tbl(
    db_connection,
    DBI::Id("inbound", "WellInstallationActivities")
  ) %>%
  filter(is.na(fieldworkcalendar_id) || is.na(visit_id)) %>%
  select(!!!c(recovery_characols, "fieldwork_id")) %>%
  collect()

wellinstallations_restore <- wellinstallations_lookup %>%
  inner_join(
    wellinstallations_existing,
    by = join_by(!!!recovery_characols),
    relationship = "one-to-many"
  )

# df <- wellinstallations_restore
convert_all_to_strings <- function(df) {
  dtypes <- sapply(df, class)
  dnames <- names(df)

  df_mod <- df %>% mutate(across(everything(), as.character))

  datecols <- dnames[dtypes == "Date"]
  for (dcol in datecols) {
    df_mod[dcol] <- sapply(df_mod[dcol], function(val) glue::glue("'{val}'"))
  }

  return(df_mod)

}

collapse_sql_string <- function (namedvec, collapse_symbol = ", ") paste0(
    sapply(
      seq_len(length(namedvec)),
      FUN = function(i) glue::glue("{names(namedvec)[[i]]} = {namedvec[[i]]}")
    ),
    collapse = collapse_symbol
  )

create_recovery_update_string <- function(target_table, filters, values) {
  # example:
  # target_table <- '"inbound"."WellInstallationActivities"'
  # values <- c("visit_id" = "1079", "fieldworkcalendar_id" = "100")
  # filters <- c(
  #   "samplelocdation_id" = "358",
  #   "grts_addres" = "1542626",
  #   "activity_group_id" = "4",
  #   "date_start" = "'2025-10-01'"
  #   )

  value_string <- collapse_sql_string(
    values,
    collapse_symbol = ", "
  )

  filter_string <- collapse_sql_string(
    filters,
    collapse_symbol = ") AND ("
  )

  update_string <- glue::glue("
    UPDATE {target_table}
      SET {value_string}
    WHERE ({filter_string})
    ;
  ")

  return(update_string)
}


# i <- 1
# target_table <- '"inbound"."WellInstallationActivities"'
# update_table <- wellinstallations_restore
recover_table_by_update_lookup <- function(target_table, update_table, keycols, valcols) {
  # keycols <- c("fieldwork_id")
  # valcols <- c("visit_id", "fieldworkcalendar_id")

  update_table_str <- convert_all_to_strings(update_table)

  update_strings <- lapply(
    seq_len(nrow(update_table_str)),
    FUN = function(i) create_recovery_update_string(
      target_table = target_table,
      filters = update_table_str[i, keycols],
      values = update_table_str[i, valcols]
    )
  )

  message(glue::glue("updating {nrow(update_table_str)} rows from {target_table}..."))
  for (upstr in update_strings) {
    execute_sql(db_connection, upstr, verbose = FALSE)
  }
  message(glue::glue("done updating {target_table}."))

}


recover_table_by_update_lookup(
  target_table = '"inbound"."WellInstallationActivities"',
  update_table = wellinstallations_restore,
  keycols = c("fieldwork_id"),
  valcols = c("visit_id", "fieldworkcalendar_id")
)

## ---- ChemicalSamplingActivities ---------------------------------------------

activity_subset <- grouped_activities %>%
  filter(activity_group %in%
    c(grouped_activities %>%
      filter(grepl("^GW.*SAMP", activity)) %>%
      pull(activity_group)
    )
  )
# grouped_activities %>% filter(activity_group_id == 13) %>% t() %>% knitr::kable()

chemicalsamplings_lookup <- visits_lookup %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )

chemicalsamplings_existing <- dplyr::tbl(
    db_connection,
    DBI::Id("inbound", "ChemicalSamplingActivities")
  ) %>%
  filter(is.na(fieldworkcalendar_id) || is.na(visit_id)) %>%
  select(!!!c(recovery_characols, "fieldwork_id")) %>%
  collect()

chemicalsamplings_restore <- chemicalsamplings_lookup %>%
  inner_join(
    chemicalsamplings_existing,
    by = join_by(!!!recovery_characols),
    relationship = "one-to-many"
  )


recover_table_by_update_lookup(
  target_table = '"inbound"."ChemicalSamplingActivities"',
  update_table = chemicalsamplings_restore,
  keycols = c("fieldwork_id"),
  valcols = c("visit_id", "fieldworkcalendar_id")
)


invisible('
SELECT *
FROM "inbound"."WellInstallationActivities" AS WIA
LEFT JOIN "archive"."ReplacementData" AS RDATA
  ON RDATA.grts_address = WIA.grts_address
WHERE TRUE
  AND WIA.fieldworkcalendar_id IS NULL
  AND RDATA.grts_address_replacement IS NULL
;
-- SELECT * FROM "inbound"."WellInstallationActivities" WHERE fieldworkcalendar_id IS NULL AND NOT visit_done AND teammember_id IS NULL;
-- SELECT DISTINCT grts_address FROM "inbound"."WellInstallationActivities" WHERE fieldworkcalendar_id IS NULL AND NOT visit_done AND teammember_id IS NOT NULL;
  SELECT *
  FROM "inbound"."WellInstallationActivities"
  WHERE fieldworkcalendar_id IS NULL
    AND (teammember_id IS NULL)
    AND (date_visit IS NULL)
    AND (photo_soil_1_peilbuis IS NULL)
    AND (photo_soil_2_piezometer IS NULL)
    AND (photo_well IS NULL)
    AND (watina_code_used_1_peilbuis IS NULL)
    AND (watina_code_used_2_piezometer IS NULL)
    AND (soilprofile_notes IS NULL)
    AND (soilprofile_unclear IS NULL OR (NOT soilprofile_unclear))
    AND (random_point_number IS NULL)
    AND (no_diver IS NULL OR (NOT no_diver))
    AND (diver_id IS NULL)
    AND (free_diver IS NULL)
    AND (NOT visit_done)
  ;


SELECT *
FROM "inbound"."ChemicalSamplingActivities" AS CSA
LEFT JOIN "archive"."ReplacementData" AS RDATA
  ON RDATA.grts_address = CSA.grts_address
WHERE TRUE
  AND CSA.fieldworkcalendar_id IS NULL
  AND RDATA.grts_address_replacement IS NULL
;
-- SELECT * FROM "inbound"."ChemicalSamplingActivities" WHERE fieldworkcalendar_id IS NULL AND NOT visit_done;



')
