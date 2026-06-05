#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")



#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### a tiny bit of REP data...
#///////////////////////////////////////////////////////////////////////////////
# (required for novel locations which appear via local replacement)

require("terra") %>% suppressPackageStartupMessages()

snippet_base_path <<- rprojroot::find_root(rprojroot::is_git_root)
# TEMPORARY adjustment pointing to adjacent branch (wip)
# snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))
source(file.path(snippet_base_path, "020_fieldwork_organization", "R", "grts.R"))
# source(file.path(snippet_base_path, "020_fieldwork_organization", "R", "grts_mh.R"))

grts_mh <- n2khab::read_GRTSmh()

grts_mh_index <- dplyr::tibble(
    id = seq_len(terra::ncell(grts_mh)),
    grts_address = terra::values(grts_mh)[, 1]
  ) %>%
  dplyr::filter(!is.na(grts_address))



#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### connect to databases
#///////////////////////////////////////////////////////////////////////////////
# connect to the databases:
# - loceval (production, read-only) = the source
# - mnmsyncdb (chosen mirror) = the central broadcaster ("syncdb")
# - mnmgwdb, mnmsurfdb (chosen mirror) = the receiver ("userdb")


config_filepath <- file.path("./mnm_database_connection.conf")

database_label <- "mnmsyncdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
suffix <- "-staging"


# source: loceval
loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = glue::glue("loceval{suffix}"),
  user = "monkey",
  password = NA
)


# intermediate destination: syncdb
mnmsyncdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(mnmsyncdb$shellstring)

# parametrize cascaded update function
update_cascade_lookup_syncdb <- parametrize_cascaded_update(mnmsyncdb)



## connect userdb databases
userdb_labels <- c("mnmgwdb", "mnmsurfdb")
userdb_connections <- list()

for (udbx in userdb_labels) {
  userdb_connections[[udbx]] <- connect_mnm_database(
    config_filepath = config_filepath,
    database = glue::glue("{udbx}{suffix}")
  )
  message(glue::glue("\tconnected: psql {userdb_connections[[udbx]]$shellstring}"))

}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### load loceval local replacements
#///////////////////////////////////////////////////////////////////////////////
### Part 1: loceval -> mnmsyncdb

message("________________________________________________________________")
message(glue::glue(" <<<<< Transferring `loceval{suffix}` to `mnmsyncdb{suffix}`. "))


### load the raw replacements
replacements_raw <- loceval_connection$query_table("Replacements") %>%
  filter(is_selected, !is_inappropriate) %>%
  select(
    grts_address_original = grts_address,
    type,
    grts_address_replacement,
    replacement_rank
  )

# replacements_raw %>%
#   filter(grts_address_original == 3662038) %>%
#   t() %>% knitr::kable()

### get the `loceval_date`
# NOTE: we currently assume that there was only one replacement, and
#       that that replacement is the latest and accurate reference.

loceval_visits <- loceval_connection$query_table("Visits") %>%
  filter(visit_done) %>%
  semi_join(
    replacements_raw,
    by = join_by(
      grts_address == grts_address_original,
      type
    )
  ) %>%
  select(
    grts_address_original = grts_address,
    type,
    date_visit,
    log_user,
    log_update
  )

na_visit_dates <- loceval_visits %>%
  filter(
    is.na(date_visit),
    log_update < as.Date('2026-06-01')
  )  %>%
  mutate(date_visit = as.Date('2024-12-24'))

n_datemissers <- nrow(na_visit_dates)
if (n_datemissers > 0) {
  message(glue::glue(
    "\t[!!!] Heads up: there are {n_datemissers} locevals without a date_visit."
  ))
}

loceval_dates <- loceval_visits %>%
  filter_out(is.na(date_visit)) %>%
  select(grts_address_original, type, date_visit)

duplicate_check <- loceval_dates %>%
  count(grts_address_original, type) %>%
  filter(n > 1)

if (nrow(duplicate_check) > 0) {
  duplicate_check %>% knitr::kable()
  stop("A location was replaced twice by `loceval`.")
}

replacementdata_upload <- replacements_raw %>%
  left_join(
    loceval_dates,
    by = join_by(grts_address_original, type),
    relationship = "one-to-one"
  ) %>%
  rename(loceval_date = date_visit) %>%
  mutate(is_latest_replacement = TRUE)


update_cascade_lookup_syncdb(
  table_label = "ReplacementData",
  new_data = replacementdata_upload,
  index_columns = c("replacementdata_id"),
  characteristic_columns = c("grts_address_original", "type", "grts_address_replacement"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


# # join location and sampleunit info from `locevaldb`
# replacement_data <- replacements_raw %>%
#   inner_join(
#     loceval_connection$query_table("Locations"),
#     by = join_by(grts_address),
#     suffix = c("_repl", "_loc_loceval")
#   ) %>%
#   left_join(
#     loceval_connection$query_table("SampleUnits"),
#     by = join_by(grts_address, type),
#     suffix = c("", "_unit_loceval")
#   )
#
# # NOTE: this still has both geometries
# # NOTE: these are the id's from `locevaldb`


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### distribute replacements to effector databases
#///////////////////////////////////////////////////////////////////////////////
### Part 2: mnmsyncdb -> {mnmgwdb, mnmsurfdb}

## general data
replacement_data <- mnmsyncdb$query_table("ReplacementData") %>%
  select(-replacementdata_id)

sampleunit_tablelabels <- c(
  "mnmgwdb" = "SampleLocations",
  "mnmsurfdb" = "SampleUnits"
)

sampleunit_indices <- c(
  "mnmgwdb" = "samplelocation_id",
  "mnmsurfdb" = "sampleunit_id"
)

sampleunit_typecolumns <- c(
  "mnmgwdb" = "strata",
  "mnmsurfdb" = "stratum"
)

# udb <- "mnmgwdb"

distribute_replacementdata_to_userdatabases <- function(udb) {

message("________________________________________________________________")
message(glue::glue(" <<< Transferring `mnmsyncdb{suffix}` to `{udb}{suffix}`. "))


mnmdb <- userdb_connections[[udb]]
update_cascade_lookup_userdb <- parametrize_cascaded_update(mnmdb)

su_tablab <- sampleunit_tablelabels[[udb]]
su_idx <- sampleunit_indices[[udb]]
su_type <- sampleunit_typecolumns[[udb]]


# load locations status quo
existing_locations <- mnmdb$query_table("Locations")
# existing_locations <- existing_locations %>%
#   filter(grts_address != 1286278, grts_address != 18063494) # testing a local replacement

# identify novel locations
new_locations <- replacement_data %>%
  anti_join(
    existing_locations,
    by = join_by(grts_address_replacement == grts_address)
  )

# upload new locations
locations_grts_collection <- new_locations %>%
  sf::st_drop_geometry() %>%
  select(grts_address = grts_address_replacement)


locations_upload <- locations_grts_collection %>%
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(locations_upload) <- "wkb_geometry"


locations_lookup <- update_cascade_lookup_userdb(
  table_label = "Locations",
  new_data = locations_upload,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

## join the new, corrected location id to the list of replacements
existing_again <- mnmdb$query_table("Locations") %>%
  select(grts_address_replacement = grts_address, location_id)

# join [mnmdb] location ID to the replacement data
replacement_upload <- replacement_data %>%
  select(-location_id) %>%
  left_join(
    existing_again,
    by = join_by(grts_address_replacement),
    suffix = c("_obsolete", "")
  )

# check whether location IDs are missing (triv. not)
check <- replacement_upload %>%
  filter(is.na(location_id))

if (nrow(check) > 0) {
  check %>%
    filter(is.na(location_id)) %>%
    t() %>% knitr::kable()
  stop("A location ID is missing!")
}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### prepare locations
#///////////////////////////////////////////////////////////////////////////////

# TODO continue here
stop("there are more troublesome occurrences of 'strata' prohibiting generalization")

# load locations status quo
existing_samplelocations <- mnmdb$query_table(su_tablab)

# identify novel locations
new_samplelocations <- replacement_data %>%
  anti_join(
    existing_samplelocations,
    by = join_by(grts_address_replacement == grts_address, type == strata)
  )
# these `new_samplelocations` are still needed below!


# upload new locations
samplelocations_upload <- new_samplelocations %>% # replacement_data  %>% #
  sf::st_drop_geometry() %>%
  select(
    location_id,
    grts_address = grts_address_replacement,
    scheme_ps_targetpanels,
    schemes,
    strata = type,
    domain_part,
    is_forest,
    in_mhq_samples,
    has_mhq_assessment,
    archive_version_id
  ) %>%
  mutate(
    is_replacement = TRUE
  )


# verbose
if (nrow(samplelocations_upload) > 0) {
  message("New sample locations to be uploaded:")
  samplelocations_upload %>%
    knitr::kable()
}

sampleunits_lookup <- update_cascade_lookup_userdb(
  table_label = su_tablab,
  new_data = samplelocations_upload,
  index_columns = c(su_idx),
  characteristic_columns = c("grts_address", "strata"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

# a better lookup (of all slocs)
sampleunits_lookup <- mnmdb$query_columns(
    table_label = su_tablab,
    select_columns = c("grts_address", su_type, su_idx)
  ) %>% rename(stratum = strata)

## join the new, corrected sample location id to the list of replacements
existing_units <- mnmdb$query_table(su_tablab)

# HOTFIX: rename columns for uniformity
if (udb == "mnmgwdb") {
  existing_units <- existing_units %>%
    rename(
      sampleunit_id = samplelocation_id,
      stratum = strata
    )
}


replacement_upload <- replacement_upload %>%
  left_join(
    existing_units,
    by = join_by(grts_address_original == grts_address, type == stratum),
    relationship = "one-to-one"
  )

check <- replacement_upload %>%
  filter(is.na(sampleunit_id))

if (nrow(check) > 0) {
  check %>%
    t() %>% knitr::kable()
  stop("A sampleunit_id is missing!")
}

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Tables with Data
#///////////////////////////////////////////////////////////////////////////////
# In tables with data,
# it is to be decided whether to simply UPDATE the grts_address with the repl
# (UPDATE may only happen on future activities)
# or duplicate the entry
# (useful if contains input fields, done only for LocationInfos).

### duplicate a table row by index
# This function will create and execute an INSERT () SELECT...; query
# based on some user input of row identifiers and fixed values
# that this makes no assumptions about the number of rows to update,
#   thus care must be taken
#   with the `origin_identification` to be specific enough.
# NOTE string identifiers/quotes must be given beforehand,
#   e.g.
#   mnmdb = mnmgwdb # mnmdb$shellstring
#   table_label = "TeamMembers"
#   row_origin_identification = c("username" = "'Falk'", "family_name" = "'Mielke'")
#   fix_values = c("username" = "'Rödiger'", "notes" = "'testing table duplication'")
#   exclude_columns = c("notes")
duplicate_table_row <- function(
    mnmdb,
    table_label,
    row_origin_identification,
    fix_values,
    exclude_columns = NULL
  ) {

  table_namestring <- mnmdb$get_namestring(table_label)
  table_columns <- mnmdb$load_table_info(table_label) %>%
    filter(!(primary_key == "True"), !(sequence == "True")) %>%
    select(column)

  # exclude excluded columns
  if (isFALSE(is.null(exclude_columns))) {
    table_columns <- table_columns %>%
      filter(!(column %in% exclude_columns))
  }

  # assemble relevant columns
  fix_columns <- names(fix_values)
  other_columns <- table_columns %>%
    filter(!(column %in% fix_columns)) %>%
    pull(column)

  # "fix_colums" are the columns for which user fixes the values;
  # they will be set first on the INSERT statement
  insert_columns <- c(fix_columns, other_columns)

  # select string:
  #     first the fixed values,
  #     then the actual db content for other cols
  fix_select <- paste0("",
    unlist(fix_values),
    " AS ", fix_columns,
    collapse = ", "
  )
  other_select <- paste0(other_columns, collapse = ", ")

  # identifier string
  row_identification <- paste0(
    names(row_origin_identification),
    " = ", unlist(row_origin_identification),
    collapse = " AND "
  )

  # stitch SELECT part of the query
  # NOTE [!!!] the ONLY is critical.
  select_component <- glue::glue("
    SELECT {fix_select}, {other_select}
      FROM ONLY {table_namestring}
      WHERE TRUE AND {row_identification}
  ")

  # combine with the INSERT part
  insert_colstr <- paste0(insert_columns, collapse = ", ")
  insert_query <- glue::glue("
    INSERT INTO {table_namestring} ({insert_colstr})
    {select_component}
  ")

  # execute duplication
  mnmdb$execute_sql(insert_query, verbose = FALSE)

  # SELECT username, notes, family_name, given_name
  #   FROM "metadata"."TeamMembers"
  #   WHERE family_name = 'Mielke'
  # ;
  # DELETE FROM "metadata"."TeamMembers" WHERE username = 'Rödiger';

} # /duplicate_table_row

# # testing
# if (suffix == "-staging") {
#   duplicate_table_row(
#     mnmdb = mnmgwdb,
#     table_label = "TeamMembers",
#     row_origin_identification = c("username" = "'Falk'", "family_name" = "'Mielke'"),
#     fix_values = c("username" = "'Rödiger'", "notes" = "'testing table duplication'"),
#     exclude_columns = c("notes")
#   )
# }

to_upload <- new_samplelocations %>%
  left_join(
    sampleunits_lookup,
    by = join_by(grts_address_replacement == grts_address, type == stratum)
  ) %>%
  select(
    grts_address,
    grts_address_replacement,
    type,
    sampleunit_id
  )

# HOTFIX again
if (udb == "mnmgwdb") {
  to_upload <- to_upload %>%
    rename(strata = type)
}

# # This safety break was used for the very first local replacement
# stopifnot("Careful now: there is a local replacement!" =
#   nrow(to_upload) == 0)
if (nrow(to_upload) > 0) {
  message(">>> Applying new replacements.")
  to_upload %>% knitr::kable()
}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Calendar and Visits
#///////////////////////////////////////////////////////////////////////////////
# These will be executed by
#     UPDATING the `grts_address` in existing calender entries
# (classical, custom query knitting)

make_string <- \(txt) glue::glue("{txt}")
wrap_string <- \(txt) glue::glue("'{txt}'")


### (A) tables which are updated by just changing the `grts_address`
# check for / retain prior visits
visits_namestring <- mnmgwdb$get_namestring("Visits")
calendar_visits_done <- glue::glue("
  SELECT DISTINCT fieldworkcalendar_id
  FROM {visits_namestring}
  WHERE visit_done
")
visits_not_done_filter <- glue::glue(
  "fieldworkcalendar_id NOT IN ({calendar_visits_done})"
)

# must contain all tables which are to be affected
extra_filters <- c(
  "FieldworkCalendar" = visits_not_done_filter,
  "Visits" = visits_not_done_filter
)

# re-link keys once more
out <- processx::run(
  "Rscript",
  c("102_re_link_foreign_keys.R", suffix),
  spinner = TRUE
)

# UPDATE the grts_address in FieldworkCalendar and Visits
for (row_nr in seq_len(nrow(to_upload))) {
  row <- to_upload[row_nr, ]

  for (table_label in names(extra_filters)) {

    # table_label = "Visits"
    table_namestring <- mnmgwdb$get_namestring(table_label)
    grts_address_replacement <- row[["grts_address_replacement"]]
    grts_address_original <- row[["grts_address"]]
    stratum <- row[[su_type]]

    # historic visits may not be replaced
    # -> use NOT IN {visit_done} structure
    filter_further <- extra_filters[[table_label]]

    grts_update <- glue::glue("
      UPDATE {table_namestring}
      SET grts_address = {grts_address_replacement}
      WHERE {filter_further}
        AND grts_address = {grts_address_original}
        AND stratum = '{stratum}'
    ;
    ")

    mnmgwdb$execute_sql(grts_update, verbose = TRUE)

  } # /loop tables with grts rename


} # loop rows to upload


### (B) tables which need a row duplicate
#   because the old `grts_address` is still somewhat stored
for (row_nr in seq_len(nrow(to_upload))) {
  row <- to_upload[row_nr, ]

  ### duplicate LocationInfos if applicable
  locinfos_status_quo <- mnmgwdb$query_table("LocationInfos")
  locinfo_id_latest <- locinfos_status_quo %>%
    pull("locationinfo_id") %>% max() + 1
  mnmgwdb$set_sequence_key("LocationInfos", "max")
  # SELECT last_value FROM "outbound".seq_locationinfo_id;
  locinfos_grts_existing <- locinfos_status_quo  %>% pull(grts_address)

  if (isFALSE(row[["grts_address_replacement"]] %in% locinfos_grts_existing)) {
    duplicate_table_row(
      mnmdb = mnmgwdb,
      table_label = "LocationInfos",
      row_origin_identification = c(
        "grts_address" = make_string(row[["grts_address"]])
      ),
      fix_values = c(
        "grts_address" = make_string(row[["grts_address_replacement"]]),
        "locationinfo_id" = make_string(locinfo_id_latest)
      ),
      exclude_columns = c("log_user", "log_update")
    )
  }
} # /loop rows to upload



#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### store replacement data - tabula rasa
#///////////////////////////////////////////////////////////////////////////////
# this is just an overview table
#   in which all the replacements are stored for later reference


replacements_upload <- replacement_data %>%
  select(
    type,
    grts_address_original,
    loceval_date,
    grts_address_replacement,
    replacement_rank,
    is_latest_replacement
  ) %>%
  left_join(
    sampleunits_lookup %>%
      rename(grts_address_replacement = grts_address),
    by = join_by(!!!rlang::syms(c("grts_address_replacement", su_type, su_idx)))
  )


replacements_lookup <- update_cascade_lookup_userdb(
  table_label = "ReplacementData",
  new_data = replacements_upload,
  index_columns = c("replacementdata_id"),
  characteristic_columns = c("grts_address", "type", "grts_address_replacement"),
  tabula_rasa = TRUE,
  verbose = TRUE
)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### LocationEvaluations
#///////////////////////////////////////////////////////////////////////////////

view_id <- DBI::Id("outbound", "gwTransfer")
transfer_data <- dplyr::tbl(loceval_connection$connection, view_id) %>%
  grts_datatype_to_integer() %>%
  collect
# replacements are already integrated by the view
# -> in the grts setting of the target mnmgwdb

if (udb == "mnmgwdb") {
  transfer_data <- transfer_data %>%
    rename(strata = type)
}

loceval_characols <- c(
  "grts_address",
  "type",
  "date_start",
  "eval_date",
  "eval_source"
)

locevals_joined <- transfer_data %>%
  left_join(
    mnmgwdb$query_columns(
        table_label = su_tablab,
        select_columns = c(
          "grts_address",
          su_type,
          su_idx,
          "location_id"
        )
      ),
    by = join_by(!!!rlang::syms(c("grts_address", su_type)))
  ) %>%
  filter_at(vars(!!!rlang::syms(c("location_id", su_idx)), ~!is.na(.)) %>%
  select(-grts_address_original, -location_id) %>%
  mutate(
    eval_name = coalesce(eval_name, "maintenance"),
    eval_date = coalesce(eval_date, as.Date(log_update))
  )

duplicate_locevals <- locevals_joined %>%
  count(!!!rlang::syms(loceval_characols)) %>%
  arrange(desc(n)) %>%
  filter(n > 1)

if (nrow(duplicate_locevals) > 0) {
  duplicate_locevals %>% t() %>% knitr::kable()
  stop("there were duplicate locevals!")
}


locevals_lookup <- update_cascade_lookup(
  table_label = "LocationEvaluations",
  new_data = locevals_joined,
  index_columns = c("locationevaluation_id"),
  characteristic_columns = loceval_characols,
  tabula_rasa = TRUE,
  verbose = TRUE
)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Cell Mapping
#///////////////////////////////////////////////////////////////////////////////

cellmaps <- loceval_connection$query_table("CellMaps")
cellmaps_lookup <- update_cascade_lookup(
  table_label = "CellMaps",
  new_data = cellmaps,
  index_columns = c("cellmap_id"),
  characteristic_columns = NA,
  tabula_rasa = TRUE,
  verbose = TRUE
)


} # /distribute_replacementdata_to_userdatabases

message("")
message("________________________________________________________________")
message(glue::glue(
  ">>> Finished distributing `loceval{suffix}` information to databases. ")
)
message("________________________________________________________________")

