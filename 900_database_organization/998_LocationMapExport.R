

library("dplyr")
library("tidyr")
library("stringr")
library("purrr")
library("lubridate")
library("sf")
library("terra")
library("n2khab")
library("googledrive")
library("readr")
library("glue")
library("rprojroot")
library("mapview")
# note: requires "webshot2"
# > install.packages("webshot2")


projroot <- find_root(is_rstudio_project)


# re-load POC data
poc_rdata_path <- file.path("./data", "objects_panflpan5.RData")
load(poc_rdata_path)

# re-run code
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/grts.R")
source("/data/git/n2khab-mne-monitoring_support/020_fieldwork_organization/R/misc.R")
invisible(capture.output(source("050_snippet_selection.R")))
source("051_snippet_transformation_code.R")



sample_units <-
  fag_stratum_grts_calendar %>%
  common_current_calenderfilters() %>%
  distinct(
    scheme_moco_ps,
    stratum,
    grts_address
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      distinct( # <- deduplicating 7220
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  common_current_samplefilters() %>%
  # also join the spatial poststratum, since we need this in setting
  # GRTS-address based priorities
  inner_join(
    scheme_moco_ps_stratum_sppost_spsamples %>%
      unnest(sp_poststr_samples) %>%
      select(-sample_status),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  select(-module_combo_code) %>%
  nest_scheme_ps_targetpanel() %>%
  # add MHQ assessment metadata
  inner_join(
    stratum_grts_n2khab_phabcorrected_no_replacements %>%
      select(stratum, grts_address, assessed_in_field, assessment_date),
    join_by(stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  distinct() %>%
  # convert_stratum_to_type() %>%
  rename_grts_address_final_to_grts_address() %>%
  rename(
    assessment = assessed_in_field,
    assessment_date = assessment_date # triv.
  ) %>%
  relocate(grts_address) %>%
  relocate(grts_join_method, .after = grts_address) %>%
  mutate(
    previous_notes = NA # FUTURE TODO
  ) %>%
  mutate(
    across(c(
        grts_join_method,
        scheme_ps_targetpanels,
        sp_poststratum,
        stratum
      ),
      as.character
    )
  )


sample_locations <- sample_units %>%
  summarize(
    scheme_ps_targetpanels = str_flatten(
      sort(unique(scheme_ps_targetpanels)),
      collapse = " | "
    ) %>% as.character(),
    schemes = str_flatten(
      sort(unique(scheme)),
      collapse = ", "
    ) %>% as.character(),
    strata = str_flatten(
      sort(unique(stratum)),
      collapse = ", "
    ) %>% as.character(),
    .by = c(
      grts_address,
    )
  )

sample_units %>%
  count(scheme)

mnm_gw_locations_sf <- sample_locations  %>%
  select(grts_address, schemes) %>%
  filter(grepl("GW_03.3", schemes)) %>%
  distinct() %>%
  # count(grts_address) %>%
  # arrange(desc(n))
  add_point_coords_grts(
    grts_var = "grts_address",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

mnm_gw_locations_sf <- mnm_gw_locations_sf %>%
  sf::st_transform("wgs84")

mapview::mapview(
    mnm_gw_locations_sf,
    map.types = "OpenStreetMap"
  ) %>%
  leafem::addMouseCoordinates() %>%
  mapview::mapshot2(url = file.path("dumps", "mnm_map", "mnm_gw_map.html"))
