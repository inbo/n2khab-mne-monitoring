#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

## ----database-connection------------------------------------------------------
# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"

### connect to mnmgwdb
message(glue::glue(">>>>> MIRROR: mnmgwdb{suffix}"))
mnmgwdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("mnmgwdb{suffix}"),
  user = "monkey",
  password = NA
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
# message(mnmgwdb$shellstring)

rowcounts_mnmgwdb <- mnmgwdb$count_all_table_content(\(df) df %>% filter(!is_view))


### connect to locevaldb
message(glue::glue(">>>>> MIRROR: loceval{suffix}"))
locevaldb <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("loceval{suffix}"),
  user = "monkey",
  password = NA
)

rowcounts_loceval <- locevaldb$count_all_table_content(\(df) df %>% filter(!is_view))

bind_rows(rowcounts_loceval, rowcounts_mnmgwdb) %>% t() %>%
  as_tibble(rownames = "table", .name_repair = "minimal") %>%
  magrittr::set_colnames(c("table", "loceval", "gwdb")) %>%
  knitr::kable()

message("")
message("________________________________________________________________")
message(" >>>>> Finished counting table contents.")
message("________________________________________________________________")
