
# find the project root directory
library("rprojroot")
n2khab_mne_monitoring_root_folder <- find_root(is_git_root)
# OPTION: hardcode this path, or use `here::here()` or `file.path()`.

# all required libraries are stored in our meta-library...
source(file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "MNMLibraryCollection.R"
))

# ... and loaded on demand.
load_database_interaction_libraries()

# Then there is the connection tooling

source(file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "MNMDatabaseConnection.R"
))


# credentials are stored for easy access
# the `mnm_database_connection.conf` file is best kept central:
# there, it is safely gitignore'd, and it only has to be assembled once.
config_filepath <- file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "mnm_database_connection.conf"
)

db_structure_folder <- file.path(
  n2khab_mne_monitoring_root_folder,
  "900_database_organization",
  "mnmgwdb_dev_structure"
)

# a connection profile must be chosen;
# wich refers to the headlines in "mnm_database_connection.conf"
# if in doubt, work on a "_testing" mirror
profile <- "test_connection"

# connect database
mnmdb <- connect_mnm_database(
  config_filepath = config_filepath,
  connection_profile = profile,
  folder = db_structure_folder,
  password = NA
)



### examples
# There are a number of convenience functions, cf.
# https://github.com/inbo/n2khab-mne-monitoring/blob/main/990_database_documentation/R/MNMDatabaseConnection.md

# query all data from a table
mnmdb$query_table("N2kHabStrata") %>%
  sample_n(2) %>% t() %>% knitr::kable()

# query some columns from a table
mnmdb$query_columns("RandomPoints", c("compass", "angle")) %>%
  sample_n(10) %>% knitr::kable()

# table attributes
mnmdb$is_spatial("LocationCells")

# organizational
mnmdb$query_table("Versions") %>%
  filter(version_id == mnmdb$load_latest_version_id()) %>%
  t() %>% knitr::kable()
