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


## location journals -----------------------------------------------------------
# append-only: use distinct union set

# NOTE: the primary upload of LoJos to syncdb
#       is handled in script `112_fill_location_journals.R`


locationjournals_statusquo <- mnmsyncdb$query_table("LocationJournals") %>%
  filter(FALSE) # select NO ROW -> just get the columns

### find overlap
# column-specific:
#   - accessibility_* is difficult
#   - recovery_hints must be merged
#   - gw::watina_code_* can be taken from mnmgwdb


for (sdb in sourcedb_labels) {
  # sdb <- "mnmgwdb"

  db <- sourcedb_connections[[sdb]]

  locationjournals_eval <- db$query_table("LocationJournals") %>%
    mutate(
      log_origindb = sdb,
    )

  locationjournals_statusquo <- bind_rows(
    locationjournals_statusquo,
    locationjournals_eval
  )

}


# locationjournals_statusquo %>% glimpse()# distinct(log_origindb, source)

locationjournals_consolidated <- locationjournals_statusquo %>%
  distinct(
    grts_address,
    date,
    source,
    type_subset,
    activity_group_id,
    loceval_type,
    loceval_replacement,
    loceval_type_absence,
    issues,
    removal_unplanned,
    category,
    is_latest
  #   location_id
  )

locationjournals_consolidated %>%
  count(
    grts_address,
    date,
    source,
    type_subset,
    activity_group_id
  ) %>%
  filter(n > 1) %>%
  # filter(grts_address == 826486) %>%
  inner_join(locationjournals_statusquo) %>%
  knitr::kable()

##  SELECT *
##  FROM "outbound"."LocationJournals"
##  WHERE grts_address = 826486
##    AND date = '2025-08-01'
##    AND type_subset = '6230_hmo'
##    AND activity_group_id = 18
##  ;


## Done! -----------------------------------------------------------------------
message("")
message("________________________________________________________________")
message(" >>>>> Finished LocationJournals initial upload to SYNCDB. ")
message("________________________________________________________________")
