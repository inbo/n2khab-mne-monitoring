# update date interval, based on date_start and date_end

# testing 20260410:
#
# SELECT DISTINCT
#   date_start, date_end, date_interval
# FROM "outbound"."FieldworkCalendar"
# WHERE grts_address = 1660081
# ;

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


# source the `update_date_interval` function
for (fi in c("system_helpers.R", "calendar_operations_and_priorities.R")) {
  source(file.path(
    rprojroot::find_root(rprojroot::is_git_root),
    "020_fieldwork_organization",
    "R",
    fi
  ))
}


database_date_interval_update <- function(mnmdb, table_label) {

  srctab <- glue::glue("temp_upd_{tolower(table_label)}")
  trgtab <- mnmdb$get_namestring(table_label)


  date_interval_updates <- mnmdb$query_columns(
      table_label,
      c("date_start", "date_end", "date_interval")
    ) %>%
    rename(date_interval_old = date_interval) %>%
    update_date_interval() %>%
    mutate_at(vars(date_interval), as.character) %>%
    distinct()


  # create temp table
  DBI::dbWriteTable(
    mnmdb$connection,
    name = srctab,
    value = date_interval_updates,
    overwrite = TRUE,
    temporary = TRUE
  )

  ### build update query
  # updated columns
  ucolumnames <- unlist(lapply(
    c("date_interval"),
    FUN = function(col) glue::glue("{col} = SRCTAB.{col}")
  ))

  # lookup columns
  lookup_criteria <- unlist(lapply(
    c("date_start", "date_end"),
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))

  # update string
  update_string <- glue::glue("
    UPDATE {trgtab} AS TRGTAB
      SET
       {paste0(ucolumnames, collapse = ', ')}
      FROM {srctab} AS SRCTAB
      WHERE
       ({paste0(lookup_criteria, collapse = ') AND (')})
    ;")

  ### execute update
  mnmdb$execute_sql(update_string)

  mnmdb$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)

} # /database_date_interval_update


database_label <- "loceval"
suffix <- "-staging"
suffix <- ""


locevaldb <- connect_mnm_database(
  config_filepath = file.path("./mnm_database_connection.conf"),
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(locevaldb$shellstring)


database_date_interval_update(locevaldb, "FieldActivityCalendar")



database_label <- "mnmgwdb"
suffix <- "-staging"
suffix <- ""


mnmgwdb <- connect_mnm_database(
  config_filepath = file.path("./mnm_database_connection.conf"),
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmgwdb$shellstring)


database_date_interval_update(mnmgwdb, "FieldworkCalendar")
