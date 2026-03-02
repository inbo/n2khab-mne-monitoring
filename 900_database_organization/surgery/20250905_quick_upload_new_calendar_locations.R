
# libraries
source("MNMLibraryCollection.R")
load_poc_common_libraries()
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


load_poc_rdata(reload = FALSE, to_env = parent.frame())



snippets_path <- "/data/git/n2khab-mne-monitoring_support"
load_poc_code_snippets(snippets_path)


verify_poc_objects()



config_filepath <- file.path("./inbopostgis_server.conf")

mnmdb_mirror <- "mnmgwdb-staging"

mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmdb_mirror
)


locations_existing <- mnmdb$query_table("Locations") %>%
  mutate_at(
    vars(grts_address),
    as.integer
  )
locations_existing %>% head(3) %>% t() %>% knitr::kable()

# cases:
#   (  A¬B ( A&B )  B¬A ) ¬A¬B
#
# tables:
# - Locations
# |  Schema  |            Name            | Type  | Owner
# |----------+----------------------------+-------+-------
# | metadata | N2kHabStrata               | table | falk
# | metadata | Locations                  | table | falk
# | metadata | LocationCells              | table | falk
# | metadata | SSPSTaPas                  | table | falk
# | outbound | SampleLocations            | table | falk
# | outbound | FieldworkCalendar          | table | falk
# | inbound  | Visits                     | table | falk
# | inbound  | ChemicalSamplingActivities | table | falk
# | inbound  | WellInstallationActivities | table | falk

# from other scripts:
# | outbound | LocationInfos              | table | falk
# | outbound | MHQPolygons                | table | falk
# | outbound | RandomPoints               | table | falk
# | archive  | ReplacementData            | table | falk
# | outbound | CellMaps                   | table | falk
# | metadata | Coordinates                | table | falk

# irrelevant/unchanged
# | metadata | TeamMembers                | table | falk
# | metadata | GroupedActivities          | table | falk
# | metadata | Protocols                  | table | falk
# | outbound | LocationEvaluations        | table | falk
# | outbound | Divers                     | table | falk
# | inbound  | FreeFieldNotes             | table | falk
