#!/usr/bin/env Rscript

# This script provides the tools to run the "code snippets" into a fresh environment,
# store everything in another `RData` file,
# and re-load it.
# This just speeds up repeated snippet use.

# start on clear workspace
rm(list = ls(all.names = TRUE))

source("MNMLibraryCollection.R")

load_rep_common_libraries()
load_rep_rdata(reload = TRUE, to_env = globalenv())
# remember gargle login prompt!

# store the current path as "snippet base path" in global env
  # [!] the variable name `snippet_base_path` must be consistent with `401_snippet_selection.R`
snippet_base_path <<- rprojroot::find_root(rprojroot::is_git_root)

# TEMPORARY adjustment pointing to adjacent branch (wip)
snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))

# run code snippets
source("401_snippet_selection.R") # note: this one MUST be sourced
# invisible(capture.output(source("401_snippet_selection.R")))

verify_rep_objects()
different_checksums %>% knitr::kable()

# save the workspace
# cf. https://stackoverflow.com/questions/40862380/in-r-is-it-possible-to-save-the-current-workspace-without-quitting

fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
save.image(file = fresh_snippet_path)

## usage:
# source("MNMLibraryCollection.R")
# fresh_snippet_path <- file.path("data", "fresh_snippet_workspace.RData")
# reload_rep_code_snippets(fresh_snippet_path)
# verify_rep_objects()

