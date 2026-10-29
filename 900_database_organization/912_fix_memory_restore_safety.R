#!usr/bin/env Rscript


# There was an issue in the processing routine
# which broke the crash safety routine
# related to `datetime_visit` which would have the `00:00:00.+12UTC` substring


source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


config_filepath <- file.path("./mnm_database_connection.conf")
# suffix <- ""
suffix <- "-staging"
# suffix <- "-testing"

# connect mnmsurfdb
mnmsurfdb_mirror <- glue::glue("mnmsurfdb{suffix}")

mnmsurfdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmsurfdb_mirror
)

# keyring::keyring_delete(keyring = "mnmdb_temp")
message(glue::glue("connected: psql {mnmsurfdb$shellstring}"))
update_cascade_lookup <- parametrize_cascaded_update(mnmsurfdb)


### issue 1: problem with datetime data type
# fixed by explicit string cast prior to collect()

visits <- mnmsurfdb$query_table("Visits")

visits %>% distinct(datetime_visit) %>% knitr::kable()

test <- mnmsurfdb$query_table_uncollected("Visits", ONLY = FALSE, subselect = c("visit_id", "datetime_visit"))

test %>% distinct(datetime_visit) %>% glimpse()

if ("datetime_visit" %in% colnames(test)) {
  test <- test %>%
    mutate(
      datetime_visit = dbplyr::sql("to_char(datetime_visit, 'YYYY-MM-DD HH24:MI:SS.FF3')")
    )
}


test_collected <- test %>% collect()
test_collected %>% distinct(datetime_visit) %>% knitr::kable()


### issue 2: tbd


db_store <- mnmsurfdb$store_table_deptree_in_memory("Locations")

mnmsurfdb$restore_table_data_from_memory(db_store, verbose = TRUE)
