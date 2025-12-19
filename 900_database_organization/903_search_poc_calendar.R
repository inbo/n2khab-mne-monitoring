#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# source("MNMDatabaseConnection.R")
# source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")


# database_label <- "mnmgwdb"
# suffix <- "staging"

## ----poc-data-----------------------------------------------------------------
# re-load POC data
load_poc_common_libraries()
load_poc_rdata(reload = FALSE, to_env = globalenv())

# ... and code snippets.
snippets_path <- rprojroot::find_root(rprojroot::is_git_root)
load_poc_code_snippets(snippets_path)

verify_poc_objects()


fieldwork_calendar <-
  fieldwork_shortterm_prioritization_by_stratum %>%
  common_current_calenderfilters() %>% # should be filtered already!
  rename_grts_address_final_to_grts_address()

fieldwork_calendar %>%
  filter(
    grts_address %in% c(1205598, 41313630)
  ) %>%
  select(
    grts_address, stratum, priority,
    field_activity_group, date_start
  ) %>%
  arrange(
    grts_address, stratum, priority,
    date_start, field_activity_group
  ) %>%
  knitr::kable()



opvolging <- data.frame(
  grts_replaced = rep(NA, 8),
  grts_original = rep(NA, 8),
  type = rep("", 8),
  stringsAsFactors = FALSE
)

opvolging[1,] <- list(41313630,  1205598, "6150_hus")
opvolging[2,] <- list(23091910,    23238, "91E0_vm")
opvolging[3,] <- list( 4772254,  4772254, "9190")
opvolging[4,] <- list(13688242, 13688242, "9130_fm")
opvolging[5,] <- list( 7069106,  7069106, "9130_fm")
opvolging[6,] <- list(53206450, 53206450, "9130_fm")
opvolging[7,] <- list(19914421,  5234357, "1310_pol")
opvolging[8,] <- list( 3554997, 29769397, "1310_pol")
