---
aliases:
  - testing mirror update fails because of empty old_data and join crs mismatch
  - NA crs on spatial tables if table is empty
tags:
  - mirror
  - LocationCells
  - expostcode
started: 2026-05-28
finished: 2026-06-01
execution:
  - FM
status: true
---

This refers to the database copying procedure in `930_copy_database.md` and `933_populate_testing_db.R` for three tables:
`c("LocationCells", "SampleUnitPolygons", "ReplacementCells")`.

Updating the `-testing` mirror would fail due to an empty `old_data` join in `upload_data_and_update_dependencies`:
```R
Error: CRS mismatch: NA vs EPSG:31370`
```

This error was hard to fix, because on repeated / surgical execution of a `copy_single_table`, the procedure would run successfully,
but on the original, looped (`lapply`) walkthrough, it would persistently fail.

> [!warning] Cascaded Deletion
> The reason was a cascaded deletion of `LocationCells` and `SampleUnitPolygons`. 
> That foreign key dependency is introduced in #expostcode (tab "EXPOST" in the structure sheet).
> When copying the whole database, referenced tables are deleted first and deletion cascades.
> This behavior is intended for key safety.

The cascaded deletion is intended.
However, the lookup would fail on these empty spatial tables.
The pk lookup join in `upload_data_and_update_dependencies` was corrected to create an empty dummy lookup in these cases, instead of crashing the joins.
