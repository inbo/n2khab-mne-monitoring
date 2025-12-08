#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# These replacements are injected to `loceval`, then transferred to `mnmgwdb`
database_label <- "loceval"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}

### connect to database
locevaldb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(locevaldb$shellstring)


update_cascade_lookup <- parametrize_cascaded_update(locevaldb)

#_______________________________________________________________________________

load_poc_common_libraries()

tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()
load_poc_rdata(reload = FALSE, to_env = parent.frame())
message(glue::glue("Good morning!
  Loading the POC data took {tic(toc)} seconds today."
))


snippets_path <- "/data/git/n2khab-mne-monitoring_support"

toc <- Sys.time()
load_poc_code_snippets(snippets_path)
message(glue::glue(
  "... loading/executing the code snippets took {tic(toc)}s."
))

verify_poc_objects()


#_______________________________________________________________________________

replacement_characols <- c(
    "grts_address",
    "type",
    "grts_address_replacement",
    "replacement_rank"
  )
# rank may not be included in sideloading,
#   otherwise anti join with existing data will logical fault:
#   want to exclude sideloaded even if they exist on a different rank number

# load the rows to sideload
replacements_to_sideload <- load_table_sideload_content(
  mnmdb = locevaldb,
  table_label = "Replacements",
  characteristic_columns = c("grts_address", "type", "grts_address_replacement"),
  data_filepath = "sideload/loceval_replacements.csv"
)

replacements_to_sideload %>% t() %>% knitr::kable()


# join sampleunit_id
sampleunits_lookup <- locevaldb$query_columns(
    "SampleUnits", c("grts_address", "type", "sampleunit_id")
  )
# sampleunits_lookup %>% filter(grts_address == 1205598)

replacements_new <- replacements_to_sideload %>%
  inner_join(
    sampleunits_lookup,
    by = join_by(type, grts_address),
    relationship = "many-to-many", # TODO
    unmatched = "drop"
  )


# add coordinates, based on GRTS
replacements_upload <- replacements_new %>%
  add_point_coords_grts(
    grts_var = "grts_address_replacement",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(replacements_upload) <- "wkb_geometry"

# Upload!
replacements_lookup <- update_cascade_lookup(
  table_label = "Replacements",
  new_data = replacements_upload,
  index_columns = c("replacement_id"),
  characteristic_columns = replacement_characols,
  tabula_rasa = FALSE, # !!!
  verbose = TRUE
)
