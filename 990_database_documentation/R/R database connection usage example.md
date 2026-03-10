## Purpose

This list of steps extensively describes how to establish a connection to one of the MNM databases via R.
(It is actually quite simple.)

## Preparation

Trivially, [R has to be installed](https://tutorials.inbo.be/installation/user/user_install_r/), and with it the libraries 
```r
install.packages(c(
  "configr",
  "keyring",
  "DBI",
  "RPostgres",
  "dplyr",
  "sf",
  "here",
  "getPass",
  "glue"
))
```

Second, clone tha [MNE monitoring repo](https://github.com/inbo/n2khab-mne-monitoring) to a local folder [with git](https://tutorials.inbo.be/tutorials/git_introduction/).

```sh
# better use ssh
git clone https://github.com/inbo/n2khab-mne-monitoring <local_folder>
```


Third, [[usage/connection config file|connection config file]] must be prepared.

The config file is best kept central, in the `900_database_organization` folder.
There, it should be `.gitignore`'d, and it only has to be assembled once for various side projects.
It has the option to keep multiple profiles. 

> [!warning]
> Do not share your credentials!

> [!warning]
> Preferrably use a read-only connection to avoid accidental data manipulation.



## Libraries and Functions

First, find the project root directory.
Options: hardcode this path, or use `here::here()` or `file.path()`.

```r
library("rprojroot")
n2khab_mne_monitoring_root_folder <- find_root(is_git_root)
```

All required libraries are stored in our meta-library, and loaded on demand.
```r
source(file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "MNMLibraryCollection.R"
))

load_database_interaction_libraries()

```

Then there is the connection tooling: source the [[R/MNMDatabaseConnection|MNMDatabaseConnection file]].
```r
source(file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "MNMDatabaseConnection.R"
))
```

## Credentials and Configuration
Credentials are stored in a [[usage/connection config file|connection config file]] for easy access.
Here, te filename is `mnm_database_connection.conf`, and the entire path gets stored in variable.
```r
config_filepath <- file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "mnm_database_connection.conf"
)
```


To make the connection object "structure-aware", it requires information from a database structure folder (which comes with the repo).
```r
db_structure_folder <- file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "mnmgwdb_dev_structure"
)
```


A connection profile must be chosen, "profile" refers to the headlines in `mnm_database_connection.conf`.
If in doubt about your code, work on a `_testing` mirror first to test things.
```r
profile <- "test_connection"
```

## connect database

With all these in place, the database can be connected as follows.
```r
mnmdb <- connect_mnm_database(
  config_filepath = config_filepath,
  connection_profile = profile,
  folder = db_structure_folder,
  password = NA
)
```



## usage
There are a number of convenience functions, *cf.* [[R/MNMDatabaseConnection]].

### query all data from a table
```r
mnmdb$query_table("N2kHabStrata") %>%
  sample_n(2) %>% t() %>% knitr::kable()
```

    |n2khabstratum_id    |87                                                          |10                                                          |
    |stratum             |7230                                                        |2120                                                        |
    |type                |7230                                                        |2120                                                        |
    |typelevel           |main_type                                                   |main_type                                                   |
    |main_type           |7230                                                        |2120                                                        |
    |typeclass           |BMF                                                         |CD                                                          |
    |hydr_class          |HC2                                                         |HC1                                                         |
    |groundw_dep         |GD2                                                         |GD0                                                         |
    |flood_dep           |FD0                                                         |FD0                                                         |
    |grts_join_method    |cell_center                                                 |cell_center                                                 |
    |sample_support      |area of type within 1024 m² cell (cell center must be type) |area of type within 1024 m² cell (cell center must be type) |
    |sample_support_code |cell_conditioned_on_center                                  |cell_conditioned_on_center                                  |


### query some columns from a table
```r
mnmdb$query_columns("RandomPoints", c("compass", "angle")) %>%
  sample_n(10) %>% knitr::kable()
```

|compass |  angle|
|:-------|------:|
|WSW     | 240.08|
|ESE     | 117.13|
|ENE     |  58.12|
|NNW     | 341.50|
|ESE     |  90.83|
|WSW     | 258.85|
|ESE     | 113.01|
|NNE     |   8.74|
|WSW     | 264.38|
|ENE     |  61.88|


### table attributes
```r
mnmdb$is_spatial("LocationCells")
```

    TRUE


### organizational
```r
mnmdb$query_table("Versions") %>%
  filter(version_id == mnmdb$load_latest_version_id()) %>%
  t() %>% knitr::kable()
```

|               |                                       |
|:--------------|:--------------------------------------|
|version_id     |6                                      |
|version_tag    |v0.12.0_rvp0.14.0                      |
|data_iteration |4                                      |
|date_applied   |20251210                               |
|notes          |correct filter for post 2026 locations |
