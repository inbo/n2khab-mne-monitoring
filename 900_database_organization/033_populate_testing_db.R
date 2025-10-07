# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# database_label <- "loceval"
database_label <- "mnmgwdb"

source_mirror <- glue::glue("{database_label}") # -staging
target_mirror <- glue::glue("{database_label}-testing")


# from source...
source_db <- connect_mnm_database(
  config_filepath,
  database_mirror = source_mirror,
  user = "monkey",
  password = NA
)
# source_db$shellstring


# ... to target
target_db <- connect_mnm_database(
  config_filepath,
  database_mirror = target_mirror
)
# target_db$shellstring

# TODO limitation: we should leave the primary and foreign keys unchanged!

#_______________________________________________________________________________
### define functions here to modify the data!
# modification is "on the go":
#   each of these functions should receive exactly one data frame,
#   just to give exactly one back.
sort_protocols <- function(prt) {
  prt <- prt %>% dplyr::arrange(dplyr::desc(protocol_code), dplyr::desc(protocol_version))
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

  table_label <- table_list[[table_idx, "table"]]
  # table_label <- "ReplacementCells"

  # print(table_list[[table_idx, "excluded"]])
  table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1
  if (table_exclusion) return()

  print(glue::glue("processing {table_idx} / {nrow(table_list)}: {target_db$get_namestring(table_label)}"))

  # download
  source_data <- source_db$query_table(table_label)

  # modify
  if (table_label %in% names(table_modification)){
    new_data <- table_modification[[table_label]](source_data)
  } else {
    # ... unless there is nothing to modify
    new_data <- source_data
  }

  copy_over_single_table(table_label, new_data)

}

#_______________________________________________________________________________
# Finally, COPY ALL DATA


invisible(lapply(seq_len(nrow(table_list)), FUN = process_db_table_copy))
