## libraries -------------------------------------------------------------------
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")



## data consolidation functions ------------------------------------------------
# some general functions to enable data aggregation further down

non_na <- function(x){
  if (all(is.na(x))) {
    return(invisible(NA))
  } else {
    return(x[!is.na(x)])
  }
}

unique_non_na <- \(x) unique(non_na(x))



## database connection ---------------------------------------------------------
config_filepath <- file.path("./mnm_database_connection.conf")

suffix <- "-dev"
suffix <- ""

mnmsyncdb_mirror <- glue::glue("mnmsyncdb{suffix}")

mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsyncdb_mirror
)

message(glue::glue("connected: psql {mnmsyncdb$shellstring}"))
syncdb_update_cascade_lookup <- parametrize_cascaded_update(mnmsyncdb)


sourcedb_labels <- c("loceval", "mnmgwdb") #, mnmsurfdb)
sourcedb_connections <- list()

for (sdb in sourcedb_labels) {
  sourcedb_connections[[sdb]] <- connect_mnm_database(
    config_filepath = config_filepath,
    database = sdb,
    user = "monkey",
    password = NA
  )

}


## LocationInfos ---------------------------------------------------------------

locationinfos_statusquo <- mnmsyncdb$query_table("LocationInfos") %>%
  filter(FALSE) # select NO ROW -> just get the columns
  # select(
  #   grts_address,
  #   landowner,
  #   accessibility_inaccessible, accessibility_revisit,
  #   recovery_hints,
  #   watina_code_1,
  #   watina_code_2
  # )

### find overlap
# column-specific:
#   - accessibility_* is difficult
#   - recovery_hints must be merged
#   - gw::watina_code_* can be taken from mnmgwdb


for (sdb in sourcedb_labels) {
  # sdb <- "mnmgwdb"
  #
  db <- sourcedb_connections[[sdb]]

  locationinfos_eval <- db$query_table("LocationInfos") %>%
    mutate(
      log_origindb = sdb,
      accessibility_revisit = as.Date(accessibility_revisit)
    )

  locationinfos_statusquo <- bind_rows(
    locationinfos_statusquo,
    locationinfos_eval
  )

}


locationinfos_assembly <- locationinfos_statusquo %>%
  arrange(log_creation, log_update) %>%
  group_by(
    grts_address
  ) %>%
  summarize(
    n = n_distinct(log_origindb),
    landowner = stringr::str_c(unique_non_na(landowner), sep = "; "),
    accessibility_inaccessible = coalesce(any(accessibility_inaccessible), FALSE),
    log_creator = non_na(log_creator)[[1]],
    log_creation = min(as.POSIXct(unique_non_na(log_creation))),
    log_update = max(as.POSIXct(unique_non_na(log_update))),
    log_user = "sync",
    accessibility_revisit = min(as.Date(unique_non_na(accessibility_revisit))),
    recovery_hints = stringr::str_c(unique_non_na(recovery_hints), sep = "; "),
    watina_code_1 = stringr::str_c(unique_non_na(watina_code_1), sep = "; "),
    watina_code_2 = stringr::str_c(unique_non_na(watina_code_2), sep = "; "),
  ) %>%
  ungroup() %>%
  mutate(
    across(
      c(log_creator, log_user),
      ~tidyr::replace_na(.x, "unknown")
    )
  )


duplicate_count <- locationinfos_assembly %>%
  count(grts_address) %>%
  filter(n > 1) %>%
  arrange(desc(n))

if (nrow(duplicate_count) > 0) {
  duplicate_count %>% knitr::kable()
  stop("duplicate locationinfos")
}

locationinfos_upload <- locationinfos_assembly %>% select(-n)

syncdb_update_cascade_lookup(
  table_label = "LocationInfos",
  new_data = locationinfos_upload,
  index_columns = c("locationinfo_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

# NOTE 20260512: NOT using "distribution/redistribute" machinery
#      because the `precedence_columns` cause issues: they are to be updated
#      in the sync table despite their function as input
#
# table_label <- "LocationInfos"
# data_nouveau <- locationinfos_assembly %>% select(-n)
# index_column <- mnmsyncdb$get_primary_key(table_label)
# characteristic_columns <- c("grts_address")
#
# # NOTE: the input must come from the input databases; there is no precedence in this case
# distribution <- categorize_data_update(...)
# print_category_count(distribution, table_label)
#
# locationinfos_lookup <- redistribute_calendar_data(...)


## Done! -----------------------------------------------------------------------
message("")
message("________________________________________________________________")
message(" >>>>> Finished LocationInfos initial upload to SYNCDB. ")
message("________________________________________________________________")
