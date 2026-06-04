---
aliases:
  - overhaul re-link foreign keys
tags:
started:
finished:
execution:
status: false
---

Script `102_re_link_foreign_keys.R` is generously called from database update procedures.
However, it currently contains code to re-link internals of three databases, which are always all called for updates.
Per status quo, a mirror is selected, yet there is no option to select a database.

The procedure offers itself to be converted to a parametrized function which can execute database- and mirror-specific internal id consistency checks.
There is also some room for optimization of the `stitch` function by having a catalog of characteristic columns which link tables, used to simplify the signature of or wrap the heavily used `stitch_` function.