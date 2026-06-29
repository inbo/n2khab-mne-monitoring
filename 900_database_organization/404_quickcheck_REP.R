

source("MNMLibraryCollection.R")
load_rep_common_libraries()

# source("MNMDatabaseConnection.R")
# source("MNMDatabaseToolbox.R")




tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()

snippet_base_path <<- rprojroot::find_root(rprojroot::is_git_root)
# TEMPORARY adjustment pointing to adjacent branch (wip)
snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))

fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
reload_rep_code_snippets(fresh_snippet_path)
message(glue::glue("Good morning!
  Loading the REP data and snippets took {tic(toc)} seconds today."
))

verify_rep_objects()

if (nrow(different_checksums) > 0) {
  knitr::kable(different_checksums)
}



#_______________________________________________________________________________
# Replacements for a given GRTS

replacements_rep <-
  stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
  filter(grts_address_final == 1466998) %>%
  select(stratum, grts_address, replacement_cells) %>%
  unnest(replacement_cells) %>%
  filter(!is.na(cellnr_replac)) %>%
  left_join(
    n2khab_strata,
    by = join_by(stratum),
    relationship = "many-to-many" # TODO
  ) %>%
  select(-stratum) %>%
  rename(
    cellnr_replacement = cellnr_replac,
    grts_address_replacement = grts_address_replac,
    replacement_rank = ranknr
  )

replacements_rep %>%
  select(-cellnr_replacement) %>%
  arrange(replacement_rank) %>%
  knitr::kable()


# join geometry column
grts_mh <- n2khab::read_GRTSmh()

grts_mh_index <- dplyr::tibble(
    id = seq_len(terra::ncell(grts_mh)),
    grts_address = values(grts_mh)[, 1]
  ) %>%
  dplyr::filter(!is.na(grts_address))

replacement_locations <- replacements_rep %>%
  add_point_coords_grts(
    grts_var = "grts_address_replacement",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

data <- replacement_locations %>%
  select(rank = replacement_rank, grts = grts_address_replacement, geometry) %>%
  arrange(rank)

# data %>% knitr::kable()

m1 <- data %>%
  mapview::mapview(zcol = "rank")

# leafem::addStaticLabels(m1, label = data$rank)


#_______________________________________________________________________________
# the whole calendar -> fag_stratum_grts_calendar


#_______________________________________________________________________________
# prioritization and subset -> fieldwork_shortterm_prioritization_by_stratum

# 2137206
# 23238 -> 23091910   # Hellebos
# 49692341

fieldwork_shortterm_prioritization_by_stratum %>%
  filter(
    # field_activity_group == "GWINSTPIEZWELL",
    # grts_address %in% c(49896893, 21323197)
    # grts_address %in% c(49692341)
    grts_address %in% c(120110)
  ) %>%
  select(
    domain_part,
    grts_address,
    stratum,
    date_start,
    field_activity_group,
    last_type_assessment_in_field,
    rank,
    priority
  ) %>%
  t() %>% knitr::kable()

# mhq_samples %>%
#   filter(grts_address == 120110)


'

SELECT
  FWCAL.grts_address,
  FWCAL.stratum,
  FWCAL.date_start,
  ACT.activity_group,
  FWCAL.activity_rank,
  FWCAL.priority,
  FWCAL.archive_version_id,
  VIS.date_visit,
  VIS.visit_done
FROM "outbound"."FieldworkCalendar" FWCAL, "inbound"."Visits" VIS
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group
  FROM "metadata"."GroupedActivities"
  GROUP BY activity_group_id, activity_group
  ) AS ACT ON ACT.activity_group_id = VIS.activity_group_id
WHERE
  FWCAL.fieldworkcalendar_id = VIS.fieldworkcalendar_id
  AND FWCAL.grts_address IN (49692341)
;

'

# will go through fwcal update with an eye for
#    (2137206, 49692341)


fieldwork_shortterm_prioritization_by_stratum %>%
  filter(
    field_activity_group %in% c("GWINSTPIEZWELL", "GWSHALLSAMPREADMAN"),
    grts_address %in% c(9488370, 1062930)
  ) %>%
  select(grts_address, stratum, date_start, field_activity_group) %>%
  arrange(grts_address, stratum, date_start, field_activity_group)
