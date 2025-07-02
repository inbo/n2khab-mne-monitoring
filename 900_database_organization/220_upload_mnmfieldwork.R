
working_dbname <- "mnmfield_dev"
config_filepath <- file.path("./inbopostgis_server.conf")
connection_profile <- "mnmfield-dev"
dbstructure_folder <- "./mnmfield_dev_structure"


common_current_calenderfilters <- function(.data) {
  return(
    .data %>%
      filter(
        year(date_start) < 2026,
      )
  )
}

common_current_samplefilters <- function(.data) {
  return(
    .data %>%
      filter(
        # only consider schemes scheduled in 2025:
        str_detect(scheme, "^(GW|HQ)"),
        # only keep cell-based types
        # (aquatic & 7220 will be more reliable or simply
        # not possible to evaluate on orthophoto)
        # str_detect(grts_join_method, "cell")
      )
  )
}

prioritize_and_arrange_fieldwork <- function(.data) {

  return(
  .data %>%
    mutate(
      priority = case_when(
        str_detect(
          scheme_ps_targetpanels,
          "GW_03\\.3:(PS1PANEL(09|10|11|12)|PS2PANEL0[56])|SURF_03\\.4_[a-z]+:PS\\dPANEL03"
        ) ~ 1L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 2L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL07|PS2PANEL03)") ~ 3L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:PS1PANEL0[56]") ~ 4L,
        .default = 5L
      ),
      wait_watersurface = str_detect(stratum, "^31|^2190_a$"),
      wait_3260 = stratum == "3260",
      wait_7220 = str_detect(stratum, "^7220")
    )
  ) %>%
  arrange(
    date_end,
    priority,
    wait_watersurface,
    wait_3260,
    wait_7220,
    stratum,
    grts_address,
    rank,
    field_activity_group
  )
}

rename_grts_address_final_to_grts_address <- function(.data) {
  return(
  .data %>%
    select(-grts_address) %>%
    rename(
      grts_address = grts_address_final,
    )
  )
}

nest_scheme_ps_targetpanel <- function(.data) {
  # flatten scheme x panel set x targetpanel to unique strings per stratum x
  # location x FAG occasion. Note that the scheme_ps_targetpanels attribute is a
  # shrinked version of the one at the level of the whole sample (see sampling
  # unit attributes in the beginning), since we limited the activities to those
  # planned before 2026, and then generate stratum_scheme_ps_targetpanels as a
  # location attribute. So it says specifically which schemes x panel sets x
  # targetpanels are served by the specific fieldwork at a specific date
  # interval.
  return(
  .data %>%
    mutate(scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    )) %>%
    nest(scheme_ps_targetpanels = scheme_ps_targetpanel) %>%
    mutate(
      scheme_ps_targetpanels = map_chr(scheme_ps_targetpanels, \(df) {
        str_flatten(
          unique(df$scheme_ps_targetpanel),
          collapse = " | "
        )
      }) %>%
        factor()
    ) %>%
    relocate(scheme_ps_targetpanels)
  )
}

convert_stratum_to_type <- function(.data) {
  # converting stratum to type (in the usual way, although for the cell-based
  # units the values - but not the factor levels - are identical)
  return(
  .data %>%
    inner_join(
      n2khab_strata,
      join_by(stratum),
      relationship = "many-to-one",
      unmatched = c("error", "drop")
    ) %>%
    select(-stratum) %>%
    relocate(type, .after = sp_poststratum)
  )
}


#_______________________________________________________________________________
####   Libraries   #############################################################

library("dplyr")
library("tidyr")
library("stringr")
library("purrr")
library("lubridate")
library("sf")
library("terra")
library("n2khab")
library("googledrive")
library("readr")
library("rprojroot")
library("keyring")

library("configr")
library("DBI")
library("RPostgres")
# library("mapview")
# mapviewOptions(platform = "mapdeck")

# you might want to run the following prior to sourcing/rendering this script:
# keyring::key_set("DBPassword", "db_user_password")


#_______________________________________________________________________________
####   POC   ###################################################################

# POC warning!
message(
  "This script assumes that the latest version of the POC RData is downloaded
  (see `070_update_POC.qmd`)."
)


poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)
source("050_snippet_selection.R")

# Load some custom GRTS functions
# source(file.path(projroot, "R/grts.R"))
# TODO: rebase once PR#5 gets merged
source(
  "/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R"
)


#_______________________________________________________________________________
####   Database   ##############################################################


source("MNMDatabaseToolbox.R")


db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile
)


schemas <- read.csv(here::here(dbstructure_folder, "TABLES.csv")) %>%
  select(table, schema, geometry)

# These are clumsy, temporary, provisional helpers.
# But, hey, there will be time later.
get_schema <- function(tablelabel) {
  return(schemas %>%
    filter(table == tablelabel) %>%
    pull(schema)
  )
}
get_namestring <- function(tablelabel) glue::glue('"{get_schema(tablelabel)}"."{tablelabel}"')
get_tableid <- function(tablelabel) DBI::Id(schema = get_schema(tablelabel), table = tablelabel)


# a local database dump as safety backup
now <- format(Sys.time(), "%Y%m%d%H%M")
dump_all(
  here::here("dumps", glue::glue("safedump_{working_dbname}_{now}.sql")),
  config_filepath = config_filepath,
  database = working_dbname,
  profile = "dumpall",
  user = "monkey",
  exclude_schema = c("tiger", "public")
)


#_______________________________________________________________________________
####   Metadata   ##############################################################

## ----upload-teammembers-------------------------------------------------------
members <- read_csv(here::here("db_structure", "data_TeamMembers.csv"))

member_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "TeamMembers"),
  members,
  ref_cols = "username",
  index_col = "teammember_id"
)


## ----upload-protocols---------------------------------------------------------
protocols <- activities %>%
  select(protocol) %>%
  distinct() %>%
  arrange(protocol) %>%
  filter(!is.na(protocol)) %>%
  mutate(
    protocol_id = 1:n(),
    protocol = as.character(protocol),
    description = NA
  )

protocol_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "Protocols"),
  protocols,
  ref_cols = "protocol",
  index_col = "protocol_id"
)


## ----upload-grouped-activities------------------------------------------------

grouped_activities_upload <- grouped_activities %>%
  lookup_join(protocol_lookup, "protocol")

grouped_activities_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "GroupedActivities"),
  grouped_activities_upload,
  ref_cols = c(
    "activity_group",
    "activity",
    "activity_group_id",
    "activity_id"
  ),
  index_col = "grouped_activity_id"
)


## ----upload-n2khabtype--------------------------------------------------------

n2khab_types_upload <- bind_rows(
  as_tibble(list(
    type = c("gh"),
    typelevel = c("main_type"),
    main_type = c("gh")
  )),
  n2khab_types_expanded_properties
  )


n2khabtype_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "N2kHabTypes"),
  n2khab_types_upload,
  ref_cols = "type",
  index_col = "n2khabtype_id"
)


## ----collect-location-assessments----------------------------------------------
# load previous in preatorio work from another database

db_loceval <- connect_database_configfile(
  config_filepath,
  database = "loceval",
  profile = "dumpall",
  user = "monkey",
  password = NA
)

migrating_schema <- "outbound"
migrating_table_key <- "LocationAssessments"
migrating_table <- DBI::Id(
  schema = migrating_schema,
  table = migrating_table_key
  )

locationassessments_data <- dplyr::tbl(
    db_loceval,
    migrating_table
  ) %>%
  collect() # collecting is necessary to modify offline and to re-upload

# before we upload, we need to collect all locations


## ----collect-sample-locations----------------------------------------------
sample_locations <-
  fag_stratum_grts_calendar %>%
  common_current_calenderfilters() %>%
  distinct(
    scheme_moco_ps,
    stratum,
    grts_address
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      select(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ) %>%
      # deduplicating 7220:
      distinct(),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  common_current_samplefilters() %>%
  # also join the spatial poststratum, since we need this in setting
  # GRTS-address based priorities
  inner_join(
    scheme_moco_ps_stratum_sppost_spsamples %>%
      unnest(sp_poststr_samples) %>%
      select(-sample_status),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  select(-module_combo_code) %>%
  nest_scheme_ps_targetpanel() %>%
  # add MHQ assessment metadata
  inner_join(
    stratum_grts_n2khab_phabcorrected_no_replacements %>%
      select(stratum, grts_address, assessed_in_field, assessment_date),
    join_by(stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  distinct() %>%
  convert_stratum_to_type() %>%
  rename_grts_address_final_to_grts_address() %>%
  rename(
    assessment = assessed_in_field,
    assessment_date = assessment_date # triv.
  ) %>%
  relocate(grts_address) %>%
  relocate(grts_join_method, .after = grts_address) %>%
  mutate(
    previous_notes = NA # FUTURE TODO
  ) %>%
  mutate(
    across(c(
        grts_join_method,
        scheme_ps_targetpanels,
        sp_poststratum,
        type
      ),
      as.character
    )
  )

# glimpse(sample_locations)

# TODO still need to join the location, below
# TODO in the future, make sure `type` is
#      correctly filled from LOCEVAL
#      "previous_assessment" -> "assessment"
#      and add previous_notes


## ----upload-locations----------------------------------------------
# will be the union set of grts addresses in
#    - locationassessments_data
#    - sample_locations
# not accounting for fieldwork_calendar because that is derived from
# the same source as sample_locations

locations <- c(
    sample_locations %>% pull(grts_address) %>% as.integer(),
    locationassessments_data %>% pull(grts_address) %>% as.integer()
  ) %>%
  tibble(grts_address = .) %>%
  distinct() %>%
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

sf::st_geometry(locations) <- "wkb_geometry"


# TODO first, delete locations to prevent the `ogc_fid` duplicate error

rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "metadata"."Locations";'
  )

locations_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "metadata", table = "Locations"),
  locations,
  ref_cols = "grts_address",
  index_col = "location_id"
)


# **Upload Location Polygons:**

units_cell_polygon[["grts_address_final"]] <-
  as.integer(units_cell_polygon[["grts_address_final"]])

# unit geometries (cells):
location_cells <-
  units_cell_polygon %>%
  inner_join(
    locations_lookup,
    by = join_by(grts_address_final == grts_address),
    relationship = "one-to-many",
    unmatched = "drop"
  ) %>%
  select(-grts_address_final) %>%
  relocate(geometry, .after = last_col())

sf::st_geometry(location_cells) <- "wkb_geometry"

# glimpse(location_cells)

append_tabledata(
  db_connection,
  DBI::Id(schema = "metadata", table = "LocationCells"),
  location_cells,
  reference_columns = "location_id"
)


## ----upload-sample-locations----------------------------------------------

if ("location_id" %in% names(sample_locations)) {
  # should not be the case in a continuous script;
  # this is extra safety for debugging and de-serial execution
  sample_locations <- sample_locations %>%
    select(-location_id)
}
sample_locations <- sample_locations %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  )

# might otherwise be duplicated due to missing fk and null constraint
rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "outbound"."SampleLocations";'
  )

slocs_refcols <- c(
  "type",
  "grts_address",
  "scheme",
  "panel_set",
  "targetpanel"
  # "sp_poststratum"
)
sample_locations_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "outbound", table = "SampleLocations"),
  sample_locations,
  ref_cols = slocs_refcols,
  index_col = "samplelocation_id"
)

# sample_locations_lookup %>% nrow()
# sample_locations_lookup %>%
#   select(!!!slocs_refcols) %>%
#   distinct %>%
#   nrow()

## ----upload-calendar----------------------------------------------

# TODO @FV shall we include aquatic types for the calendar?


fieldwork_calendar <-
  fag_stratum_grts_calendar %>%
  common_current_calenderfilters() %>%
  select(
    scheme_moco_ps,
    stratum,
    grts_address,
    starts_with("date"),
    field_activity_group,
    rank
  ) %>%
  # move the fieldwork that was kept for 2024, to 2025, since that is indeed
  # its meaning
  mutate(
    across(c(date_start, date_end), \(x) {
      if_else(year(date_start) == 2024, x + years(1), x)
    }),
    date_interval = interval(
      force_tz(date_start, "Europe/Brussels"),
      force_tz(date_end, "Europe/Brussels")
    )
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      select(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ) %>%
      # deduplicating 7220:
      distinct(),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  # also join the spatial poststratum, since we need this in setting
  # GRTS-address based priorities
  inner_join(
    scheme_moco_ps_stratum_sppost_spsamples %>%
      unnest(sp_poststr_samples) %>%
      select(-sample_status),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one"
  ) %>%
  select(-module_combo_code) %>%
  common_current_samplefilters() %>%
  nest_scheme_ps_targetpanel() %>%
  prioritize_and_arrange_fieldwork() %>%
  convert_stratum_to_type() %>%
  rename_grts_address_final_to_grts_address() %>%
  left_join(
    grouped_activities_lookup %>%
      select(activity_group, activity_group_id) %>%
      distinct()
    ,
    by = join_by(field_activity_group == activity_group),
    relationship = "many-to-many"
  ) %>%
  select(-field_activity_group) %>%
  rename(activity_rank = rank) %>%
  relocate(activity_rank, .after = activity_group_id) %>%
  left_join(
    sample_locations_lookup,
    by = slocs_refcols,
    relationship = "many-to-one"
  ) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  ) %>%
  select(
    -grts_address,
    -type,
    -scheme_ps_targetpanels,
    -scheme,
    -panel_set,
    -sp_poststratum,
    -date_interval,
    -grts_join_method,
    -targetpanel
  )

# glimpse(fieldwork_calendar)

fac_lookup <- upload_and_lookup(
  db_connection,
  DBI::Id(schema = "outbound", table = "FieldActivityCalendar"),
  fieldwork_calendar,
  ref_cols = c("samplelocation_id", "activity_group_id", "date_start"),
  index_col = "fieldactivitycalendar_id"
)


# TODO check that stratum matches type from the orthofoto table

locationassessments_upload <- locationassessments_data %>%
  select(-location_id) %>%
  left_join(
    locations_lookup,
    by = join_by(grts_address),
    relationship = "many-to-one"
  )

# Location Assessments: re-link locations
rs <- DBI::dbExecute(
  db_connection,
  'DELETE FROM "outbound"."LocationAssessments";'
  )

# re-upload
sf::dbWriteTable(
  db_connection,
  DBI::Id(schema = "outbound", table = "LocationAssessments"),
  locationassessments_upload,
  row.names = FALSE,
  overwrite = FALSE,
  append = TRUE,
  factorsAsCharacter = TRUE,
  binary = TRUE
  )


## TODO POC update?
## TODO Visits from Calendar
