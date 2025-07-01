
working_dbname <- "mnmfield_dev"
config_filepath <- file.path("./inbopostgis_server.conf")
connection_profile <- "mnmfield-dev"
dbstructure_folder <- "./mnmfield_dev_structure"


#_______________________________________________________________________________
####   Libraries   #############################################################

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
library("rprojroot")
library("keyring")

library("configr")
library("DBI")
library("RPostgres")
# library("mapview")
# mapviewOptions(platform = "mapdeck")

# you might want to run the following prior to sourcing/rendering this script:
# keyring::key_set("DBPassword", "db_user_password")


#_______________________________________________________________________________
####   POC   ###################################################################

# POC warning!
message(
  "This script assumes that the latest version of the POC RData is downloaded
  (see `110_update_POC.qmd`)."
)


poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)
source("050_snippet_selection.R")

# Load some custom GRTS functions
# source(file.path(projroot, "R/grts.R"))
# TODO: rebase once PR#5 gets merged
source(
  "/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R"
)


#_______________________________________________________________________________
####   Database   ##############################################################


source("MNMDatabaseToolbox.R")


db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  select(table, schema, geometry)

# These are clumsy, temporary, provisional helpers.
# But, hey, there will be time later.
get_schema <- function(tablelabel) {
  return(schemas %>%
    filter(table == tablelabel) %>%
    pull(schema)
  )
}
get_namestring <- function(tablelabel) glue::glue('"{get_schema(tablelabel)}"."{tablelabel}"')
get_tableid <- function(tablelabel) DBI::Id(schema = get_schema(tablelabel), table = tablelabel)


# a local database dump as safety backup
now <- format(Sys.time(), "%Y%m%d%H%M")
dump_all(
  here::here("dumps", glue::glue("safedump_{working_dbname}_{now}.sql")),
  config_filepath = config_filepath,
  database = working_dbname,
  profile = "dumpall",
  user = "monkey",
  exclude_schema = c("tiger", "public")
)


#_______________________________________________________________________________
####   Metadata   ##############################################################

## ----upload-teammembers-------------------------------------------------------
members <- read_csv(here::here("db_structure", "data_TeamMembers.csv"))

member_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "TeamMembers"),
  members,
  ref_cols = "username",
  index_col = "teammember_id"
)


## ----upload-protocols---------------------------------------------------------
protocols <- activities %>%
  select(protocol) %>%
  distinct() %>%
  arrange(protocol) %>%
  filter(!is.na(protocol)) %>%
  mutate(
    protocol_id = 1:n(),
    protocol = as.character(protocol),
    description = NA
  )

protocol_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "Protocols"),
  protocols,
  ref_cols = "protocol",
  index_col = "protocol_id"
)


## ----upload-grouped-activities------------------------------------------------

grouped_activities_upload <- grouped_activities %>%
  lookup_join(protocol_lookup, "protocol")

upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "GroupedActivities"),
  grouped_activities_upload,
  ref_cols = c(
    "activity_group",
    "activity",
    "activity_group_id",
    "activity_id"
  ),
  index_col = "grouped_activity_id"
)


## ----upload-n2khabtype--------------------------------------------------------

n2khab_types_upload <- bind_rows(
  as_tibble(list(
    type = c("gh"),
    typelevel = c("main_type"),
    main_type = c("gh")
  )),
  n2khab_types_expanded_properties
  )


n2khabtype_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "N2kHabTypes"),
  n2khab_types_upload,
  ref_cols = "type",
  index_col = "n2khabtype_id"
)


## ----upload-location-assessments----------------------------------------------
# load previous in preatorio work from another database

db_loceval <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  user = "monkey",
  password = NA
)

migrating_schema <- "outbound"
migrating_table_key <- "LocationAssessments"
migrating_table <- DBI::Id(schema = migrating_schema, table = migrating_table_key)

locationassessments_data <- dplyr::tbl(
    db_loceval,
    migrating_table
  ) %>%
  collect() # collecting is necessary to modify offline and to re-upload


### TODO Location Assessments: re-link locations
# append_tabledata(
#   db_connection,
#   migrating_table,
#   locationassessments_data
# )
