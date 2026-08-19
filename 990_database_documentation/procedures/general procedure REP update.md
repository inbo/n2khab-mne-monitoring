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

> [!important] Announcements
> Normally, database service is continuous, even during the REP updates.
> However, on complex adjustments or major data updates, it is advised to notify colleagues beforehand to prepare them for potential disruptions.
> If fieldwork is intense and people depend on the database, evaluate which moment is best for the REP update.
> (Nevertheless, tests on non-production mirrors may happen, so feel free to proceed.)

Also, make sure to document all the steps of each particular REP update in the [[glossary/dbdev backlog|dbdev backlog]].

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

![[attachments/meld_diff_code_snippets.webp]]

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

## Database Updates

> [!warning] Backups!
> The next steps will most likely affect the database. 
> Things have crashed before and may crash again.
> Make sure to get emergency [[database/backups|backups]].

... but before we do "the real thing", always good to try it on a non-production mirror.
Therefore, it is good practice to update #staging mirrors with the current status of #production, by simply [[database/copy|copying]] the data in a dump-restore manoevre.

There is one script per database (except `mnmsyncdb`, which gets sync'd on the fly and does not contain REP-related metadata tables).
+ `510_loceval_update_REP.qmd` --> #locevaldb 
+ `610_mnmgwdb_update_REP.qmd` --> #mnmgwdb
+ `710_mnmsurfdb_update_REP.qmd` --> #mnmsurfdb

In each of these files, there is a hardcoded line 
```R
suffix <- "-staging"
```
This defines the [[database/mirrors|mirror]] to be used, and the first trial is best done on `-staging` or `-testing`.

Also, the `version_id` in #Versions can change; make sure to give a new version tag and version notes:
```R
  version_tag <- "snip:0.17.0_rep:0.17.0" 
  version_notes <- "quarterly prio update"
```


> [!tip] Chunk-wise Execution
> Although these quarto notebooks can be rendered to speed up the test on `-staging`, it is recommended to go through them chunk-by-chunk to closely follow up the changes they induce and the messages they report.
> 
> Reserve some time and make yourself comfortable: these scripts should be handled carefully and require some attention.

![[attachments/rep_update_error.webp]]

No two REP updates are the same.
Take your time, expect things to crash, and celebrate if everything goes smoothly.


## Finishing

Once all the REP update scripts ran successfully,
reassure the colleagues that they can continue work (they did, anyways),
commit and merge all changes.


## What If It Fails?

> [!note] Don't Panic!
> We have backups.

Because of the general "expect it to fail" mindset, take backups when they are necessary.
If everything was tested on a staging mirror, chances are greatly reduced that the database will rest in an incomplete or corrupted state.
Nonetheless, production failures can happen despite all caution.

> [!important] Create Post-Failure Backups
> If the procedure crashed and you know you have to restore emergency backups,
> make sure to **also dump a "post-failure backup" right before restoring**.
> These dumps can be used to find back intermediate changes, in case colleagues continued work during the failed update.

Communicate.
Focus on preventing future failures (minimum: write a "*post mortem*" in the dev backlog; better: establish fail-safe structures).
Stay patient: It's just a database.

Good luck ;)