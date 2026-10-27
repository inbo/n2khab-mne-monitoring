# 2026-10-19 This code was written to support INBO's answer to sv34. It extends
# on functionality written in analysis.qmd, and also borrows from
# support_adhoc008_panprogress.R and support_sv896.R in the n2khab-mne-designs
# repo.
#
# It needs the outcomes from queries.qmd (rds files) as well as the REP RData
# file at version 0.18.0 (tag rep_0.18.0).
#
# Both these sources are read from Google Drive.
#
# The REP RData file can be regenerated from the 010_revisitplan directory in
# the n2khab-mne-designs repo (tag rep_0.18.0) with following bash command:
#
# Rscript -e 'bookdown::render_book("index.Rmd", "bookdown::html_document2",
# params = list(save_rdata = TRUE))'

# Setup -------------------------------------------------------------------

## Parameters ----------------------------------------------------------------

reproduce_r_package_versions <- FALSE
update_googlesheet <- FALSE

## Packages -------------------------------------------------------------------

# Optionally reproduce package versions (and require specific R version) with
# renv
if (reproduce_r_package_versions) {
  source("renv/activate.R") # activate renv on demand
  renv::restore() # restore package versions from renv.lock
  # we only proceed if project library is in sync with renv.lock:
  status <- renv::status()
  if (!status$synchronized) {
    stop(
      "Restoring package versions went wrong. ",
      "Please run renv::status() manually, solve problems and try again."
    )
  }
}

library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(forcats)
library(lubridate)
library(sf)
library(n2khab)
library(rprojroot)
library(googlesheets4)
library(googledrive)
library(janitor)

## Paths -------------------------------------------------------------------

gitroot <- find_root(is_git_root)
projroot <- file.path(gitroot, "100_reporting/20261014_analysis_sv34")
datapath <- file.path(projroot, "data")
if (!dir.exists(datapath)) dir.create(datapath, recursive = TRUE)

## Functions ------------------------------------------------------------------

source(file.path(projroot, "functions.R"))

## Data -------------------------------------------------------------------

# Setup for googledrive authentication. Set the appropriate env vars in
# .Renviron and make sure you ran drive_auth() interactively with these settings
# for the first run (or to renew an expired Oauth token).
# See ?gargle::gargle_options for more information.
if (Sys.getenv("GARGLE_OAUTH_EMAIL") != "") {
  options(gargle_oauth_email = Sys.getenv("GARGLE_OAUTH_EMAIL"))
}
if (Sys.getenv("GARGLE_OAUTH_CACHE") != "") {
  options(gargle_oauth_cache = Sys.getenv("GARGLE_OAUTH_CACHE"))
}

# Download and load R objects into global environment
tribble(
  ~filename, ~id,
  "objects_panflpan5.RData", "1a42qESF5L8tfnEseHXbTn9hYR1phqS-S",
  "le_fieldwork.rds", "18hiTDZ1_zKffvMnQh3NYV8s1gVcgyEbh",
  "gw_fieldwork_samples.rds", "1ebXYbMfP3XAO_Qfyp-x4pcu0SD1ks53L",
  "surf_fieldwork.rds", "1YVSWnxjVPgp8-FHZO4rNWFU92SVkz768"
) %>%
  split(.$filename) %>%
  walk(function(df) {
    path <- file.path(datapath, df$filename)
    drive_download(as_id(df$id), path = path, overwrite = TRUE)
  })
load(file.path(datapath, "objects_panflpan5.RData"))
le_fieldwork <- readRDS(file.path(datapath, "le_fieldwork.rds")) %>%
  as_tibble()
gw_fieldwork <- readRDS(file.path(datapath, "gw_fieldwork_samples.rds")) %>%
  as_tibble()
surf_fieldwork <- readRDS(file.path(datapath, "surf_fieldwork.rds")) %>%
  as_tibble()


# Some exploration and checks ---------------------------------------------

le_fieldwork %>% glimpse()
le_fieldwork %>% summary()
le_fieldwork %>% count(scheme)
gw_fieldwork %>% glimpse()
gw_fieldwork %>% summary()
gw_fieldwork %>% count(scheme)
surf_fieldwork %>% glimpse()
surf_fieldwork %>% summary()
surf_fieldwork %>% count(scheme)

# Check that domainpart_grts_n2khab covers all GRTS addresses
list(le_fieldwork, gw_fieldwork, surf_fieldwork) %>%
  walk(function(df) {
    stopifnot({
      df %>%
        anti_join(domainpart_grts_n2khab, join_by(grts_address)) %>%
        nrow() == 0
    })
  })


# Selections and aggregations ---------------------------------------------

# counting planned sampling units
compartment_domainpart_planned <-
  scheme_moco_ps_stratum_sppost_spsamples %>%
  filter(!str_detect(scheme, "^HQ")) %>%
  unnest(sp_poststr_samples) %>%
  inner_join(
    domainpart_grts_n2khab,
    join_by(grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  relevel_domain_part() %>%
  select(scheme, stratum, grts_address, domain_part) %>%
  add_compartment_col() %>%
  arrange(
    compartment,
    domain_part,
    stratum
  ) %>%
  # distinct in order to collapse panel sets and schemes within same compartment
  distinct(
    compartment,
    domain_part,
    stratum,
    grts_address
  ) %>%
  count(compartment, domain_part, name = "total_planned")

# counting sampling units with positive locevals
compartment_domainpart_prepared <-
  le_fieldwork %>%
  filter(loceval_approved == 1L) %>%
  aggregate_fieldwork() %>%
  summarize(
    prepared_end_2025 = n_distinct(sampleunit_id[end_2025]),
    prepared_current = n_distinct(sampleunit_id),
    .by = c(compartment, domain_part)
  )

# counting sampled sampling units
compartment_domainpart_sampled <-
  gw_fieldwork %>%
  bind_rows(surf_fieldwork) %>%
  aggregate_fieldwork() %>%
  summarize(
    sampled_end_2025 = sum(end_2025, na.rm = TRUE),
    sampled_current = n(),
    .by = c(compartment, domain_part)
  )

# stitching previous results, streamline and add totals for Flanders
compartment_domainpart_overview <-
  compartment_domainpart_planned %>%
  left_join(
    compartment_domainpart_prepared,
    join_by(compartment, domain_part),
    relationship = "one-to-one",
    unmatched = "error"
  ) %>%
  left_join(
    compartment_domainpart_sampled,
    join_by(compartment, domain_part),
    relationship = "one-to-one",
    unmatched = "error"
  ) %>%
  # replace NAs by zeroes
  mutate(across(4:last_col(), \(x) coalesce(x, 0))) %>%
  # reorder columns
  relocate(contains("end"), .after = total_planned) %>%
  # add totals for Flanders
  nest(data = -compartment) %>%
  mutate(data = map(data, function(df) {
    df %>%
      adorn_totals(where = "row", name = "Flanders") %>%
      as_tibble()
  })) %>%
  unnest(data) %>%
  # update column name given its hybrid nature since totals were included
  rename(area = domain_part)


# Optionally write to googlesheet --------------------------------------------

if (update_googlesheet) {
  # Googlesheet ID
  gs_id <- "14eOcYK4eIRSGerw_tIH-bwpJp-7Hoh8JI30sSksmcjE"

  compartment_domainpart_overview %>%
    # use Dutch factor levels for the table
    mutate(
      area = fct_recode(
        area,
        `Overige SBZ-H` = "SAC_network_remainder",
        `Buiten SBZ-H` = "Flanders_remainder",
        `Vlaanderen totaal` = "Flanders"
      )
    ) %>%
    write_sheet(
      ss = gs_id,
      sheet = "sv34_tables"
    )

  # also write list of used SAC names
  read_admin_areas(dsn = "sac") %>%
    st_drop_geometry() %>%
    filter(sac_code %in% compartment_domainpart_overview$area) %>%
    distinct(sac_code, sac_name) %>%
    write_sheet(
      ss = gs_id,
      sheet = "sac_names"
    )
}
