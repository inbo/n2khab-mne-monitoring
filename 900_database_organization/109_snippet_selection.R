# Below is a copy of a subset of the code snippets provided by @florisvdh
# https://github.com/inbo/n2khab-mne-monitoring/tree/fieldworkdata_supportbyfloris
#
# These specific snippets are used for updating the POC in the database.


grts_mh <- read_GRTSmh()
# create a spatial index of the GRTS addresses
grts_mh_index <- tibble(
  id = seq_len(ncell(grts_mh)),
  grts_address = values(grts_mh)[, 1]
) %>%
  filter(!is.na(grts_address))


# attributes of spatial sampling units (~grts_address_final), useful in maps,
# selections and decisions. Note that we *identify* sampling units as stratum x
# grts_address; a unit_id is not needed provided that units don't share the same
# GRTS address (if some still do, it means that the GRTS raster is too coarse
# for those types, and will eventually need extra levels inside those specific
# cells)
scheme_moco_ps_stratum_targetpanel_spsamples <-
  scheme_moco_ps_spsubset_targetfag_stratum_sppost_spsamples_calendar %>%
  inner_join(
    n2khab_strata,
    join_by(stratum),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  inner_join(
    n2khab_types_expanded_properties %>%
      select(type, grts_join_method, sample_support_code),
    join_by(type),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  mutate(
    is_forest = str_detect(type, "^9|^2180|^rbbppm")
  ) %>%
  distinct(
    scheme,
    module_combo_code,
    panel_set,
    stratum,
    # 'aquatic' column will be improved for 7220 later on (now it simply has a
    # duplication (TRUE + FALSE) of all locations)
    is_aquatic = in_aquatic_subset,
    is_forest,
    grts_join_method,
    sample_support_code,
    grts_address,
    grts_address_final,
    targetpanel,
    last_type_assessment = assessment_date,
    last_type_assessment_in_field = assessed_in_field,
    last_inaccessible = inaccessible
  ) %>%
  arrange(pick(scheme:grts_address))


# merging scheme:module_combo_code:panel_set:targetpanel, still distinguishing
# strata separately (even though they may share their location: this is unreal
# in the case of multiple cell-centered strata). For now, not distinguishing
# module_combo as explained above.
stratum_schemepstargetpanel_spsamples <-
  scheme_moco_ps_stratum_targetpanel_spsamples %>%
  select(-module_combo_code) %>%
  mutate(scheme_ps_targetpanel = str_glue(
    "{ scheme }:PS{ panel_set }{ targetpanel }"
  )) %>%
  select(-scheme, -panel_set, -targetpanel) %>%
  nest(scheme_ps_targetpanels = scheme_ps_targetpanel) %>%
  mutate(
    scheme_ps_targetpanels = map_chr(scheme_ps_targetpanels, \(df) {
      str_flatten(df$scheme_ps_targetpanel, collapse = " | ")
    }) %>%
      factor()
  ) %>%
  relocate(scheme_ps_targetpanels) %>%
  arrange(pick(stratum:grts_address))

# Note: if grts_address_final differs from grts_address, then this means a local
# replacement took place already in the past. If now it appears that the stratum
# is no longer present in the field, then a new replacement procedure must take
# place using grts_address as the anchor, provided that the type still occurs in
# the polygon. If not, the absence must be noted and sampling frame + sample are
# to be updated.
# scheme_moco_ps_stratum_targetpanel_spsamples %>%
#   filter(grts_address != grts_address_final) %>%
#   glimpse


# cell centers of the terrestrial sampling units (excluding 7220):
units_cell_cellcenter <-
  stratum_schemepstargetpanel_spsamples %>%
  filter(str_detect(sample_support_code, "cell")) %>%
  add_point_coords_grts(
    grts_var = "grts_address_final",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

# sampling units as raster cells:
units_cell_rast <-
  stratum_schemepstargetpanel_spsamples %>%
  filter(str_detect(sample_support_code, "cell")) %>%
  pull(grts_address_final) %>%
  filter_grtsraster_by_address(spatrast = grts_mh, spatrast_index = grts_mh_index)
set.names(units_cell_rast, "grts_address_final")

# the number of non-NA cells matches the number of unique GRTS addresses
stratum_schemepstargetpanel_spsamples %>%
  filter(str_detect(sample_support_code, "cell")) %>%
  distinct(grts_address_final) %>%
  nrow() %>%
  all.equal(global(units_cell_rast, "notNA")[1, 1])

# representing this limited number of cells as polygons: useful for plotting etc
units_cell_polygon <-
  units_cell_rast %>%
  as.polygons(aggregate = FALSE) %>%
  st_as_sf() %>%
  # to prefer the tibble approach in sf, we need to convert forth and back
  as_tibble() %>%
  # it appears that the CRS is actually retrieved from the tibble, but I don't
  # understand how (so the crs argument below isn't needed)
  st_as_sf(crs = "EPSG:31370")


# mapview(units_cell_polygon)


# This section is primarily intended as support for fieldwork planning by the
# compartment scheme responsible, who will use these R objects directly.

# Derive the FAG calendar for 2025 at the stratum x location x FAG occasion, and
# include some of the location attributes.
fag_stratum_grts_calendar_2025_attribs <-
  fag_stratum_grts_calendar %>%
  select(
    scheme_moco_ps,
    stratum,
    grts_address,
    starts_with("date"),
    field_activity_group,
    rank
  ) %>%
  filter(year(date_start) < 2026) %>%
  # count(date_start, date_end, date_interval) %>%
  # move the fieldwork that was kept for 2024, to 2025, since that is indeed
  # its meaning
  mutate(
    across(c(date_start, date_end), \(x) {
      if_else(year(date_start) == 2024, x + years(1), x)
    }),
    date_interval = interval(
      force_tz(date_start, "Europe/Brussels"),
      force_tz(date_end, "Europe/Brussels")
    )
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      select(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ) %>%
      # deduplicating 7220:
      distinct(),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  select(-module_combo_code) %>%
  # flatten scheme x panel set x targetpanel to unique strings per stratum x
  # location x FAG occasion. Note that the scheme_ps_targetpanels attribute is a
  # shrinked version of the one at the level of the whole sample (see sampling
  # unit attributes in the beginning), since we limited the activities to those
  # planned before 2026, and then generate stratum_scheme_ps_targetpanels as a
  # location attribute. So it says specifically which schemes x panel sets x
  # targetpanels are served by the specific fieldwork at a specific date
  # interval.
  mutate(scheme_ps_targetpanel = str_glue(
    "{ scheme }:PS{ panel_set }{ targetpanel }"
  )) %>%
  select(-scheme, -panel_set, -targetpanel) %>%
  nest(scheme_ps_targetpanels = scheme_ps_targetpanel) %>%
  mutate(
    scheme_ps_targetpanels = map_chr(scheme_ps_targetpanels, \(df) {
      str_flatten(
        unique(df$scheme_ps_targetpanel),
        collapse = " | "
      )
    }) %>%
      factor()
  ) %>%
  relocate(scheme_ps_targetpanels)


#_______________________________________________________________________________
# # TODO there are some activities with different ranks within a sequence.
# activity_groupcount <- activity_sequences %>%
#   distinct(activity, activity_group, rank) %>%
#   count(activity, activity_group) %>%
#   arrange(desc(n))

activity_group_lookup <-
  activity_sequences %>%
    distinct(activity_group, activity)

grouped_activities <-
  activities %>%
  left_join(
    activity_group_lookup,
    join_by(activity),
    relationship = "one-to-many"
  )

# knitr::kable(grouped_activities %>% distinct(activity_group, activity))

# replace group non-sequenced activities with activity name
grouped_activities <- grouped_activities %>%
  mutate_at(
    vars(activity_group, activity, activity_name, protocol),
    as.character
  ) %>%
  mutate(
    activity_group = ifelse(is.na(activity_group), activity, activity_group)
  )
# %>% select(activity, activity_group) %>% tail(10) %>% knitr::kable()


grouped_activities <- grouped_activities %>%
  arrange(activity) %>%
  group_by(activity) %>%
  mutate(activity_id = cur_group_id()) %>%
  ungroup %>%
  arrange(activity_group) %>%
  group_by(activity_group) %>%
  mutate(activity_group_id = cur_group_id()) %>%
  ungroup %>%
  arrange(activity_group, activity) %>%
  group_by(
    activity_group,
    activity
  ) %>%
  mutate(grouped_activity_id = cur_group_id()) %>%
  ungroup %>%
  relocate(
    grouped_activity_id,
    activity_group_id,
    activity_group,
    activity_id,
    activity,
    .before = 1
  )



#_______________________________________________________________________________
# scheme_moco_ps_spsubset_targetfag_stratum_sppost_spsamples_calendar
# scheme_moco_ps_stratum_targetpanel_spsamples
# stratum_schemetargetpanel_spsamples
# stratum_units_non_cell_n2khab


fag_stratum_grts_calendar_2025_attribs_sf <-
  fag_stratum_grts_calendar_2025_attribs %>%
  add_point_coords_grts(
    grts_var = "grts_address_final",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

if (FALSE){
  fag_stratum_grts_calendar_2025_attribs_sf %>%
    head(32) %>%
    sf::st_geometry() %>%
    plot()
}



#_______________________________________________________________________________
# Making a list of terrestrial locations to be assessed using orthophotos in
# 2025. The procedure evaluates somewhat larger areas in which the unit is
# situated, so we rather have a polygon evaluation which says: can this be the
# targeted stratum or not? Because of expected negative results and hence the
# need for replacements at polygon level (dropping the unit without a local
# field replacement), the locations that are scheduled for field evaluation in
# both 2025 and 2026 are provided for orthophoto evaluation.

orthophoto_type_grts <-
  fag_stratum_grts_calendar %>%
  filter(
    str_detect(field_activity_group, "LOCEVAL"),
    year(date_start) < 2027
  ) %>%
  distinct(
    scheme_moco_ps,
    stratum,
    grts_address,
    date_start
  ) %>%
  unnest(scheme_moco_ps) %>%
  # adding location attributes
  inner_join(
    scheme_moco_ps_stratum_targetpanel_spsamples %>%
      select(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_join_method,
        grts_address,
        grts_address_final,
        targetpanel
      ) %>%
      # deduplicating 7220:
      distinct(),
    join_by(scheme, module_combo_code, panel_set, stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  filter(
    # only consider schemes scheduled in 2025:
    str_detect(scheme, "^(GW|HQ)"),
    # only keep cell-based types (aquatic & 7220 will be more reliable or simply
    # not possible to evaluate on orthophoto)
    str_detect(grts_join_method, "cell")
  ) %>%
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
  # add MHQ assessment metadata
  inner_join(
    stratum_grts_n2khab_phabcorrected_no_replacements %>%
      select(stratum, grts_address, assessed_in_field, assessment_date),
    join_by(stratum, grts_address),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  # converting stratum to type (in the usual way, although for the cell-based
  # units the values - but not the factor levels - are identical)
  inner_join(
    n2khab_strata,
    join_by(stratum),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  select(-stratum) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  relocate(type, grts_join_method, .after = panel_set) %>%
  select(-module_combo_code) %>%
  distinct() %>%
  mutate(
    scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    ),
    loceval_year = ifelse(year(date_start) < 2025, 2025, year(date_start)) %>%
      as.integer()
  ) %>%
  select(-targetpanel, -date_start) %>%
  relocate(panel_set, .after = grts_join_method) %>%
  # set priorities based on loceval_year; for 2026 differentiate according to
  # GRTS address (because lower GRTS addresses have more chance to end up as
  # replacement). The latter is done within spatial poststratum & panel set
  mutate(
    priority_orthophoto = case_when(
      # priority 10: in 2025 there may not be time left to do these LOCEVALs in
      # the field (and secondly, this is currently not yet ready XXXXXXXXXXX)
      str_detect(scheme, "^HQ") ~ 10L,
      loceval_year == 2025 ~ 1L,
      grts_address <= median(grts_address) ~ 2L,
      .default = 3L
    ),
    .by = c(type, loceval_year, scheme, panel_set, sp_poststratum)
  ) %>%
  # collapse scheme & panel_set since these can have different values for the
  # same location
  summarize(
    # Note that the scheme_ps_targetpanels attribute is a shrinked version of
    # the one at the level of the whole sample (see sampling unit attributes in
    # the beginning), since we limited the activities to LOCEVAL activities
    # planned before 2027, and then generate stratum_scheme_ps_targetpanels as a
    # location attribute.
    scheme_ps_targetpanels = str_flatten(
      sort(unique(scheme_ps_targetpanel)),
      collapse = " | "
    ) %>%
      factor(),
    loceval_year = min(loceval_year),
    priority_orthophoto = min(priority_orthophoto),
    .by = c(
      type,
      grts_join_method,
      grts_address,
      grts_address_final,
      starts_with("assess"),
      sp_poststratum
    )
  ) %>%
  arrange(
    loceval_year,
    priority_orthophoto,
    type,
    sp_poststratum,
    grts_address
  )
