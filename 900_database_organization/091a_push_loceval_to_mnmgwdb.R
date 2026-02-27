#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

config_filepath <- file.path("./inbopostgis_server.conf")


#



database_label <- "mnmgwdb"

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
suffix <- "-staging"


message("________________________________________________________________")
message(glue::glue(" <<<<< Transferring `loceval{suffix}` to `mnmgwdb{suffix}`. "))


### connect to database
mnmgwdb <- connect_mnm_database(
  config_filepath,
  database_mirror = glue::glue("{database_label}{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")

message(mnmgwdb$shellstring)


loceval_connection <- connect_mnm_database(
  config_filepath = config_filepath,
  database = "loceval",
  user = "monkey",
  password = NA
)


update_cascade_lookup <- parametrize_cascaded_update(mnmgwdb)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### load loceval local replacements
#///////////////////////////////////////////////////////////////////////////////

# re-link loceval
if (FALSE) {
  # ☇ monkey permissions
  stitch_table_connection(
    mnmdb = loceval_connection,
    table_label = "Replacements",
    reference_table = "SampleUnits",
    link_key_column = "sampleunit_id",
    lookup_columns = c("grts_address", "type"),
  )
} else {
  system(glue::glue("Rscript 095_re_link_foreign_keys_optional.R {suffix}"))
}


replacements_raw <- loceval_connection$query_table("Replacements") %>%
  filter(is_selected, !is_inappropriate) %>%
  select(
    grts_address,
    type,
    sampleunit_id,
    grts_address_replacement,
    replacement_rank,
    notes,
    wkb_geometry
  )

replacement_data <- replacements_raw %>%
  inner_join(
    loceval_connection$query_table("Locations"),
    by = join_by(grts_address),
    suffix = c("_repl", "_loc")
  ) %>%
  left_join(
    loceval_connection$query_table("SampleUnits"),
    by = join_by(grts_address, type),
    suffix = c("", "_unit")
  )

# NOTE: this still has both geometries


# also re-link mnmgwdb
system(glue::glue("Rscript 095_re_link_foreign_keys_optional.R {suffix}"))


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### prepare locations
#///////////////////////////////////////////////////////////////////////////////

# load locations status quo
existing_locations <- mnmgwdb$query_table("Locations")

# identify novel locations
new_locations <- replacement_data %>%
  anti_join(
    existing_locations,
    by = join_by(grts_address_replacement == grts_address)
  )

# upload new locations
locations_upload <- new_locations %>% # replacement_data  %>% #
  sf::st_drop_geometry() %>%
  select(grts_address = grts_address_replacement)

locations_lookup <- update_cascade_lookup(
  table_label = "Locations",
  new_data = locations_upload,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)


## join the new, corrected location id to the list of replacements
existing_again <- mnmgwdb$query_table("Locations") %>%
  select(grts_address_replacement = grts_address, location_id)

replacement_data <- replacement_data %>%
  select(-location_id) %>%
  left_join(
    existing_again,
    by = join_by(grts_address_replacement),
    suffix = c("_obsolete", "")
  )

check <- replacement_data %>%
  filter(is.na(location_id))

if (nrow(check) > 0) {
  check %>%
    t() %>% knitr::kable()
}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### prepare locations
#///////////////////////////////////////////////////////////////////////////////

# load locations status quo
existing_samplelocations <- mnmgwdb$query_table("SampleLocations")

# identify novel locations
new_samplelocations <- replacement_data %>%
  anti_join(
    existing_samplelocations,
    by = join_by(grts_address_replacement == grts_address, type == strata)
  )

new_samplelocations %>% t() %>% knitr::kable()
# these are still needed

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

samplelocations_lookup <- update_cascade_lookup(
  table_label = "SampleLocations",
  new_data = samplelocations_upload,
  index_columns = c("samplelocation_id"),
  characteristic_columns = c("grts_address", "strata"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

samplelocations_lookup <- mnmgwdb$query_columns(
    table_label = "SampleLocations",
    select_columns = c("grts_address", "strata", "samplelocation_id")
  ) %>% rename(stratum = strata)

## join the new, corrected sample location id to the list of replacements
existing_again <- mnmgwdb$query_table("SampleLocations") %>%
  select(grts_address_replacement = grts_address, type = strata, samplelocation_id)

replacement_data <- replacement_data %>%
  left_join(
    existing_again,
    by = join_by(grts_address_replacement, type),
    suffix = c("_obsolete", "")
  )

check <- replacement_data %>%
  filter(is.na(samplelocation_id))

if (nrow(check) > 0) {
  check %>%
    t() %>% knitr::kable()
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
  # NOTE string identifiers must be given beforehand,
  # e.g.
# mnmdb = mnmgwdb # mnmdb$shellstring
# table_label = "TeamMembers"
# row_origin_identification = c("username" = "'Falk'", "family_name" = "'Mielke'")
# fix_values = c("username" = "'Rödiger'", "notes" = "'testing table duplication'")
# exclude_columns = c("notes")
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

  # sort out columns
  fix_columns <- names(fix_values)
  other_columns <- table_columns %>%
    filter(!(column %in% fix_columns)) %>%
    pull(column)

  insert_columns <- c(fix_columns, other_columns)

  # select string
  fix_select <- paste0("",
    unlist(fix_values),
    " AS ", names(fix_values),
    collapse = ", "
  )
  other_select <- paste0(other_columns, collapse = ", ")

  # identifier string
  row_identification <- paste0(
    names(row_origin_identification),
    " = ", unlist(row_origin_identification),
    collapse = " AND "
  )

  # stitch query
  # NOTE [!!!] the ONLY is critical.
  select_component <- glue::glue("
    SELECT {fix_select}, {other_select}
      FROM ONLY {table_namestring}
      WHERE TRUE AND {row_identification}
  ")

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
    samplelocations_lookup,
    by = join_by(grts_address_replacement == grts_address, type == stratum)
  ) %>%
  select(
    grts_address,
    grts_address_replacement,
    strata = type,
    samplelocation_id
  )

stopifnot("Careful now: there is a local replacement!" =
  nrow(to_upload) == 0)

# to_upload <- data.frame(
#     "grts_address" = c(as.integer(23238)),
#     "grts_address_replacement" = c(as.integer(1)),
#     "strata" = "9160",
#     "samplelocation_id" = 2072
#   )
# # SELECT * FROM "outbound"."SampleLocations" ORDER BY samplelocation_id DESC LIMIT 1;

# replacement_data %>%
#   filter(
#    grts_address == 23238
#   ) %>% t() %>% knitr::kable()

# # TODO What was the samplelocation_id?
# # TODO get next fwcal key :(
# fwcal_statusquo <- mnmgwdb$query_table("FieldworkCalendar")
# fwcal_latest <- fwcal_statusquo %>%
#   pull("fieldworkcalendar_id") %>% max()
# mnmgwdb$set_sequence_key("FieldworkCalendar", "max")
# # SELECT last_value FROM "outbound".seq_fieldworkcalendar_id;

# ### query true activity calendar
# activity_groupid_lookup <- mnmgwdb$query_columns(
#     table_label = "GroupedActivities",
#     c("activity_group", "activity_group_id")
#   ) %>%
#   distinct()
#
# gw_field_activities <- mnmgwdb$query_table("GroupedActivities") %>%
#   filter(is_gw_activity, is_field_activity) %>%
#   distinct(activity_group, activity)
#
# # Loop Special Activities
# selection_of_activities <- list(
#   "InstallationVisits" = activity_groupid_lookup %>%
#     filter(grepl("^GWINST", activity_group)) %>%
#     pull(activity_group_id) %>% unique, # /WIA
#   "SamplingVisits" = activity_groupid_lookup %>%
#     filter(activity_group %in%
#       c(gw_field_activities %>%
#         filter(grepl("^GW.*SAMP", activity)) %>%
#         pull(activity_group))
#       ) %>%
#     pull(activity_group_id) %>% unique, # /CSA
#   "PositioningVisits" = activity_groupid_lookup %>%
#     filter(activity_group %in%
#       c(gw_field_activities %>%
#         filter(grepl("^SPATPOSIT", activity)) %>%
#         pull(activity_group))
#       ) %>%
#     pull(activity_group_id) %>% unique # /SPA
# )

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Calendar and Visits
#///////////////////////////////////////////////////////////////////////////////
make_string <- \(txt) glue::glue("{txt}")
wrap_string <- \(txt) glue::glue("'{txt}'")

# check for / retain prior visits
visits_namestring <- mnmdb$get_namestring("Visits")
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

system(glue::glue("Rscript 095_re_link_foreign_keys_optional.R {suffix}"))

for (row_nr in seq_len(nrow(to_upload))) {
  row <- to_upload[row_nr, ]

  for (table_label in names(extra_filters)) {

    # table_label = "Visits"
    table_namestring <- mnmdb$get_namestring(table_label)
    grts_address_replacement <- row[["grts_address_replacement"]]
    grts_address_original <- row[["grts_address"]]
    stratum <- row[["strata"]]

    # TODO historic visits may not be replaced
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


}




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


replacements_upload <- replacement_data %>%
  select(
    type,
    grts_address,
    grts_address_replacement,
    is_replaced,
    new_location_id = location_id,
    new_samplelocation_id = samplelocation_id,
    replacement_rank
  )


replacements_lookup <- update_cascade_lookup(
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

# TODO views do not exist in the connection "object"
view_id <- DBI::Id("outbound", "gwTransfer")
transfer_data <- dplyr::tbl(loceval_connection$connection, view_id) %>%
  grts_datatype_to_integer() %>%
  collect
# replacements are already integrated by the view
# -> in the grts setting of the target mnmgwdb

locevals_joined <- transfer_data %>%
  left_join(
    mnmgwdb$query_columns(
        table_label = "SampleLocations",
        select_columns = c(
          "grts_address", "strata", "samplelocation_id", "location_id"
        )
      ),
    by = join_by(grts_address, type == strata)
  ) %>%
  filter_at(vars(location_id, samplelocation_id), ~!is.na(.)) %>%
  select(-grts_address_original, -location_id) %>%
  mutate(
    eval_name = coalesce(eval_name, "maintenance"),
    eval_date = coalesce(eval_date, as.Date(log_update))
  )

locevals_lookup <- update_cascade_lookup(
  table_label = "LocationEvaluations",
  new_data = locevals_joined,
  index_columns = c("locationevaluation_id"),
  characteristic_columns = c("grts_address", "type", "eval_date", "eval_source"),
  tabula_rasa = TRUE,
  verbose = TRUE
)

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Cel Mapping
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


message("")
message("________________________________________________________________")
message(" >>>>> Finished transferring loceval -> mnmgwdb. ")
message("________________________________________________________________")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### ARCHIVE - wrong old lead
#///////////////////////////////////////////////////////////////////////////////
# upload_nr <- 1
# for (upload_nr in seq_len(nrow(to_upload))) {
#   one_upload <- to_upload[upload_nr, ]
#
#   fwcalendar_to_duplicate <- fwcal_statusquo %>%
#     semi_join(
#       one_upload,
#       by = join_by(grts_address, stratum == strata)
#     )
#   fwcalendar_to_duplicate %>% head(2) %>% t() %>% knitr::kable()
#
#   # cal_nr <- 1
#   for (cal_nr in seq_len(nrow(fwcalendar_to_duplicate))) {
#
#     fwcal_latest <- fwcal_latest + 1
#     cal_row <- fwcalendar_to_duplicate[cal_nr, ]
#
#     duplicate_table_row(
#       mnmdb = mnmgwdb,
#       table_label = "FieldworkCalendar",
#       row_origin_identification = c(
#         "grts_address" = make_string(one_upload[["grts_address"]]),
#         "stratum" = wrap_string(one_upload[["strata"]]),
#         "fieldworkcalendar_id" = make_string(cal_row[["fieldworkcalendar_id"]])
#       ),
#       fix_values = c(
#         "grts_address" = make_string(one_upload[["grts_address_replacement"]]),
#         "samplelocation_id" = make_string(cal_row[["samplelocation_id"]]),
#         "fieldworkcalendar_id" = make_string(fwcal_latest)
#       ),
#       exclude_columns = c("log_user", "log_update")
#     )
#
#     # switch activities
#     activity_group_id <- cal_row[["activity_group_id"]]
#     date_start <- wrap_string(cal_row[["date_start"]])
#
#     if (activity_group_id %in% selection_of_activities[["InstallationVisits"]]) {
#
#       duplicate_table_row(
#         mnmdb = mnmgwdb,
#         table_label = "InstallationVisits",
#         row_origin_identification = c(
#           "grts_address" = make_string(one_upload[["grts_address"]]),
#           "stratum" = wrap_string(one_upload[["strata"]]),
#           "activity_group_id" = make_string(activity_group_id),
#           "date_start" = date_start,
#           "fieldworkcalendar_id" = make_string(cal_row[["fieldworkcalendar_id"]])
#         ),
#         fix_values = c(
#           "grts_address" = make_string(one_upload[["grts_address_replacement"]]),
#           "stratum" = wrap_string(one_upload[["strata"]]),
#           "activity_group_id" = make_string(activity_group_id),
#           "date_start" = date_start,
#           "samplelocation_id" = make_string(cal_row[["samplelocation_id"]]),
#           "fieldworkcalendar_id" = make_string(fwcal_latest)
#         ),
#         exclude_columns = c("log_user", "log_update")
#       )
#
#     }
#
#     [...]
#
#   } # /loop calendar entries to duplicate
#
# } # /loop uploads
