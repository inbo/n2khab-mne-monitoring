

source("MNMLibraryCollection.R")
load_poc_common_libraries()
load_database_interaction_libraries()



tic <- function(toc) round(Sys.time() - toc, 1)
toc <- Sys.time()
load_poc_rdata(reload = FALSE, to_env = parent.frame())
message(glue::glue("Good morning!
  Loading the POC data took {tic(toc)} seconds today."
))


fag_stratum_grts_calendar %>%
  filter(lubridate::year(date_start) < 2027) %>%
  # filter(grts_address_final == 1999406) %>%
<<<<<<< HEAD
<<<<<<< HEAD
  filter(grts_address_final %in% c(10119474)) %>%
  # filter(grts_address_final %in% c(41746, 9478930)) %>%
  # filter(field_activity_group == "GWINSTPIEZWELL") %>%
  knitr::kable()

fag_stratum_grts_calendar %>%
  unnest(scheme_moco_ps) %>%
  count(scheme)
=======
  filter(grts_address_final == 9478930) %>%
  # filter(field_activity_group == "GWINSTPIEZWELL") %>%
  knitr::kable()

>>>>>>> b4b58bd (dbinit: raiders of the archived locations)
=======
  filter(grts_address_final %in% c(10119474)) %>%
  # filter(grts_address_final %in% c(41746, 9478930)) %>%
  # filter(field_activity_group == "GWINSTPIEZWELL") %>%
  knitr::kable()

fag_stratum_grts_calendar %>%
  unnest(scheme_moco_ps) %>%
  count(scheme)
>>>>>>> 916978f (dbinit: dashboard ++ archive, counts)

# snippets_path <- "/data/git/n2khab-mne-monitoring_support"
#
# toc <- Sys.time()
# load_poc_code_snippets(snippets_path)
# message(glue::glue(
#   "... loading/executing the code snippets took {tic(toc)}s."
# ))
