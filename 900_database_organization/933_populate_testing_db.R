# DO NOT MODIFY
# this file is "tangled" automatically from `930_copy_database.org`.

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")
# keyring::key_set("DBPassword", "db_user_password")

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

# choose database via the command line
commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  database_label <- commandline_args[1]
} else {
  stop("please provide a database label as command line argument, e.g. 'loceval'.")
}
# database_label <- "loceval"
# database_label <- "mnmgwdb"
stopifnot(database_label %in% c("loceval", "mnmgwdb", "mnmsurfdb"))

source_mirror <- glue::glue("{database_label}") # -staging
target_mirror <- glue::glue("{database_label}-testing")

message(glue::glue("copying `{source_mirror}` to `{target_mirror}`."))

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

  ## infer characteristic columns
  characteristic_columns <- target_db$get_characteristic_columns(table_label)

  if (is.scalar.na(characteristic_columns)) {
    # just take all columns
    characteristic_columns <- names(new_data)
  }

  # if all else fails (e.g. LocationCells), use the target columns
  if (length(characteristic_columns) == 0) {
    # pk <- target_db$get_primary_key(table_label)
    # characteristic_columns <- c(pk)
    characteristic_columns <-
      target_db$load_table_info(table_label) %>%
      pull(column)
    # print(characteristic_columns)
  }

  # fix characteristic columns of `ReplacementArchives`
  if (table_label == "ReplacementArchives") {
    characteristic_columns <- c(
      characteristic_columns,
      "version_id"
    )
  }

  # # fix crs of table
  # if (target_db$is_spatial(table_label)) {
  #   new_data <- new_data %>% sf::st_as_sf(crs = 31370)

  #   # sf::st_crs(new_data) <- 31370
  #   sf::st_geometry(new_data) <- "wkb_geometry"
  # }

  # push the update
  upload_data_and_update_dependencies(
    mnmdb = target_db,
    table_label = table_label,
    data_replacement = new_data,
    characteristic_columns = characteristic_columns,
    verbose = FALSE,
    ...
  )

} # /copy_over_single_table

table_list_file <- file.path(glue::glue("{source_db$folder}/TABLES.csv"))
table_list <- read.csv(table_list_file)

process_db_table_copy <- function(table_idx) {

  table_label <- table_list[[table_idx, "table"]]
  # table_label <- "LocationCells"
  # table_idx <- table_list %>% mutate(table_idx = seq_len(nrow(table_list))) %>% filter(table == table_label) %>% pull(table_idx)

  table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1
  if (table_exclusion) return()

  print(glue::glue("processing {table_idx} / {nrow(table_list)}: {target_db$get_namestring(table_label)}"))

  # download
  source_data <- source_db$query_table(table_label, ONLY = TRUE)

  # modify
  if (table_label %in% names(table_modification)){
    new_data <- table_modification[[table_label]](source_data)
  } else {
    # ... unless there is nothing to modify
    new_data <- source_data
  }

  copy_over_single_table(
    table_label,
    new_data
    #, skip_sequence_reset = TRUE
  )

} # /process_db_table_copy

#_______________________________________________________________________________
# Finally, COPY ALL DATA


invisible(lapply(seq_len(nrow(table_list)), FUN = process_db_table_copy))
