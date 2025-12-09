

source("MNMLibraryCollection.R")
load_poc_common_libraries()

tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()
load_poc_rdata(reload = FALSE, to_env = parent.frame())
message(glue::glue("Good morning!
  Loading the POC data took {tic(toc)} seconds today."
))


snippets_path <- "/data/git/n2khab-mne-monitoring_support"

toc <- Sys.time()
load_poc_code_snippets(snippets_path)
message(glue::glue(
  "... loading/executing the code snippets took {tic(toc)}s."
))

verify_poc_objects()


#_______________________________________________________________________________
# the whole calendar -> fag_stratum_grts_calendar


#_______________________________________________________________________________
# prioritization and subset -> fieldwork_2025_prioritization_by_stratum

# 2137206
# 23238 -> 23091910   # Hellebos
# 49692341

fieldwork_2025_prioritization_by_stratum %>%
  filter(
    # field_activity_group == "GWINSTPIEZWELL",
    # grts_address %in% c(49896893, 21323197)
    grts_address %in% c(49692341)
  ) %>%
  select(
    domain_part,
    grts_address,
    stratum,
    date_start,
    field_activity_group,
    rank,
    priority
  ) %>%
  t() %>% knitr::kable()


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
