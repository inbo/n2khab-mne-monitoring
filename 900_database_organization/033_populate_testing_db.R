# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# database_label <- "mnmgwdb"
database_label <- "loceval"
source_mirror <- glue::glue("{database_label}")
target_mirror <- glue::glue("{database_label}-dev")


# from source...
source_db <- connect_mnm_database(
  config_filepath,
  database_mirror = source_mirror,
  user = "monkey",
  password = NA
)


# ... to target
target_db <- connect_mnm_database(
  config_filepath,
  database_mirror = target_mirror
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

copy_over_single_table <- function(table_label, new_data, ...) {
  # parametrization of the `upload_data_and_update_dependencies` functions
  # just to make the loop code below look a little less convoluted.

  # push the update
  upload_data_and_update_dependencies(
    target_db,
    table_label = table_label,
    data_replacement = new_data,
    verbose = FALSE,
    ...
  )

}

table_list_file <- file.path(glue::glue("{source_db$folder}/TABLES.csv"))
table_list <- read.csv(table_list_file)

process_db_table_copy <- function(table_idx) {

  table_schema <- table_list[[table_idx, "schema"]]
  table_label <- table_list[[table_idx, "table"]]
  table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1

  # print(table_list[[table_idx, "excluded"]])

  if (table_exclusion) return()

  print(glue::glue("processing {table_schema}.{table_label}"))

  # download
  source_data <- source_db$query_table(table_label)

  # modify
  if (table_label %in% names(table_modification)){
    source_data <- table_modification[[table_label]](source_data)
  }

  copy_over_single_table(table_label, source_data)

}

# TODO due to ON DELETE SET NULL from "Locations", location_id's temporarily become NULL.
#      Updating would be cumbersome.
constraints_mod <- function(do = c("DROP", "SET")){

  toggle_null_constraint <- function(schema, table_label, column){
    # {dis/en}able fk for these tables
    target_db$execute_sql(
      glue::glue('ALTER TABLE "{schema}"."{table_label}" ALTER COLUMN {column} {do} NOT NULL;'),
      verbose = FALSE
    ) # /sql
  } # /toggle_mod


  if (database_label == "loceval") {
    # To prevent failure, I temporarily remove the constraint.
    for (table_label in c("LocationAssessments", "SampleUnits", "LocationInfos")){
      toggle_null_constraint("outbound", table_label, "location_id")
    } # /loop

    toggle_null_constraint("inbound", "Visits", "location_id")
    toggle_null_constraint("outbound", "ReplacementCells", "replacement_id")
  }

  if (database_label == "mnmgwdb") {
    # To prevent failure, I temporarily remove the constraint.
    for (table_label in c("SampleLocations", "LocationInfos")){
      toggle_null_constraint("outbound", table_label, "location_id")
    } # /loop

    toggle_null_constraint("inbound", "Visits", "location_id")
  }

} #/constraints_mod

#_______________________________________________________________________________
# Finally, COPY ALL DATA

constraints_mod("DROP")

invisible(lapply(seq_len(nrow(table_list)), FUN = process_db_table_copy))

constraints_mod("SET")
