---
aliases:
  - background processes
tags:
  - processx
---

I `source` d too much, though I am not a real `source` rer.

Switched to using `processx` on [[timeline/2026-03-24|2026-03-24]]

usage example:
```R
out <- processx::run(
  "Rscript",
  c("102_re_link_foreign_keys.R", suffix),
  spinner = TRUE
)
```

optional: unlock #keyring *ex ante*, to catch segfaults
```R
keyring <- "mnmdb_temp"
if (keyring::keyring_is_locked(keyring)) unlock_keyring(keyring_label = keyring)
```