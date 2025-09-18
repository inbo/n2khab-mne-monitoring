ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN stratum varchar DEFAULT NULL;
ALTER TABLE "inbound"."Visits" ADD COLUMN stratum varchar DEFAULT NULL;
ALTER TABLE "inbound"."WellInstallationActivities" ADD COLUMN stratum varchar DEFAULT NULL;
ALTER TABLE "inbound"."ChemicalSamplingActivities" ADD COLUMN stratum varchar DEFAULT NULL;


source("MNMLibraryCollection.R")
load_poc_common_libraries()
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


config_filepath <- file.path("./inbopostgis_server.conf")
mirror <- "-staging"


mnmgwdb_mirror <- glue::glue("mnmgwdb{mirror}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror
)

update_cascade_lookup <- parametrize_cascaded_update(mnmgwdb)


# get SampleLocations

#_______________________________________________________________________________
# 1: SAMPLE LOCATIONS
sample_locations <- mnmgwdb$query_table("SampleLocations")

sample_locations %>% distinct(strata) %>% print(n = Inf)
# strata %>%
#   left_join(
#     plans,
#     by = join_by(grts_address)
#   ) %>%
#   distinct(strata, activity_group_id, date_start) %>%
#   print(n = Inf)

flat_strata <- sample_locations %>%
  select(grts_address, strata) %>%
  distinct()

distinct_strata <- flat_strata %>%
  mutate(
    stratum = strsplit(as.character(strata), ", "),
  ) %>%
  mutate(
    first_stratum = unlist(map(stratum, first))
  ) %>%
  unnest(stratum) %>%
  mutate(
    first_stratum = (first_stratum == stratum)
  )

sample_locations_distribute <- sample_locations %>%
  left_join(
    distinct_strata,
    by = join_by(grts_address, strata)
  )

sample_locations_update <- sample_locations_distribute %>%
  filter(first_stratum) %>%
  select(-first_stratum, -strata) %>%
  rename(strata = stratum)

sample_locations_upload <- sample_locations_distribute %>%
  filter(!first_stratum) %>%
  select(-first_stratum, -samplelocation_id, -strata) %>%
  rename(strata = stratum) %>%
  relocate(strata)


# mnmgwdb$get_characteristic_columns("SampleLocations")
# sample_locations_update %>% count(grts_address) %>% arrange(desc(n))
# sample_locations_update %>% filter(grts_address == 871030) %>% knitr::kable()
# sample_locations_upload %>% filter(grts_address == 871030) %>% knitr::kable()
# sample_locations_update %>% filter(grts_address == 311342) %>% knitr::kable()

update_existing_data(
  mnmdb = mnmgwdb,
  table_label = "SampleLocations",
  changed_data = sample_locations_update,
  input_precedence_columns = precedence_columns[["SampleLocations"]],
  index_columns = c("samplelocation_id"),
  reference_columns = c("samplelocation_id", "grts_address")
)

append_tabledata(
  db_connection = mnmgwdb$connection,
  table_id = mnmgwdb$get_table_id("SampleLocations"),
  data_to_append = sample_locations_upload,
  characteristic_columns = c("grts_address", "strata"),
  verbose = TRUE
)

mnmgwdb$query_table("SampleLocations") %>%
  count(strata) %>%
  arrange(desc(n)) %>%
  knitr::kable()

#_______________________________________________________________________________
# 2: FIELDWORK CALENDAR


fieldwork_calendar <- mnmgwdb$query_table("FieldworkCalendar")

sloc_redownload <- mnmgwdb$query_table("SampleLocations")
sloc_lookup <- sample_locations_distribute %>%
  select(grts_address, stratum, first_stratum) %>%
  rename(strata = stratum) %>%
  left_join(
    sloc_redownload,
    by = join_by(grts_address, strata)
  ) %>%
  select(grts_address, strata, first_stratum, samplelocation_id)
# sloc_lookup %>% count(samplelocation_id) %>% arrange(desc(n))
# sloc_lookup %>% filter(grts_address == 311342) %>% t() %>% knitr::kable()
# sloc_redownload %>% filter(grts_address == 311342) %>% t() %>% knitr::kable()
# sample_locations_distribute %>% filter(grts_address == 311342) %>% t() %>% knitr::kable()


fieldwork_calendar_distribute <- fieldwork_calendar %>%
  select(-samplelocation_id) %>%
  left_join(
    sloc_lookup,
    by = join_by(grts_address),
    relationship = "many-to-many"
  ) %>%
  relocate(grts_address, activity_group_id, strata)

fwcal_update <- fieldwork_calendar_distribute %>%
  filter(first_stratum) %>%
  select(-first_stratum, -stratum) %>%
  rename(stratum = strata)

fwcal_upload <- fieldwork_calendar_distribute %>%
  filter(!first_stratum) %>%
  select(-first_stratum, -samplelocation_id, -stratum, -fieldworkcalendar_id) %>%
  rename(stratum = strata) %>%
  relocate(stratum)


update_existing_data(
  mnmdb = mnmgwdb,
  table_label = "FieldworkCalendar",
  changed_data = fwcal_update %>%
    select(
      fieldworkcalendar_id,
      grts_address,
      activity_group_id,
      date_start,
      stratum
    ),
  input_precedence_columns = precedence_columns[["FieldworkCalendar"]],
  index_columns = c("fieldworkcalendar_id"),
  reference_columns = c("fieldworkcalendar_id", "grts_address", "activity_group_id", "date_start")
)

append_tabledata(
  db_connection = mnmgwdb$connection,
  table_id = mnmgwdb$get_table_id("FieldworkCalendar"),
  data_to_append = fwcal_upload,
  characteristic_columns = c("grts_address", "activity_group_id", "date_start", "stratum"),
  verbose = TRUE
)

fwcal_lookup <- mnmgwdb$query_columns(
  "FieldworkCalendar",
  c("grts_address", "activity_group_id", "date_start", "stratum", "fieldworkcalendar_id")
)

mnmgwdb$query_table("FieldworkCalendar") %>%
  count(stratum) %>%
  arrange(desc(n)) %>%
  knitr::kable()


#_______________________________________________________________________________
# 3: VISITS



visits <- mnmgwdb$query_table("Visits")

visits_distribute <- visits %>%
  select(-samplelocation_id) %>%
  left_join(
    sloc_lookup,
    by = join_by(grts_address),
    relationship = "many-to-many"
  ) %>%
  relocate(grts_address, activity_group_id, strata)

visits_update <- visits_distribute %>%
  filter(first_stratum) %>%
  select(-first_stratum, -stratum) %>%
  rename(stratum = strata) %>%
  select(-fieldworkcalendar_id) %>%
  left_join(
    fwcal_lookup,
    by = join_by(grts_address, activity_group_id, date_start, stratum)
  ) %>%
  relocate(fieldworkcalendar_id)


visits_upload <- visits_distribute %>%
  filter(!first_stratum) %>%
  select(-first_stratum, -samplelocation_id, -stratum, -fieldworkcalendar_id, -visit_id) %>%
  rename(stratum = strata) %>%
  relocate(stratum) %>%
  left_join(
    fwcal_lookup,
    by = join_by(grts_address, activity_group_id, date_start, stratum)
  ) %>%
  relocate(fieldworkcalendar_id)



update_existing_data(
  mnmdb = mnmgwdb,
  table_label = "Visits",
  changed_data = visits_update %>%
    select(
      visit_id,
      fieldworkcalendar_id,
      grts_address,
      activity_group_id,
      date_start,
      stratum
    ),
  input_precedence_columns = precedence_columns[["Visits"]],
  index_columns = c("visit_id"),
  reference_columns = c("visit_id", "grts_address", "date_start", "activity_group_id")
)


append_tabledata(
  db_connection = mnmgwdb$connection,
  table_id = mnmgwdb$get_table_id("Visits"),
  data_to_append = visits_upload,
  characteristic_columns = c("grts_address", "activity_group_id", "date_start", "fieldworkcalendar_id", "stratum"),
  verbose = TRUE
)


mnmgwdb$query_table("Visits") %>%
  count(stratum) %>%
  arrange(desc(n)) %>%
  knitr::kable()


# DONE update scheme_ps_targetpanels, schemes, sspstapa_id
# DONE new visits?



#_______________________________________________________________________________
# 3: WIA/CSA

activity_subset <- mnmgwdb$query_table("GroupedActivities") %>%
  distinct(activity_group, activity_group_id) %>%
  filter(grepl("^GWINST", activity_group))


wellinstallations <- mnmgwdb$query_table("Visits") %>%
  semi_join(
    visits_upload,
    join_by(grts_address, activity_group_id, date_start, fieldworkcalendar_id)
  ) %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )

wellinstallations_upload <- wellinstallations %>%
  select(
    fieldworkcalendar_id,
    visit_id,
    grts_address,
    stratum,
    activity_group_id,
    date_start
  ) %>%
  mutate(
    no_diver = FALSE,
    soilprofile_unclear = FALSE,
    visit_done = FALSE,
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )


wellinstallation_lookup <- update_cascade_lookup(
  table_label = "WellInstallationActivities",
  new_data = wellinstallations_upload,
  index_columns = c("fieldwork_id"),
  characteristic_columns = c("grts_address", "activity_group_id", "date_start", "fieldworkcalendar_id"),
  skip_sequence_reset = TRUE,
  verbose = TRUE
)


table_label <- "WellInstallationActivities"
wia <- mnmgwdb$query_table(table_label) %>%
  filter(is.na(stratum)) %>%
  select(-stratum) %>%
  left_join(
    sample_locations_update %>%
      select(grts_address, strata),
    by = join_by(grts_address),
    relationship = "many-to-many"
  ) %>%
  rename(stratum = strata) %>%
  distinct(fieldwork_id, stratum)

update_existing_data(
  mnmdb = mnmgwdb,
  table_label = table_label,
  changed_data = wia,
  input_precedence_columns = precedence_columns[[table_label]],
  reference_columns = c("fieldwork_id")
)



activity_subset <- mnmgwdb$query_table("GroupedActivities") %>%
  distinct(activity_group, activity_group_id) %>%
  filter(grepl("^GW.*SAMP", activity_group))


chemicalsamplings <- mnmgwdb$query_table("Visits") %>%
  semi_join(
    visits_upload,
    join_by(grts_address, activity_group_id, date_start, fieldworkcalendar_id)
  ) %>%
  semi_join(
    activity_subset,
    by = join_by(activity_group_id)
  )

chemicalsamplings_upload <- chemicalsamplings %>%
  select(
    fieldworkcalendar_id,
    visit_id,
    grts_address,
    stratum,
    activity_group_id,
    date_start
  ) %>%
  mutate(
    visit_done = FALSE,
    log_user = "maintenance",
    log_update = as.POSIXct(Sys.time())
  )


chemicalsamplings_lookup <- update_cascade_lookup(
  table_label = "ChemicalSamplingActivities",
  new_data = chemicalsamplings_upload,
  index_columns = c("fieldwork_id"),
  characteristic_columns = c("grts_address", "activity_group_id", "date_start", "fieldworkcalendar_id"),
  skip_sequence_reset = TRUE,
  verbose = TRUE
)


table_label <- "ChemicalSamplingActivities"
wia <- mnmgwdb$query_table(table_label) %>%
  filter(is.na(stratum)) %>%
  select(-stratum) %>%
  left_join(
    sample_locations_update %>%
      select(grts_address, strata),
    by = join_by(grts_address),
    relationship = "many-to-many"
  ) %>%
  rename(stratum = strata) %>%
  distinct(fieldwork_id, stratum)

update_existing_data(
  mnmdb = mnmgwdb,
  table_label = table_label,
  changed_data = wia,
  input_precedence_columns = precedence_columns[[table_label]],
  reference_columns = c("fieldwork_id")
)
