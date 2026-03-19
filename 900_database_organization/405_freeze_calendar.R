
# libraries
source("MNMLibraryCollection.R")
load_database_interaction_libraries()

# the database connection object
source("MNMDatabaseConnection.R")

# more specific database tools
source("MNMDatabaseToolbox.R")


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
  database_mirror = locevaldb_mirror,
  user = "monkey",
  password = NA
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {locevaldb$shellstring}"))


# connect mnmgwdb
mnmgwdb_mirror <- glue::glue("mnmgwdb{suffix}")

mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = mnmgwdb_mirror,
  user = "monkey",
  password = NA
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(glue::glue("connected: psql {mnmgwdb$shellstring}"))


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### export relevant data
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


# update key links
source("102_re_link_foreign_keys.R")

#' query all relevant info of fixed calendar periods from a given MNM database
query_frozen_tables <- function(db) {

  calendar <- connections[[db]]$query_table(calendar_table[[db]])
  cal_pk <- glue::glue("{tolower(calendar_table[[db]])}_id")
  visits <- connections[[db]]$query_table(visit_table[[db]])
  activity_groups <- connections[[db]]$query_columns(
    "GroupedActivities",
    c("activity_group_id", "activity_group")
  ) %>% distinct()

  calendar %>%
    filter(date_start <= freeze_date) %>%
    left_join(
      activity_groups,
      by = join_by(activity_group_id),
      relationship = "many-to-one"
    ) %>%
    left_join(
      visits,
      by = join_by(!!!rlang::syms(cal_pk)),
      relationship = "one-to-one",
      suffix = c("", "_visits")
    ) %>%
    return()

}


# I have been thinking and working too long towards this variable definition
# to apply this in a loop...
gw_freeze <- query_frozen_tables("gw") # *chuckle*
gw_freeze %>%
  write.csv(file = file.path("sideload", glue::glue("freeze_gw.csv")))

# also for loceval
loceval_freeze <- query_frozen_tables("eva") # let it go!
loceval_freeze %>%
  write.csv(file = file.path("sideload", glue::glue("freeze_loceval.csv")))
