source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

## ----database-connection------------------------------------------------------
# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

suffix <- "-staging"
suffix <- ""

### connect to mnmgwdb
mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("mnmgwdb{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmgwdb$shellstring)

characteristic_columns <- c(
      "grts_address",
      "stratum",
      "activity_group_id",
      "date_start"
    )

visit_uniques <- mnmgwdb$query_columns(
    "Visits",
    characteristic_columns,
    ONLY = FALSE
    ) %>%
    arrange(grts_address, stratum, date_start, activity_group_id) %>%
    mutate(visit_id = seq_len(n()))


  srctab <- "temp_visitid_update"

  DBI::dbWriteTable(
    mnmgwdb$connection,
    name = srctab,
    value = visit_uniques,
    overwrite = TRUE,
    temporary = TRUE
  )

  lookup_criteria <- unlist(lapply(
    characteristic_columns,
    FUN = function(col) glue::glue("TRGTAB.{col} = SRCTAB.{col}")
  ))

  for (tablab in c(
      "Visits",
      "InstallationVisits",
      "SamplingVisits",
      "PositioningVisits")
    ) {
    trgtab <- mnmgwdb$get_namestring(tablab)

    mnmgwdb$execute_sql(glue::glue("
      UPDATE {trgtab} AS TRGTAB
        SET
        visit_id = visit_id + 100000
    "), verbose = TRUE)

    update_string <- glue::glue("
      UPDATE {trgtab} AS TRGTAB
        SET
          visit_id = SRCTAB.visit_id
        FROM {srctab} AS SRCTAB
        WHERE
         ({paste0(lookup_criteria, collapse = ') AND (')})
      ;")

    # print(update_string)
    mnmgwdb$execute_sql(update_string, verbose = TRUE)
  }

  mnmgwdb$set_sequence_key("Visits", new_key_value = "max", verbose = TRUE )
  sequence_label <- glue::glue('"inbound".seq_visit_id')
  print(mnmgwdb$get_sequence_last_value(sequence_label))

  mnmgwdb$execute_sql(glue::glue("DROP TABLE {srctab};"), verbose = TRUE)


mnmgwdb$query_table("Visits", ONLY = FALSE) %>%
  count(visit_id) %>% filter(n>1)
