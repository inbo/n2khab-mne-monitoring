---
aliases:
tags:
  - REP
started:
finished:
execution:
status: false
priority:
---


## preparations
- download latest `RData` file, e.g. from `160 Bewerking.../veldwerk/rep_exports/dev/<latest>`
- fetch/pull `snippets_update` branch to a different folder
- optionally merge branch `snippets_update` to get all functions correct and in place
- use meld to bring in changes on `[snippets_update]/020_fieldwork_organization/code_snippets.R` to `[rep_update_branch]/900_database_organization/401_snippet_selection.R`
- `fieldworg_checksums.csv` 
- run `900_database_organization/403_precalculate_fresh_snippets.R` 
	- with link to snippet base path (though merging above did that)
	- `snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))`
	- this will make sure all the extra functions (such as `020_fieldwork_organization/R/calendar_operations_and_priorities.R`) are correct

## test on #staging
- sync staging mirrors

run REP update notebooks step-by-step; first on the `-staging` mirror:
+ `900_database_organization/510_loceval_update_REP.qmd`