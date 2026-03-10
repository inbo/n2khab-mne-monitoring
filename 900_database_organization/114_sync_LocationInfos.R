#!/usr/bin/env Rscript

# TODO in case we get to more than two databases,
#      create a central place to store infos
#      and check against that.

#_______________________________________________________________________________
### Libraries

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")

todays_date <- strftime(as.POSIXct(Sys.time()), "%Y%m%d%H%M%S")

#_______________________________________________________________________________
### connect to databases

# credentials are stored for easy access
config_filepath <- file.path("./mnm_database_connection.conf")

commandline_args <- commandArgs(trailingOnly = TRUE)
if (length(commandline_args) > 0) {
  suffix <- commandline_args[1]
} else {
  suffix <- ""
  # suffix <- "-staging" # "-testing"
}
# suffix <- "-staging"

mnmgwdb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("mnmgwdb{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(mnmgwdb$shellstring)

locevaldb <- connect_mnm_database(
  config_filepath = config_filepath,
  database_mirror = glue::glue("loceval{suffix}")
)
# keyring::keyring_delete(keyring = "mnmdb_temp")
message(locevaldb$shellstring)


#_______________________________________________________________________________
### Load Data

loceval_locations <- locevaldb$query_table("Locations")
loceval_data <- locevaldb$query_table("LocationInfos")

mnmgwdb_locations <- mnmgwdb$query_table("Locations")
mnmgwdb_data <- mnmgwdb$query_table("LocationInfos")


if (FALSE) {
# local replacements
mnmgwdb_replacements <- mnmgwdb$query_table("ReplacementData")

# .data <- mnmgwdb_data
# replace_forward <- TRUE
transmogrify_data <- function(.data, replace_forward) {
  # toggle grts_address replacement of a data frame
  # forward: switch from original to replaced grts address
  # backward: return from replaced to original grts
  # taking "type" into account, of course
  # and assuming that the column name is `grts_address`.

  grts_lookup <- mnmgwdb_replacements %>%
    distinct(grts_address, type, grts_address_replacement)

  if (replace_forward) {
    grts_lookup <- grts_lookup %>%
      rename(
        grts_address_before = grts_address,
        grts_address_after = grts_address_replacement
      )
  } else {
    grts_lookup <- grts_lookup %>%
      rename(
        grts_address_after = grts_address,
        grts_address_before = grts_address_replacement
      )
  }

  changed <- .data %>%
    left_join(
      grts_lookup,
      by = join_by(type, grts_address == grts_address_before)
    )

  ### LOGICAL ERROR
  # No need to replace data!
  # grts inaccessible does not necessarily apply to the replacement
  # same for the rest: LocationInfos are rather GRTS-specific

  return(changed)
}

}



# mnmgwdb_data %>%
# loceval_data %>%
#   select(-landowner) %>%
#   sample_n(3) %>%
#   t() %>% knitr::kable()


#_______________________________________________________________________________
### find overlap
# column-specific:
#   - gw::watina_code_* can be ignored
#   - accessibility and recovery must be merged
#   - location_id linked upon upload (loceval_locations, mnmgwdb_locations)
#   - even NAs should be uploaded -> filled via qgis

log_columns <- c(
  "log_user",
  "log_update"
)

data_columns <- c(
  "accessibility_inaccessible",
  "accessibility_revisit",
  "recovery_hints"
)

mnmgwdb_to_loceval <- mnmgwdb_data %>%
  anti_join(
    loceval_data,
    by = join_by(grts_address)
  ) %>%
  select(!!!rlang::syms(c("grts_address", log_columns, data_columns))) %>%
  mutate(
    log_creator = "mnmgwdb",
    log_creation = as.POSIXct(Sys.time())
  )

if (nrow(mnmgwdb_to_loceval) > 0) {
  readr::write_csv2(
    mnmgwdb_to_loceval,
    glue::glue("logs/{todays_date}_LocationInfos_to_loceval{suffix}.csv")
  )
}

loceval_to_mnmgwdb <- loceval_data %>%
  anti_join(
    mnmgwdb_data,
    by = join_by(grts_address)
  ) %>%
  select(!!!rlang::syms(c("grts_address", log_columns, data_columns))) %>%
  mutate(
    log_creator = "locevaldb",
    log_creation = as.POSIXct(Sys.time())
  )

if (nrow(loceval_to_mnmgwdb) > 0) {
  readr::write_csv2(
    loceval_to_mnmgwdb,
    glue::glue("logs/{todays_date}_LocationInfos_to_mnmgwdb{suffix}.csv")
  )
}

# find the common ground and evaluate it
# (1) rows which both tables have in common
#     -> no processing necessary
same_data <- loceval_data %>%
  inner_join(
    mnmgwdb_data,
    by = join_by(grts_address, !!!rlang::syms(data_columns))
  ) %>%
  select(grts_address, !!!rlang::syms(data_columns))

# (2) rows which differ
different_common <- loceval_data %>%
  inner_join(
    mnmgwdb_data,
    by = join_by(grts_address),
    suffix = c("_locevaldb", "_mnmgwdb")
  ) %>%
  select(c(
    "grts_address",
    paste(log_columns, "_locevaldb", sep = ""),
    paste(data_columns, "_locevaldb", sep = ""),
    paste(log_columns, "_mnmgwdb", sep = ""),
    paste(data_columns, "_mnmgwdb", sep = "")
  )) %>%
  anti_join(same_data, by = join_by(grts_address))

message("### Differing Rows:")
different_common %>%
  select(c(
    "grts_address",
    paste(data_columns, "_locevaldb", sep = ""),
    paste(data_columns, "_mnmgwdb", sep = "")
  )) %>%
  knitr::kable()

# TODO timestamp variables are currently not reliable due to
#      system users triggering sync_mod.
#      -> approach "content only"
# per-column:
#   - if NA, NA <- caught by a single coalesce
#   - if same, same <- caught by inverse coalesce comparison
#   - coalesce has the risk of favoring the first <- also set a default case

## for testing...
#   different_common[1, "recovery_hints_locevaldb"] <- "test1"
#   different_common[1, "recovery_hints_mnmgwdb"] <- "different1"
#   different_common[3, "accessibility_inaccessible_locevaldb"] <- FALSE
#   different_common[3, "accessibility_inaccessible_mnmgwdb"] <- TRUE
#   different_common[4, "accessibility_revisit_locevaldb"] <- as.Date(as.POSIXct(Sys.time()))
#   different_common[4, "accessibility_revisit_mnmgwdb"] <- as.Date(as.POSIXct(Sys.time()))-2

# recovery hints:
#   keep info from both databases
#   issue warning for manual adjustment in case of removals/changes
cols <- paste("recovery_hints", c("locevaldb", "mnmgwdb"), sep = "_")
different_common <- different_common %>%
  mutate(
    same_recovery = coalesce(
      coalesce(!!!rlang::syms(cols)) == coalesce(!!!rlang::syms(rev(cols))),
      TRUE
    ),
    recovery_hints = coalesce(!!!rlang::syms(cols)),
    recovery_both = stringr::str_c(!!!rlang::syms(cols), sep = " // ")
  )

# (in)accessibility
#   any inaccessibility is retained
#   issue warning for manual removal inaccessibility
cols <- paste("accessibility_inaccessible", c("locevaldb", "mnmgwdb"), sep = "_")
different_common <- different_common %>%
  mutate(
    same_inaccessibility = coalesce(
      coalesce(!!!rlang::syms(cols)) == coalesce(!!!rlang::syms(rev(cols))),
      TRUE
    ),
    accessibility_inaccessible = coalesce(!!!rlang::syms(cols)),
    inaccessible_any = !is.na(accessibility_inaccessible)
  )

# revisit inaccessibility
#   the minimum date is taken
cols <- paste("accessibility_revisit", c("locevaldb", "mnmgwdb"), sep = "_")
different_common <- different_common %>%
  mutate(
    same_revisit = coalesce(
      coalesce(!!!rlang::syms(cols)) == coalesce(!!!rlang::syms(rev(cols))),
      TRUE
    ),
    accessibility_revisit = coalesce(!!!rlang::syms(cols)),
    revisit_min = pmin(!!!rlang::syms(cols))
  )


different_common <- different_common %>%
  mutate(no_conflict = same_recovery & same_inaccessibility & same_revisit)

# different_common %>%
#   select(
#     grts_address,
#     starts_with("same_"),
#     # recovery_both,
#     inaccessible_any,
#     revisit_min,
#     no_conflict
#   ) %>%
#   knitr::kable()

# different revisit tipps can be concatenated
diff_recovery <- !different_common$same_recovery
different_common[diff_recovery, "recovery_hints"] <-
  different_common[diff_recovery, "recovery_both"]
diff_inacc <- !different_common$same_inaccessibility
different_common[diff_inacc, "accessibility_inaccessible"] <-
  different_common[diff_inacc, "inaccessible_any"]
diff_revisit <- !different_common$same_revisit
different_common[diff_revisit, "accessibility_revisit"] <-
  different_common[diff_revisit, "revisit_min"]

# different_common %>%
#   head(5) %>% t() %>% knitr::kable()

if (nrow(different_common) > 0) {
  readr::write_csv2(
    different_common,
    glue::glue("logs/{todays_date}_LocationInfos_diffs{suffix}.csv")
  )
}

common_location_infos <- different_common %>%
  select(grts_address, !!!rlang::syms(data_columns)) %>%
  mutate(
    log_creator = "maintenance",
    log_creation = as.POSIXct(Sys.time()),
  )

#_______________________________________________________________________________
### UPLOAD
table_label <- "LocationInfos"
characteristic_columns = c("grts_address")
update_cascade_locevaldb <- parametrize_cascaded_update(locevaldb)
update_cascade_mnmgwdb <- parametrize_cascaded_update(mnmgwdb)

locevaldb_lookup <- update_cascade_locevaldb(
  table_label = table_label,
  new_data = mnmgwdb_to_loceval,
  index_columns = c("locationinfo_id"),
  characteristic_columns = characteristic_columns,
  tabula_rasa = FALSE,
  verbose = TRUE
)

mnmgwdb_lookup <- update_cascade_mnmgwdb(
  table_label = table_label,
  new_data = loceval_to_mnmgwdb,
  index_columns = c("locationinfo_id"),
  characteristic_columns = characteristic_columns,
  tabula_rasa = FALSE,
  verbose = TRUE
)


### temptable
# mnmdb <- mnmgwdb
update_conflicting <- function(mnmdb, table_label) {
  srctab <- glue::glue("temp_upd_{tolower(table_label)}")
  trgtab <- mnmdb$get_namestring(table_label)

  # create temp table
  DBI::dbWriteTable(
    mnmdb$connection,
    name = srctab,
    value = common_location_infos,
    overwrite = TRUE,
    temporary = TRUE
  )

  ### build update query
  # updated columns
  ucolumnames <- unlist(lapply(
    names(common_location_infos),
    FUN = function(col) glue::glue("{col} = SRCTAB.{col}")
  ))

  # lookup columns
  lookup_criteria <- unlist(lapply(
    c(characteristic_columns),
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

  # re-link location id
  system(glue::glue(
    "Rscript 102_re_link_foreign_keys.R {suffix}"
  ))

}

table_label <- "LocationInfos"
update_conflicting(mnmgwdb, table_label)
update_conflicting(locevaldb, table_label)



# update landowner
update_landuse_in_locationinfos(locevaldb)
update_landuse_in_locationinfos(mnmgwdb)


message("")
message("________________________________________________________________")
message(" >>>>> Finished syncing location infos. ")
message("________________________________________________________________")
