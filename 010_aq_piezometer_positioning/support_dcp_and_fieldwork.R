# This code is to support ad-hoc steps and building blocks in making a data
# collection plan or in preparing fieldwork and not to be considered part of the
# POC workflow. Just like the other helper scripts.



# Object wrt spatial coupling of piezometers with MNE sample --------



# This code requires availability of the following objects:
# - scheme_moco_ps_stratum_sppost_spsamples_sf
# - n2khab_strata

# First run setup chunk
#
# Then run:

load(file.path(datapath, "binary/results/objects_panflpan5.RData"))

spsamples_gw_sf_panflpan5 <-
  scheme_moco_ps_stratum_sppost_spsamples_sf %>%
  filter(str_detect(scheme, "^(GW)")) %>%
  distinct(stratum, grts_address, geometry) %>%
  # adding type metadata
  inner_join(
    n2khab_strata,
    join_by(stratum),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  inner_join(
    read_types() %>%
      select(
        type,
        hydr_class,
        hydr_class_shortname
      ),
    join_by(type),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  ) %>%
  select(-type) %>%
  relocate(geometry, .after = last_col())

saveRDS(
  spsamples_gw_sf_panflpan5,
  file.path(datapath, "binary/intermediate/spsamples_gw_sf_panflpan5.rds")
)

write_sf(
  spsamples_gw_sf_panflpan5,
  file.path(datapath, "binary/intermediate/spsamples_gw_sf_panflpan5.gpkg")
)










# Tryout code to create data for piezometer positioning in aq types -------

# This code requires availability of the following objects:
# - scheme_moco_ps_stratum_sppost_spsamples_spares_sf
# - stratum_units_non_cell_n2khab
# - units_non_cell_n2khab_grts

# This code serves as a warmup for similar code in the n2khab-mne-monitoring
# repo, which then only needs the small RData file saved at the end (those
# objects are just from the POC, they're used as input below)

# First run setup chunk
#
# Then run:

load(file.path(datapath, "binary/results/objects_panflpan5.RData"))

n2khab_targetpops <-
  read_scheme_types() %>%
  select(scheme, type)
n2khab_types <-
  n2khab_targetpops %>%
  distinct(type) %>%
  arrange(type)

wsh <- read_watersurfaces_hab(interpreted = TRUE)
wsh_occ <-
  wsh$watersurfaces_types %>%
  # in general we restrict types using an expanded type list tailored to the
  # type levels present in data sources, but for the aquatic types expansion and
  # subsequent collapse of types are redundant steps
  semi_join(n2khab_types, join_by(type))
wsh_pol <-
  wsh$watersurfaces_polygons %>%
  semi_join(wsh_occ, join_by(polygon_id)) %>%
  select(polygon_id)


# Temporary approach to define the 3260 segments (i.e. it will miss a
# part and some may be false positives)
habstream <- read_habitatstreams()
segm_3260 <- read_watercourse_100mseg(element = "lines")[habstream, ] %>%
  unite(unit_id, vhag_code, rank)

flanders_buffer <-
  read_admin_areas(dsn = "flanders") %>%
  st_buffer(40)
habspring_units_aquatic <-
  read_habitatsprings(units_7220 = TRUE) %>%
  .[flanders_buffer, ] %>%
  filter(system_type != "mire")

stratum_units_non_cell_n2khab %>%
  inner_join(
    units_non_cell_n2khab_grts,
    join_by(sample_support_code, unit_id)
  ) %>%
  filter(
    sample_support_code %in% c(
      "watersurface",
      "watercourse_segment",
      "spring"
    ),
    unit_id %in% habspring_units_aquatic$unit_id |
      sample_support_code != "spring"
  ) %>%
  semi_join(
    scheme_moco_ps_stratum_sppost_spsamples_spares_sf %>%
      st_drop_geometry() %>%
      filter(str_detect(scheme, "^GW")),
    join_by(stratum, grts_address == grts_address_final)
  )

# we save these for usage in n2khab-mne-monitoring repo, since they take much
# code to recreate:
save(
  list = c(
    "stratum_units_non_cell_n2khab",
    "units_non_cell_n2khab_grts",
    "scheme_moco_ps_stratum_sppost_spsamples_spares_sf"
  ),
  file = file.path(
    datapath,
    "binary/intermediate/objects_for_aq_piezometers_panfl_pan5.RData"
  )
)
