
library("dplyr")
library("configr")
library("DBI")
library("RPostgres")


config_filepath <- file.path("./inbopostgis_server.conf")

# config <- configr::read.config(file = config_filepath)[[connection_profile]]
source("MNMDatabaseToolbox.R")


# to query latest data from loceval
loceval_connection <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  password = NA
)

# the ofo view combines
#
# "outbound"."LocationAssessments" AS LOCASS
# "metadata"."Locations" AS LOC
# "outbound"."SampleUnits" AS UNIT
#
# ... and joins them via ID or grts (+type)
# the type comes from UNIT

locations <- dplyr::tbl(
  loceval_connection,
  DBI::Id(schema = "metadata", table = "Locations")
) %>% collect
location_assessments <- dplyr::tbl(
  loceval_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments")
) %>% collect
sample_units <- dplyr::tbl(
  loceval_connection,
  DBI::Id(schema = "outbound", table = "SampleUnits")
) %>% collect

location_assessments %>% anti_join(
    sample_units,
    by = join_by(grts_address)
  ) %>%
  select(location_id, grts_address, type, assessment_done) %>%
  knitr::kable()

sample_units %>% anti_join(
    location_assessments,
    by = join_by(grts_address)
  ) %>%
  select(location_id, grts_address, type, assessment_done) %>%
  knitr::kable()
