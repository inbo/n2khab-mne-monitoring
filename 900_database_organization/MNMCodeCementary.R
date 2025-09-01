#!/usr/bin/env Rscript

# Too good to be thrown away. Yet.

#_______________________________________________________________________________
# DATABASE STRUCTURE

# the first entry is the table itself
# find_dependent_tables("mnmgwdb_db_structure", "Visits")
obsolete_find_dependent_tables <- function(dbstructure_folder = "db_structure", table_key) {
  # dbstructure_folder <- "./mnmgwdb_db_structure"
  # table_key <- "Visits"

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, schema, geometry, excluded)

  ### (2) load current data
  excluded_tables <- schemas %>%
    filter(!is.na(excluded)) %>%
    filter(excluded == 1) %>%
    pull(table)

  table_relations <- read_table_relations_config(
    storage_filepath = here::here(dbstructure_folder, "table_relations.conf")
    ) %>%
    filter(relation_table == tolower(table_key),
      !(dependent_table %in% excluded_tables)
    )

  dependent_tables <- c(
    table_key,
    table_relations %>% pull(dependent_table)
    )

  create_dbi_identifier <- function(tabkey) {
    schema <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(schema)
    tkey_right <- schemas %>% filter(tolower(table) == tolower(tabkey)) %>% pull(table)
    return(DBI::Id(schema, tkey_right))
  }

  table_ids <- lapply(dependent_tables, FUN = create_dbi_identifier)

  return(table_ids)

} # /find_dependent_tables


# store the content of a table in memory
obsolete_load_table_content <- function(
    db_connection,
    dbstructure_folder,
    table_id
    ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))

  is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
    select(table, geometry) %>%
    filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
    pull(geometry) %>% is.na

  if (is_spatial) {
    data <- sf::st_read(db_connection, table_id) %>% collect
  } else {
    data <- dplyr::tbl(db_connection, table_id) %>% collect
  }

  return(list("id" = table_id, "data" = data))

} # /load_table_content


# push table from memory back to the server
obsolete_restore_table_data_from_memory <- function(
    db_target,
    content_list,
    dbstructure_folder = "db_structure",
    verbose = TRUE
  ) {
  # content_list <- table_content_storage[[3]]

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("DBI" = require("DBI"))
  stopifnot("glue" = require("glue"))

  table_id <- content_list$id
  table_key <- attr(table_id, "name")
  table_lable <- glue::glue('"{table_key[[1]]}"."{table_key[[2]]}"')
  table_data <- content_list$data


  if (is.scalar.na(table_data) || (nrow(table_data) < 1)) {
    message("no data to restore.")
    return(invisible(NA))
  }

  # restore data
  pk <- mnmdb$get_primary_key(table_key[[2]])

  # TODO need to branch geometry tables?
  # is_spatial <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  #   select(table, geometry) %>%
  #   filter(tolower(table) == tolower(attr(table_id, "name")[[2]])) %>%
  #   pull(geometry) %>% is.na

  # using dplyr/DBI to upload has the usual issues of deletion/restroation,
  # i.e. that user roles are not persistent.
  # Hence, the usual trick of "empty/append".

  # Note that I neglect dependent table here, since they will be re-uploaded after
  ## delete from table
  execute_sql(
    db_target,
    glue::glue("DELETE FROM {table_lable};"),
    verbose = verbose
  )

  ## reset the sequence
  sequence_key <- glue::glue('"{table_key[[1]]}".seq_{pk}')
  nextval_query <- glue::glue("SELECT last_value FROM {sequence_key};")

  current_highest <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]

  execute_sql(
    db_target,
    glue::glue('ALTER SEQUENCE {sequence_key} RESTART WITH 1;'),
    verbose = verbose
  )

  ## append the table data
  append_tabledata(db_target, table_id, table_data)

  ## restore sequence
  nextval <- DBI::dbGetQuery(db_target, nextval_query)[[1, 1]]
  nextval <- max(c(nextval, current_highest, table_data %>% pull(pk)))

  execute_sql(
    db_target,
    glue::glue("SELECT setval('{sequence_key}', {nextval});"),
    verbose = verbose
  )

  return(invisible(NULL))

} # /restore_table_data_from_memory
