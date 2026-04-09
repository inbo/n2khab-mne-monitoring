---
aliases:
  - R setup
tags:
  - R
  - usage
  - tools
---
To get started with the database tools on a new computer, several assets have to be in place.
These are collected herein.

## R packages
The file `n2khab-mne-monitoring/900_database_organization/MNMLibraryCollection.R` contains modules of libraries which are required for spinning our database tools.
```r
c(
  "magrittr",
  "dplyr",
  "tidyr",
  "stringr",
  "digest",
  "purrr",
  "lubridate",
  "googledrive",
  "readr",
  "rprojroot",
  "configr",
  "keyring",
  "DBI",
  "RPostgres",
  "here",
  "getPass",
  "glue",
  "sf",
  "terra"
)
```

Additional INBO packages are required, all can be installed from github:
- [`n2khab`](https://github.com/inbo/n2khab?tab=readme-ov-file#installing-and-using-the-n2khab-package): `remotes::install_github("inbo/inbospatial")`
- [`inbospatial`](https://github.com/inbo/inbospatial/?tab=readme-ov-file#installation): `remotes::install_github("inbo/inbospatial")`
- [`inbodb`](https://github.com/inbo/inbodb?tab=readme-ov-file#installation): `remotes::install_github("inbo/inbodb")`

The above listing is extensive; for specific tasks, one might get away with less.

## `n2khab` data (optional)
In addition to the `n2khab` package, `n2khab_data` must be collected if data updates are due.
*This is not necessary for less involved, specific tasks, such as reporting- and read-only queries.*

A script [here](https://github.com/inbo/n2khab-mne-designs/blob/a983f0b75336e4ffa642056ae3a0b4e954b1525b/110_design_groundwater/160_spatial_coupling/zenodo_helper.R) can be used for generously downloading all data at once.
It is certainly not the only download helper for [zenodo](https://zenodo.org/)-hosted sources (e.g. [`zenodor`](https://github.com/FRBCesab/zenodor)).

The `n2khab_data` folder must be in reach of the working folder (*cf.* [`locate_n2khab_data()`](https://inbo.github.io/n2khab/reference/locate_n2khab_data.html)).

Particular focus must be put on potential use of interrim- or preview-stage data source versions, e.g. the habitat map.
Consult the recent #REP instructions and look out for mismatching [[R/checksums|checksums]].
Frequently (or, at least, once) encountered missers are:
- GRTS master sample for habitat monitoring in Flanders <https://doi.org/10.5281/zenodo.2682323>
- `GRTSmh_bricks.tif` <https://doi.org/10.5281/zenodo.3354403>

## REP data and code snippets (optional)
The #REP data predecessors must be acquired (`objects_panflpan5.RData`, simply called "the #RData"); those are shared via our internal sharing platform.

Code snippets to correctly process them are found in `/020_fieldwork_organization/code_snippets.R`.

## database connection
The following components must be correctly set up:
+ [[database/authentication|database authentication]]
+ [[usage/connection config file|connection config file]]

Consider testing the database connection via a non-R pathway to make sure that a passage is available.

## database structure
The [[database/structure|structure]] google sheets must be downloaded as `.ods` and converted to `.csv` files with `x01_init*.py` scripts (see [[database/generation|database generation]]).
Those python scripts might require [[usage/python#initialization|python initialization]] first.
