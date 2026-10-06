#!usr/bin/env Rscript


# + only take explicit negatives with date_loceval > date_visit_planned
# + then update =excluded= and =excluded_reason=
# + but also update =fieldcalendar_ids= of =Visits=



source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


config_filepath <- file.path("./mnm_database_connection.conf")
# suffix <- ""
suffix <- "-staging"
# suffix <- "-testing"


# select database
# database_label <- "mnmgwdb"
database_label <- "mnmsurfdb"


# connect mnmdb
mnmdb_mirror <- glue::glue("{database_label}{suffix}")

mnmdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmdb_mirror
)

# keyring::keyring_delete(keyring = "mnmdb_temp")
message(glue::glue("connected: psql {mnmdb$shellstring}"))


## loceval: explicit disapprovals
'
SELECT
  grts_address,
  type,
  date_start,
  type_assessed,
  eval_source,
  eval_name,
  log_user,
  eval_date,
  log_update,
  type_is_absent,
  CASE WHEN (type_is_absent IS NULL) OR (type_is_absent IS FALSE) THEN
    CASE WHEN (type_assessed IS NULL) OR (type_assessed = type)
    THEN FALSE ELSE TRUE END
  ELSE TRUE
  END AS loceval_disapproval
FROM "transfer"."LocationEvaluations"
;
'

# Attention: using a FAKE missing data imputation
transfer_loceval <- mnmdb$query_table("LocationEvaluations") %>%
  dplyr::mutate(
    type_is_absent = dplyr::coalesce(type_is_absent, FALSE),
    type_assessed = dplyr::coalesce(type_assessed, type),
    loceval_disapproval = type_is_absent | (type_assessed != type)
  )

disapproval_units <- transfer_loceval %>%
  filter(loceval_disapproval)

disapproval_units %>%
  filter(type_is_absent, type == type_assessed) %>%
  glimpse()


'
WITH EVA AS (
SELECT
  grts_address,
  type,
  date_start,
  type_assessed,
  eval_source,
  eval_name,
  log_user,
  eval_date,
  log_update,
  type_is_absent,
  CASE WHEN (type_assessed IS NOT NULL)
    THEN type_is_absent AND (type_assessed = type)
  ELSE FALSE
  END AS loceval_inconsistent
FROM "transfer"."LocationEvaluations"
)
SELECT
  grts_address,
  type,
  eval_date,
  type_assessed,
  type_is_absent
 FROM EVA
WHERE loceval_inconsistent
;
'


## FieldCalendars
visits_done <- mnmdb$query_table("Visits") %>%
  dplyr::filter(visit_done)

calendars <- mnmdb$query_table("FieldCalendars") %>%
  dplyr::semi_join(visits_done, by = dplyr::join_by(visit_id)) %>%
  dplyr::filter_out(excluded)

calendars %>%
  dplyr::semi_join(
    disapproval_units,
    by = dplyr::join_by(sampleunit_id)
  ) %>%
  glimpse()
