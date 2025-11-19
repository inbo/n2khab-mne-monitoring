#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

# credentials are stored for easy access
config_filepath <- file.path("./inbopostgis_server.conf")

# this issue is "mnmgwdb only"
database_label <- "mnmgwdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}


### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(mnmgwdb$shellstring)


#_______________________________________________________________________________
### update fieldwork id in special activities
###

characteristic_columns <- c(
  "grts_address",
  "stratum",
  "activity_group_id",
  "date_start"
)

for (table_label in c(
    "WellInstallationActivities",
    "ChemicalSamplingActivities"
  )) {

  if (table_label == "ChemicalSamplingActivities") {
    offset <- 10000
    } else offset <- 0

  ### query existing
  existing_activities <- mnmgwdb$query_columns(
      table_label,
      c(characteristic_columns, "fieldwork_id")
    ) %>%
    mutate_at(vars(grts_address), as.integer) %>%
    arrange(!!!rlang::syms(characteristic_columns)) %>%
    mutate(fieldwork_id_new = seq_len(n())+offset)

  # existing_activities %>% knitr::kable()

  ### temptable
  srctab <- glue::glue("temp_upd_{tolower(table_label)}")
  trgtab <- mnmgwdb$get_namestring(table_label)

  # create temp table
  DBI::dbWriteTable(
    mnmgwdb$connection,
    name = srctab,
    value = existing_activities,
    overwrite = TRUE,
    temporary = TRUE
  )

  ##e build update query
  ucolumnames <- c("fieldwork_id = SRCTAB.fieldwork_id_new")

  lookup_criteria <- unlist(lapply(
    c(characteristic_columns, "fieldwork_id"),
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))

  update_string <- glue::glue("
    UPDATE {trgtab} AS TRGTAB
      SET
       {paste0(ucolumnames, collapse = ', ')}
      FROM {srctab} AS SRCTAB
      WHERE
       ({paste0(lookup_criteria, collapse = ') AND (')})
    ;")


  ### execute update
  mnmgwdb$execute_sql(update_string)

  mnmgwdb$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)

} # /loop special activity tables
