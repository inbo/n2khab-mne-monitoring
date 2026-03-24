---
aliases:
  - production protection prompt
tags:
  - credentials
  - fail
started: 2026-03-24
finished:
execution:
  - FM
status: false
---

> [!error] CONFIRMED 
> the `source("405_freeze_calendar.R")` 
> in `510_loceval_update_REP.qmd` 
> caused the connection switch 
> by direct `source("102_re_link_foreign_keys.R")` (no mirror in cmd args)

try wrapping all `source` into subprocess launchers (though a `system("Rscript [...]")` should be fine, too?)
decided to look into https://processx.r-lib.org

*cf.* [[procedures/run script in background]]

#### production protection prompt
also added a prompt which asks the user to confirm update/delete when working on `production`
-> attempt using simple `utils::askYesNo` to be tested in real situations; 
    though I would prefer a popup and click because that makes me move my mouse

    


