#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

config_filepath <- file.path("./inbopostgis_server.conf")


#



database_label <- "mnmgwdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
suffix <- "-staging"


message("________________________________________________________________")
message(glue::glue(" <<<<< Transferring `loceval{suffix}` to `mnmgwdb{suffix}`. "))


### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(mnmgwdb$shellstring)


loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### load loceval local replacements
#///////////////////////////////////////////////////////////////////////////////


if (FALSE) {
  # ☇ monkey permissions
  stitch_table_connection(
    mnmdb = loceval_connection,
    table_label = "Replacements",
    reference_table = "SampleUnits",
    link_key_column = "sampleunit_id",
    lookup_columns = c("grts_address", "type"),
  )
} else {
  system(glue::glue("Rscript 095_re_link_foreign_keys_optional.R {suffix}"))
}

# TODO I should re-link
replacements_raw <- loceval_connection$query_table("Replacements") %>%
  filter(is_selected, !is_inappropriate) %>%
  select(
    grts_address,
    type,
    sampleunit_id,
    grts_address_replacement,
    replacement_rank,
    notes,
    wkb_geometry
  )

replacement_data <- replacements_raw %>%
  inner_join(
    loceval_connection$query_table("Locations"),
    by = join_by(grts_address),
    suffix = c("_repl", "_loc")
  ) %>%
  left_join(
    loceval_connection$query_table("SampleUnits"),
    by = join_by(grts_address, type),
    suffix = c("", "_unit")
  )

# NOTE: this still has both geometries



#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### prepare locations
#///////////////////////////////////////////////////////////////////////////////

existing_locations <- mnmgwdb$query_table("Locations")

new_locations <- replacement_data %>%
  anti_join(
    existing_locations,
    by = join_by(grts_address_replacement == grts_address)
  )


# message("")
# message("________________________________________________________________")
# message(" >>>>> Finished transferring loceval -> mnmgwdb. ")
# message("________________________________________________________________")
