
# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


# NOTE: this freeze date was set upon REP update 0.15.0, March 2026
freeze_date <- as.Date("2025-12-31")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### connect databases
#///////////////////////////////////////////////////////////////////////////////

config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"
suffix <- "-staging"

# connect loceval
locevaldb_mirror <- glue::glue("loceval{suffix}")

locevaldb <- connect_mnm_database(
  config_filepath,
  database_mirror = locevaldb_mirror
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {locevaldb$shellstring}"))


# connect mnmgwdb
mnmgwdb_mirror <- glue::glue("mnmgwdb{suffix}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {mnmgwdb$shellstring}"))


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### table and field catalogus
#///////////////////////////////////////////////////////////////////////////////

connections <- list(
  "gw" = mnmgwdb,
  "eva" = locevaldb
)

# TODO consider writing these to a meta-table on the server

calendar_table <- c(
  "gw" = "FieldworkCalendar",
  "eva" = "FieldActivityCalendar"
)

visit_table  <- c(
  "gw" = "AllVisits",
  "eva" = "Visits"
)

units_table  <- c(
  "gw" = "SampleLocations",
  "eva" = "SampleUnits"
)

remove_plural_s <- \(txt) substr(txt, 1, nchar(txt) - 1)

### update key links
# keyring/getpass sometimes segfaults R;
# this will make sure that either there is a key
# or main process crashes (preferred)
keyring <- "mnmdb_temp"
if (keyring::keyring_is_locked(keyring)) unlock_keyring(keyring_label = keyring)

# update key links by running script in the background
out <- processx::run(
  "Rscript",
  c("102_re_link_foreign_keys.R", suffix),
  spinner = TRUE
)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### update calendar flag
#///////////////////////////////////////////////////////////////////////////////

# db <- "gw"
update_calendar_freeze_attribute <- function(db) {

  caltab <- calendar_table[[db]]
  caltab_namestring <- connections[[db]]$get_namestring(caltab)
  freeze_date_str <- strftime(freeze_date, format = "%Y-%m-%d")


  # check_command <- glue::glue("
  #   SELECT * FROM {caltab_namestring}
  #   WHERE date_start <= '{freeze_date_str}'
  #     AND done_planning
  #   ORDER BY date_start DESC
  #   ;
  # ")
  # print(check_command)

  # stitch the update command
  freezing_command <- glue::glue("
    UPDATE {caltab_namestring}
      SET is_frozen = TRUE
    WHERE date_start <= '{freeze_date_str}'
    ;
  ")

  # execute update command
  connections[[db]]$execute_sql(freezing_command)


  # SELECT DISTINCT date_start, is_frozen, count(*) AS N
  # FROM "outbound"."FieldworkCalendar"
  # GROUP BY is_frozen, date_start;

  # SELECT DISTINCT date_start, is_frozen, count(*) AS N
  # FROM "outbound"."FieldActivityCalendar"
  # GROUP BY is_frozen, date_start;

} # /update_calendar_freeze_attribute

update_calendar_freeze_attribute("gw")
update_calendar_freeze_attribute("eva")

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### export relevant data
#///////////////////////////////////////////////////////////////////////////////


#' query all relevant info of fixed calendar periods from a given MNM database
query_frozen_tables <- function(db) {

  calendar <- connections[[db]]$query_table(calendar_table[[db]])
  cal_pk <- glue::glue("{tolower(calendar_table[[db]])}_id")
  unit_pk <- glue::glue("{remove_plural_s(tolower(units_table[[db]]))}_id")

  visits <- connections[[db]]$query_table(visit_table[[db]])

  activity_groups <- connections[[db]]$query_columns(
    "GroupedActivities",
    c("activity_group_id", "activity_group")
  ) %>% distinct()

  sampleunits <- connections[[db]]$query_table(units_table[[db]])

  calendar %>%
    filter(date_start <= freeze_date) %>%
    left_join(
      activity_groups,
      by = join_by(activity_group_id),
      relationship = "many-to-one"
    ) %>%
    left_join(
      sampleunits,
      by = join_by(!!!rlang::syms(unit_pk)),
      relationship = "many-to-one",
      suffix = c("", "_UNITS")
    ) %>%
    left_join(
      visits,
      by = join_by(!!!rlang::syms(cal_pk)),
      relationship = "one-to-one",
      suffix = c("", "_VISITS")
    ) %>%
    return()

} # /query_frozen_tables


# I have been thinking and working too long towards this variable definition
# to apply this in a loop...
gw_freeze <- query_frozen_tables("gw")
gw_freeze %>%
  write.csv(file = file.path("sideload", glue::glue("freeze_gw.csv")))

# also for loceval
loceval_freeze <- query_frozen_tables("eva") # let it go!
loceval_freeze %>%
  write.csv(file = file.path("sideload", glue::glue("freeze_loceval.csv")))
