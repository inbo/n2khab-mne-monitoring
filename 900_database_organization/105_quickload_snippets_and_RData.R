#!/usr/bin/env Rscript

source("MNMLibraryCollection.R")
load_database_interaction_libraries()

source("MNMDatabaseConnection.R")
source("MNMDatabaseToolbox.R")


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



fieldwork_shortterm_prioritization_by_stratum %>%
  filter(
    grts_address == 1995094,
    field_activity_group == "GWINSTPIEZWELL"
  ) %>%
  t() %>% knitr::kable()
