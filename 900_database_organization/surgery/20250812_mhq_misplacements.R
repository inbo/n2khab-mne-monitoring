library("dplyr")
library("tidyr")
library("stringr")
library("purrr")
library("lubridate")
library("sf")
library("terra")
library("n2khab")
library("googledrive")
library("readr")
library("glue")
library("rprojroot")
library("keyring")
library("spbal")

library("configr")
library("DBI")
library("RPostgres")

library("mapview")
# mapviewOptions(platform = "mapdeck")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")

# testing
working_dbname <- "mnmgwdb"
connection_profile <- "mnmgwdb"
# working_dbname <- "mnmgwdb_testing"
# connection_profile <- "mnmgwdb-testing"


config <- configr::read.config(file = config_filepath)[[connection_profile]]
source("MNMDatabaseToolbox.R")

# database connection
db_connection <- connect_database_configfile(
  config_filepath,
  database = "mnmgwdb",
  profile = "dumpall",
  password = NA
)


if (TRUE){
### info from POC
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R")

poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)

invisible(capture.output(source("050_snippet_selection.R")))
source("051_snippet_transformation_code.R")
}

assessment_lookup <- bind_rows(
    fag_stratum_grts_calendar %>%
      distinct(grts_address_final, assessed_in_field) %>%
      setNames(c("grts_address", "assessed")),
    stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
      distinct(grts_address_final, last_type_assessment_in_field) %>%
      setNames(c("grts_address", "assessed"))
  ) %>%
  mutate_at(
    vars(grts_address),
    as.character
  )


visits <- dplyr::tbl(db_connection, DBI::Id("inbound", "Visits")) %>%
  filter(visit_done, activity_group_id == 4) %>%
  collect

sample_locations <- dplyr::tbl(
  db_connection,
  DBI::Id("outbound", "SampleLocations")
  ) %>%
  collect

locations_forest_visited <- sf::st_read(
  db_connection,
  DBI::Id("metadata", "Locations")
  ) %>%
  select(-ogc_fid) %>%
  collect %>%
  inner_join(
    sample_locations %>% select(-grts_address),
    by = join_by(location_id)
  ) %>%
  mutate(
    is_forest = stringr::str_detect(strata, "^9|^2180|^rbbppm")
  ) %>%
  filter(is_forest) %>%
  semi_join(
    visits,
    by = join_by(grts_address)
  ) %>%
  mutate_at(
    vars(grts_address),
    as.character
  )


locations_forest_visited_assessed <-
  locations_forest_visited %>%
  semi_join(
    assessment_lookup %>% filter(assessed),
    by = join_by(grts_address)
  )

knitr::kable(t(locations_forest_visited_assessed))
