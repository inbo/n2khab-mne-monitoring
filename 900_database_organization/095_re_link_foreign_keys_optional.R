# libraries
source("MNMLibraryCollection.R")
# load_poc_common_libraries()
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


# library("mapview") # debugging only
# mapviewOptions(platform = "mapdeck")



config_filepath <- file.path("./inbopostgis_server.conf")

# mirror <- ""
mirror <- "-staging"

# ... and mnmgwdb
mnmgwdb_mirror <- glue::glue("mnmgwdb{mirror}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror
)

mnmgwdb$shellstring



# link FieldworkCalender back to SampleLocations
stitch_table_connection(
  mnmdb = mnmgwdb,
  table_label = "FieldworkCalendar",
  reference_table = "SampleLocations",
  link_key_column = "samplelocation_id",
  lookup_columns = c("grts_address", "stratum"),
  reference_mod = function(ref) ref %>% rename(stratum = strata)
)



# link Visits back to Locations
stitch_table_connection(
  mnmdb = mnmgwdb,
  table_label = "Visits",
  reference_table = "Locations",
  link_key_column = "location_id",
  lookup_columns = c("grts_address")
)


# link Visits back to SampleLocations
stitch_table_connection(
  mnmdb = mnmgwdb,
  table_label = "Visits",
  reference_table = "SampleLocations",
  link_key_column = "samplelocation_id",
  lookup_columns = c("grts_address", "stratum"),
  reference_mod = function(ref) ref %>% rename(stratum = strata)
)


# link Visits back to FieldworkCalendar
stitch_table_connection(
  mnmdb = mnmgwdb,
  table_label = "Visits",
  reference_table = "FieldworkCalendar",
  link_key_column = "fieldworkcalendar_id",
  lookup_columns = c("grts_address", "stratum", "activity_group_id", "date_start")
)


mnmgwdb$query_table("Visits") %>%
  count(is.na(samplelocation_id), is.na(fieldworkcalendar_id)) %>%
  knitr::kable()




for (table_label in c("WellInstallationActivities", "ChemicalSamplingActivities")) {

  # link WIA/CSA back to SampleLocations
  stitch_table_connection(
    mnmdb = mnmgwdb,
    table_label = table_label,
    reference_table = "SampleLocations",
    link_key_column = "samplelocation_id",
    lookup_columns = c("grts_address", "stratum"),
    reference_mod = function(ref) ref %>% rename(stratum = strata)
  )

  # link WIA/CSA back to FieldworkCalendar
  stitch_table_connection(
    mnmdb = mnmgwdb,
    table_label = table_label,
    reference_table = "FieldworkCalendar",
    link_key_column = "fieldworkcalendar_id",
    lookup_columns = c("grts_address", "stratum", "activity_group_id", "date_start")
  )

  # link WIA/CSA back to Visits
  stitch_table_connection(
    mnmdb = mnmgwdb,
    table_label = table_label,
    reference_table = "Visits",
    link_key_column = "visit_id",
    lookup_columns = c("grts_address", "stratum", "activity_group_id", "date_start")
  )


}


# TODO there are `new_location_id` and `new_samplelocation_id` in "archive"."ReplacementData"
