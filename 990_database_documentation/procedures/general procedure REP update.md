---
aliases:
  - REP update
tags:
  - REP
  - maintenance
  - dataupdate
---
Here, I summarize the general steps which need to happen if a new version of the [[glossary/revisit plan|REP]] is released.

## Gather Prior Information

+ #FV usually sends informative e-mails with changelog and summary.
+ Also work through all changes [in the news of `n2khab-mne-designs`](https://github.com/inbo/n2khab-mne-designs/blob/main/100_design_common/010_revisitplan/NEWS.md) to know in advance which changes are to be expected.
+ More info can be found [in the release tag message](https://github.com/inbo/n2khab-mne-designs/tags) and the preceding commits.
+ If [[glossary/code snippets|code snippets]] are adjusted, there is more info to be found [on that respective release tag](https://github.com/inbo/n2khab-mne-monitoring/tags).
+ Generally, the [reference manual](https://inbo.github.io/mnedesigndata/reference/) of `mne-designdata` is a good place to find information on the REP objects.

## Assemble Code and Data 

It might be useful to simultaneously handle two branches of [`n2khab-mne-monitoring`](https://github.com/inbo/n2khab-mne-monitoring): one with the latest "fieldwork support" code by #FV (**`support` branch**, containing the [[glossary/code snippets|"code snippets"]]), the other with the latest, potentially ongoing work on **database tooling**.

+ `git fetch` and `git pull` the latest code snippet branch (or `main`, if they were already merged)
+ `git fetch` and `git pull` the latest database tooling. Then, create a new branch for the REP update (e.g. `git branch rep_update && git switch rep_update`). This is the **`rep_update` branch**.

With the `support` and `rep_update` branches in place, part of the code snippets must be sync'd.
+ Merge the `support` branch into the `rep_update` branch to get the latest changes on functions and procedures:
    + To facilitate merging, support and database development are usually stored in different folders on `n2khab-mne-monitoring`: `020_fieldwork_organization` and `900_database_organization`.
    + To update update with the other, `git switch rep_update && git merge main`
    + (This can actually be done before creating `rep_update`.)
+ Part of the code snippets is moved over and optionally modified to `900_database_organization/401_snippet_selection.R`.
    + This is best done via a "diff tool", which can display and work through file differences. The software [meld](https://meldmerge.org) is warmly recommended.
    + open diff editor with `meld n2khab-mne-monitoring_support/020_fieldwork_organization/code_snippets.R n2khab-mne-monitoring_repupdate/900_database_organization/401_snippet_selection.R`
    + Selectively adjust the `rep_update` file `401_snippet_selection.R`. Note in particular that some sections at the top and bottom of the script are intentionally left different to account for different execution context.
    + Make sure to not miss any adjustments in `020_fieldwork_organization/R` scripts (they should be merged in by the previous step).

With this, the *code* is up to date in the relevant places.
Most certainly, there will also be *new or modified data* in the [[glossary/RData file|RData file]].
Therefore, the next step is to manually download the latest version of the `objects_panflpan5.RData` file (may be a `dev` version on urgent changes).
Alternatively, scripts will re-download the RData file.

Finally and critically, the [[R/checksums|checksums]] must be at the latest version (see below).

## Process and Store Preparatory Data: `403_precalculate_fresh_snippets.R`

With the latest [[glossary/code snippets|code snippets]] and the new [[glossary/RData file|RData]], further precalculation will speed up the subsequent steps.
For that, source the `900_database_organization/403_precalculate_fresh_snippets.R` file.
The script will apply the snippets to the latest `RData`, and calculate yet more objects more proximal to the database content.
This will take a few seconds.

> [!warning] R package versions
> A common cause for issues with this script are deviating R package versions.
> #FV also provides and `renv` file in `020_fieldwork_organization/renv.lock`, which may be used to ensure compatibility.

At the end of the preparation script, the [[R/checksums|checksums]] of relevant data objects in memory are re-calculated and compared to the expected outcome.
Make sure to inspect them (`different_checksums %>% knitr::kable()`): **now** is the time to identify differences and make sure your situation is exactly as intended.

The script saves yet another dump of processed R objects to `900_database_organization/data/fresh_snippet_workspace.RData`.
Loading them instead of the prior data will noticeably reduce loading and processing steps later on.

