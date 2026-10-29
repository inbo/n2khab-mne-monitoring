#!/usr/bin/env Rscript

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

database <- "mnmsurfdb"
suffix <- "-staging"

mnmsurfdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("{database}{suffix}")
)

message(glue::glue("\tconnected: psql {mnmsurfdb$shellstring}"))

### download Visits - stepwise, raw

# db <- mnmsurfdb
# table_label <- "Visits"
# ONLY <- FALSE
# subselect <- NA

# # -> was an issue with `collect` used in `query_table_uncollected`

### download Visits -> issues at first

visits_original <- mnmsurfdb$query_table("Visits")
visits_original %>%
  select(visit_id, grts_address, stratums, sampleunit_ids, fieldcalendar_ids)


visits_original %>%
  select(visit_id, grts_address, stratums, sampleunit_ids, fieldcalendar_ids)

visits_original %>% filter(grts_address == 231150) %>% pull(stratums) %>% unlist()

# and upload!
visit_upload <- visits_original %>% filter(grts_address == 231150)  %>%
  mutate(
    grts_address = 1111111,
    notes = "TEST array types / FM",
  ) %>%
  select(-log_user, -log_update, -visit_id)

visit_upload %>%
  glimpse()

mnmsurfdb$insert_data(
  table_label = "Visits",
  upload_data = visit_upload
)

# SELECT visit_id, grts_address, date_start, activity_group_id, UNNEST(sampleunit_ids) AS su_id, UNNEST(fieldcalendar_ids) AS fc_id, UNNEST(stratums) AS stratum FROM "inbound"."Visits" WHERE grts_address = 1111111;

# DELETE FROM "inbound"."Visits" WHERE grts_address = 1111111;
