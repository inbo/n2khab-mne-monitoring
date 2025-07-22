# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

library("dplyr")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password") # <- for source database

# database_label <- "mnmgwdb"
database_label <- "loceval"
target_mirror <- "staging"

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")
dbstructure_folder <- glue::glue("{database_label}_dev_structure")

# from source...
source_db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = database_label,
  user = "monkey",
  password = NA
)

# ... to target
target_db_name <- glue::glue("{database_label}_testing")
target_connection_profile <- glue::glue("{database_label}-testing")
target_db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = target_connection_profile
)

# TODO limitation: we should leave the primary and foreign keys unchanged!

#_______________________________________________________________________________
### define functions here to modify the data!
# modification is "on the go":
#   each of these functions should receive exactly one data frame,
#   just to give exactly one back.
sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
  return(prt)
}

rename_FieldActivityCalendar <- function(fac) {
  fac <- fac %>% dplyr::rename(accessibility_revisit = acceccibility_revisit)
  return(fac)
}

#_______________________________________________________________________________
### associate the functions with table names

table_modification <- c(
  "Protocols" = function (prt) sort_protocols(prt) # (almost) anything you like
  # "FieldActivityCalendar" = function (fac) rename_FieldActivityCalendar(fac) # (almost) anything you like
)

#_______________________________________________________________________________

copy_over_single_table <- function(table_key, new_data) {
  # just to make the loop code below look a little less convoluted.

  # push the update
  update_datatable_and_dependent_keys(
    config_filepath = config_filepath,
    working_dbname = target_db_name,
    table_key = table_key,
    new_data = new_data,
    profile = target_connection_profile,
    dbstructure_folder = dbstructure_folder,
    db_connection = target_db_connection,
    verbose = FALSE
  )

}

table_list_file <- file.path(glue::glue("{dbstructure_folder}/TABLES.csv"))
table_list <- read.csv(table_list_file)

process_db_table_copy <- function(table_idx){

  table_schema <- table_list[[table_idx, "schema"]]
  table_key <- table_list[[table_idx, "table"]]
  table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1

  print(table_list[[table_idx, "excluded"]])

  if (table_exclusion) return()

  print(glue::glue("processing {table_schema}.{table_key}"))

  # download
  source_data <- dplyr::tbl(
      source_db_connection,
      DBI::Id(schema = table_schema, table = table_key)
    ) %>%
    collect() # collecting is necessary to modify offline and to re-upload

  # modify
  if (table_key %in% names(table_modification)){
    source_data <- table_modification[[table_key]](source_data)
  }

  copy_over_single_table(table_key, source_data)

}

# TODO due to ON DELETE SET NULL from "Locations", location_id's temporarily become NULL.
#      Updating would be cumbersome.
constraints_mod <- function(do = c("DROP", "SET")){

  toggle_null_constraint <- function(schema, table_key, column){
    # {dis/en}able fk for these tables
    execute_sql(
      target_db_connection,
      glue::glue('ALTER TABLE "{schema}"."{table_key}" ALTER COLUMN {column} {do} NOT NULL;'),
      verbose = FALSE
    ) # /sql
  } # /toggle_mod


  if (database_label == "loceval") {
    # To prevent failure, I temporarily remove the constraint. # , "LocationInfos"
    for (table_key in c("LocationAssessments", "SampleUnits")){
      toggle_null_constraint("outbound", table_key, "location_id")
    } # /loop

    toggle_null_constraint("inbound", "Visits", "location_id")
    toggle_null_constraint("outbound", "ReplacementCells", "replacement_id")
  }

  if (database_label == "mnmgwdb") {
    # To prevent failure, I temporarily remove the constraint.
    for (table_key in c("SampleLocations", "LocationInfos")){
      toggle_null_constraint("outbound", table_key, "location_id")
    } # /loop

    toggle_null_constraint("inbound", "Visits", "location_id")
  }

} #/constraints_mod

#_______________________________________________________________________________
# Finally, COPY ALL DATA

constraints_mod("DROP")

invisible(lapply(1:nrow(table_list), FUN = process_db_table_copy))

constraints_mod("SET")
