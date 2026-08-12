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


- sync staging mirrors
- use meld to bring in changes on `[snippets_update]/020_fieldwork_organization/code_snippets.R` to `[rep_update_branch]/900_database_organization/401_snippet_selection.R`
- copy over new `fieldworg_checksums.csv`
- run `900_database_organization/403_precalculate_fresh_snippets.R` 
	- with link to snippet base path
	- `snippet_base_path <<- normalizePath(file.path(snippet_base_path, "..", "n2khab-mne-monitoring_support"))`
	- this will make sure all the extra functions (such as `priorities`) are correct

