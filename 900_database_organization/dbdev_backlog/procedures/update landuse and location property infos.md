---
aliases:
tags:
  - LocationInfos
---

The field `landuse` in #LocationInfos collects information we have about the legal status of #Locations to facilitate inquiry of land access permissions and coordination with local rangers.
The displayed data gives a good first indication about publicly available land owner information.
However, not all owners are available from public sources, and thus **landuse information is indicative, but incomplete**.
It resides in the *old `n2khab-mne-design` repo* simply because we lacked time to update and migrate (ask #FV or #FM for information).

The procedure used for updating the field is threefold.
+ First, all data sources are collected to the following path by `010_data_sources.qmd`
`/data/git/n2khab-mne-design-old_landuse/110_design_groundwater/170_accessibility/data`
+ Second, the list of sample locations is loaded and prepared (from the `.RData` file on google drive), using notebook `020_load_sample.qmd`
+ Finally, info about landuse is joined to the geographic location of our samples in `030_join_geometries.qmd`.

This dumps `landuse_export.rds`, which is copied over and used further in the regular database tooling.
The function to use is `update_landuse_in_locationinfos(mnmdb)` from `MNMDatabaseToolbox.R`.