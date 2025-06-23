# Code snippets that support data creation to organize fieldwork: sampling
# units, local replacement cells, field variables, FAG occasions, fieldwork
# prioritization

# Below code can be run from top to bottom, but it is meant to be studied and
# used elsewhere in generating tools & files needed by people that plan or
# execute fieldwork.

# The final section can always be run, regardless of which code in this file has
# been run. It checks that the resulting objects are identical to the ones
# obtained by Floris.


## Setup -----------------------------

library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(lubridate)
library(sf)
library(terra)
library(n2khab)
library(googledrive)
library(readr)
library(rprojroot)

# Set project root; works everywhere as the RStudio project file is in the repo
projroot <- find_root(is_rstudio_project)

# Load some custom GRTS functions
source(file.path(projroot, "R/grts.R"))

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

# Download and load R objects from the POC into global environment
path <- file.path(tempdir(), "objects_panflpan5.RData")
drive_download(as_id("1a42qESF5L8tfnEseHXbTn9hYR1phqS-S"), path = path)
load(path)


## Sampling unit attributes -----------------------------


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

# existing sample support codes and spatial GRTS join methods:
n2khab_types_expanded_properties %>%
  distinct(grts_join_method, sample_support_code, sample_support) %>%
  arrange(grts_join_method, sample_support_code)

# with the currently active modules, module_combo_code has a single unique value
# for each scheme. We take advantage of this uniqueness to keep things as simple
# as possible. Checking that foregoing statement is TRUE:
scheme_moco_ps_stratum_targetpanel_spsamples %>%
  distinct(scheme, module_combo_code) %>%
  {nrow(.) == nrow(distinct(., scheme))}

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
scheme_moco_ps_stratum_targetpanel_spsamples %>%
  filter(grts_address != grts_address_final) %>%
  glimpse









## Sampling unit geometries --------------------------------------

# obtaining geometries of the sampling units themselves:
# - for aquatic types, see code from
#   https://github.com/inbo/n2khab-mne-monitoring/pull/2, but then do use the
#   POC RData file used here
# - for type 7220 (springs) as a whole, see code provided below
# - for terrestrial types, these are cells; see code provided below


# geometries of 7220 units are represented by points, labelled with their GRTS
# address
# ////////////////////////////////////////////////////////////////////////////

flanders_buffer <-
  read_admin_areas(dsn = "flanders") %>%
  st_buffer(40)
# following function will be adapted to support the latest version of the data
# source; for now use version habitatsprings_2020v2
units_7220 <-
  read_habitatsprings(units_7220 = TRUE) %>%
  .[flanders_buffer, ] %>%
  mutate(unit_id = as.character(unit_id)) %>%
  # replacing unit_id by the grts_address
  inner_join(
    units_non_cell_n2khab_grts %>%
      filter(sample_support_code == "spring") %>%
      select(-sample_support_code),
    join_by(unit_id),
    relationship = "one-to-one",
    unmatched = c("error", "drop")
  ) %>%
  # to be solved later; a hack which looses one unit for now:
  filter(!is.na(grts_address)) %>%
  select(
    -unit_id,
    grts_address_final = grts_address
  ) %>%
  relocate(grts_address_final)


# geometries of terrestrial types, excluding 7220: these are cells
# ////////////////////////////////////////////////////////////////////////////

grts_mh <- read_GRTSmh()
# create a spatial index of the GRTS addresses
grts_mh_index <- tibble(
  id = seq_len(ncell(grts_mh)),
  grts_address = values(grts_mh)[, 1]
) %>%
  filter(!is.na(grts_address))


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

# adding the sampling unit attributes to these polygons, arranged as in
# stratum_schemepstargetpanel_spsamples. Note that this duplicates cells with
# multiple strata!
units_cell_polygon_stratum_attribs <-
  units_cell_polygon %>%
  inner_join(
    stratum_schemepstargetpanel_spsamples %>%
      filter(str_detect(sample_support_code, "cell")),
    join_by(grts_address_final),
    relationship = "one-to-many",
    unmatched = "error"
  ) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  relocate(geometry, .after = last_col()) %>%
  arrange(pick(stratum:grts_address))

# merging strata as well for visualization (where we want each row to represent
# another location):
schemepstargetpanel_spsamples_terr <-
  stratum_schemepstargetpanel_spsamples %>%
  filter(str_detect(sample_support_code, "cell")) %>%
  mutate(stratum_scheme_ps_targetpanels = str_c(
    stratum,
    " (",
    grts_join_method,
    ") ",
    " [",
    scheme_ps_targetpanels,
    "]"
  )) %>%
  mutate(
    stratum_scheme_ps_targetpanels =
      str_flatten(stratum_scheme_ps_targetpanels, collapse = " \u2588 ") %>%
      factor(),
    .by = grts_address_final
  ) %>%
  distinct(stratum_scheme_ps_targetpanels, grts_address, grts_address_final)

units_cell_polygon_attrib <-
  units_cell_polygon %>%
  inner_join(
    schemepstargetpanel_spsamples_terr,
    join_by(grts_address_final),
    relationship = "one-to-many",
    unmatched = "error"
  ) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  relocate(geometry, .after = last_col()) %>%
  arrange(stratum_scheme_ps_targetpanels, grts_address)








## Cells for local unit replacement in terrestrial types except 7220 -------


# The units that are eligible for local replacement of a specific cell-based
# sampling unit are the other cells that belong to the same habitatmap polygon.
# In case that this polygon is too large, i.e. exceeds 64 cells, OR if it has at
# least 32 cells in combination with too 'long' dimensions (evaluated from the
# bounding box of the polygon's cell centers), then the replacement cells are
# kept that belong to the same 'level 3' GRTS address as the considered unit (we
# call this the anchor level 3 cell). The level 3 address is the GRTS address of
# the enclosing large cell (256 * 256 quare meters; i.e. 64 level 0 units) of
# the coarser level3 GRTS raster. These replacement cells are still supplemented
# by those of the 'next' level 3 cell of the polygon if such one exists and if
# the anchor level 3 cell has at most 16 cells, which is done to end up with a
# reasonable amount of replacement cells, at the same time applying a decent
# split of the polygon. With 'next level 3 cell' we mean the next level 3
# address that is attached to the polygon, or the lowest one if the anchor level
# 3 cell already had the highest address (since this is how lower level
# addresses cyclically 'walk through' the higher level addresses).

# Getting the replacement cells based on polygon. Beware that we must rely on
# grts_address if grts_address_final is different, so we can just use
# grts_address. In the case of the 'cell' join method, it is possible to get
# multiple polygons attached to the same considered cell, provided that these
# polygons have been labelled to contain the specific type. Further, some
# sampling units concern previously assessed sites with the type, while this
# information is not present in habitatmap_terr, hence also not in below used
# hmt_pol_stratum_grts_cell_all_n2khab, so that the polygon_id is missing. In
# these cases, for now, we will take all replacement cells according to the
# level 3 cell (further down).

stratum_schemepstargetpanel_spsamples_terr_polygonreplacementcells <-
  stratum_schemepstargetpanel_spsamples %>%
  filter(str_detect(sample_support_code, "cell")) %>%
  # adding polygon_id attribute (sometimes missing, sometimes more than one, as
  # explained above)
  left_join(
    hmt_pol_stratum_grts_cell_all_n2khab,
    join_by(stratum, grts_address),
    relationship = "many-to-many",
    unmatched = "drop"
  ) %>%
  # adding all GRTS addresses of the polygon, taking into account the stratum's
  # GRTS join method
  left_join(
    hmt_pol_stratum_grts_cell_all_n2khab %>%
      rename(grts_address_replac = grts_address),
    join_by(stratum, polygon_id),
    relationship = "many-to-many",
    unmatched = "drop"
  ) %>%
  select(-polygon_id) %>%
  # we also determine the 'next GRTS address' per grts_address x stratum, which
  # we will need to determine the 'next level 3 cell' per grts_address x
  # stratum. This acts like 'within polygon', but for cell-joined types several
  # adjacent polygons can be selected which we combine since we abstracted
  # polygon_id away.
  nest(addr_replac = grts_address_replac) %>%
  mutate(
    grts_address_next = map2_int(grts_address, addr_replac, function(grts, ar) {
      if (all(is.na(ar$grts_address_replac))) {
        return(NA_integer_)
      }
      grts_r <- sort(unique(ar$grts_address_replac))
      grts_next_i <- which(grts_r == grts) + 1
      # this gives back NA if grts_next_i is out of range, which is what we
      # want:
      grts_r[grts_next_i]
    })
  ) %>%
  # GRTS addresses of the considered stratum that are member of the sample,
  # either drawn or already in use as a replacement, are considered forbidden
  # area to use as a replacement within the polygon for this stratum, since this
  # would generate problems in the sample management. This step also drops the
  # to-be-replaced address that is under consideration, which is no problem.
  # Note that the following nesting step makes unique rows per stratum x
  # set of replacement cells (~ mostly a single polygon).
  nest(addr_sampled = c(
    scheme_ps_targetpanels,
    grts_address,
    grts_address_final,
    last_type_assessment,
    last_type_assessment_in_field,
    last_inaccessible,
    grts_address_next
  )) %>%
  # filter replacement addresses as described above and make them unique
  mutate(
    addr_replac = map2(addr_replac, addr_sampled, function(ar, as) {
      ar %>%
        filter(
          !(grts_address_replac %in% as$grts_address),
          !(grts_address_replac %in% as$grts_address_final)
        ) %>%
        distinct()
    })
  ) %>%
  # unnest the list columns sequentially, and don't drop rows if no replacement
  # cells are available: we want to keep all sampled locations in this data
  # frame
  unnest(addr_sampled) %>%
  relocate(scheme_ps_targetpanels) %>%
  unnest(addr_replac, keep_empty = TRUE) %>%
  # get cell numbers of the replacement addresses (useful in visualization)
  left_join(
    grts_mh_index %>%
      rename(cellnr_replac = id),
    join_by(grts_address_replac == grts_address),
    relationship = "many-to-one",
    unmatched = "drop"
  ) %>%
  # nesting polygon ids, cellnr & replacement addresses; the number of rows is
  # the same as before the first join above
  nest(polygon_replacement_cells = c(
    cellnr_replac,
    grts_address_replac
  )) %>%
  relocate(polygon_replacement_cells, .after = grts_address_final)

# distribution of the number of polygon replacement cells per sampling unit:
stratum_schemepstargetpanel_spsamples_terr_polygonreplacementcells %>%
  mutate(nrcells = map_int(polygon_replacement_cells, nrow)) %>%
  pull(nrcells) %>%
  summary()


# reading the level0-resolution SpatRaster layer that holds the level 3
# addresses, to prepare for potential restriction to level 3 cells
grts_mh_brick_lev3 <- read_GRTSmh(brick = TRUE)[["level3"]]
# create a spatial index of the level 3 GRTS values
grts_mh_brick_lev3_index <- tibble(
  id = seq_len(ncell(grts_mh_brick_lev3)),
  grts_address = values(grts_mh_brick_lev3)[, 1]
) %>%
  filter(!is.na(grts_address))

# In order to restrict to the level 3 cells, we generate the level 3 replacement
# cells as a separate list column. Beware that we must rely on grts_address if
# grts_address_final is different, so we can just use grts_address. First, we
# set the several criteria to decide about the level 3 restriction.

# Maximum allowed bboxdiag: if exceeded and there are at least 32 replacement
# cells in the polygon, we apply level 3 restriction. Dimensions are based on
# those of a level 3 cell
max_allowed_bboxdiag <- sqrt(2 * 256^2)
min_nrcells_tosplit <- (2^3)^2 / 2
# Maximum allowed number of cells in polygon; based on number of cells in a
# level 3 cell. If exceeded, we apply level 3 restriction.
max_allowed_nrcells <- (2^3)^2
# Maximum nr of replacement cells after first level 3 cell restriction, below
# which it is decided to add the second level 3 cell if available
max_insufficient_nrcells_level3 <- (2^3)^2 / 4

# Resolving the eligible replacement cells (column replacement_cells) from
# polygon replacement cells, level 3 replacement cells (from current + next
# level3-cell) and the application of criteria that determine how to use these.
# The tibbles in the replacement_cells column have a column 'ranknr' to show the
# order in which a replacement cell can be elected: the first positive
# evaluation for the considered stratum determines which cell must be used as
# replacement.

stratum_schemepstargetpanel_spsamples_terr_replacementcells <-
  stratum_schemepstargetpanel_spsamples_terr_polygonreplacementcells %>%
  mutate(
    # calculate diagonal length of bounding box of replacement cell centers
    bboxdiag = map_dbl(polygon_replacement_cells, \(df) {
      coo <- xyFromCell(grts_mh, df$cellnr_replac)
      xdiff <- max(coo[, "x"]) - min(coo[, "x"])
      ydiff <- max(coo[, "y"]) - min(coo[, "y"])
      sqrt(xdiff^2 + ydiff^2)
    }),
    # calculate level3 address of current and next level0 address
    level3_address = convert_level0_to_level3(
      grts_address,
      spatrast = grts_mh,
      spatrast_index = grts_mh_index,
      spatrast_lev3 = grts_mh_brick_lev3
    ),
    level3_address_next = convert_level0_to_level3(
      grts_address_next,
      spatrast = grts_mh,
      spatrast_index = grts_mh_index,
      spatrast_lev3 = grts_mh_brick_lev3
    ),
    # get level 3 replacement cells for current GRTS address
    level3_replacement_cells = get_level3replacement_cellnrs(
      grts_address,
      spatrast = grts_mh,
      spatrast_index = grts_mh_index,
      spatrast_lev3 = grts_mh_brick_lev3,
      spatrast_lev3_index = grts_mh_brick_lev3_index
    ),
    # get level 3 replacement cells for next GRTS address
    nextlevel3_replacement_cells = ifelse(
      is.na(level3_address_next) | level3_address_next == level3_address,
      list(NULL),
      get_level3replacement_cellnrs(
        grts_address_next,
        spatrast = grts_mh,
        spatrast_index = grts_mh_index,
        spatrast_lev3 = grts_mh_brick_lev3,
        spatrast_lev3_index = grts_mh_brick_lev3_index
      )
    ),
    # determine final replacement cells
    replacement_cells = pmap(
      list(
        polygon_replacement_cells,
        bboxdiag,
        level3_replacement_cells,
        nextlevel3_replacement_cells
      ),
      function(poladr, d, lev3adr, nextlev3adr) {
        poladr_unique <- unique(poladr$grts_address_replac)
        if (length(poladr_unique) == 1 && is.na(poladr_unique)) {
          # if polygon missing (but this needs a solution!), just return all
          # cells from the level3-cell
          lev3adr %>%
            mutate(ranknr = row_number(grts_address_replac))
        } else if (
          length(poladr_unique) > max_allowed_nrcells | (
            d > max_allowed_bboxdiag &
            length(poladr_unique) >= min_nrcells_tosplit
          )
        ) {
          # if polygon too large, apply 'polygon x level3-cell' constrained
          # replacement. If the result is quite small, add the next level3-cell
          # if available, but keep its level0 ranks after the first one, since
          # the idea is still to 'split' the polygon in the replacement
          # procedure, only relaxing it if no replacement was possible in the
          # first level3-cell. If no second level3-cell is available, this means
          # that all polygon cells belong to the same level3-cell).
          lev3_constrained <-
            lev3adr %>%
            filter(grts_address_replac %in% poladr_unique) %>%
            mutate(ranknr = row_number(grts_address_replac))
          if (
            !is.null(nextlev3adr) &
            nrow(lev3_constrained) <= max_insufficient_nrcells_level3
          ) {
            bind_rows(
              lev3_constrained,
              nextlev3adr %>%
                filter(grts_address_replac %in% poladr_unique) %>%
                mutate(
                  ranknr =
                    row_number(grts_address_replac) + nrow(lev3_constrained)
                )
            )
          } else {
            lev3_constrained
          }
        } else {
          # if polygon not too large, just apply polygon-constrained replacement
          poladr %>%
            distinct(cellnr_replac, grts_address_replac) %>%
            mutate(ranknr = row_number(grts_address_replac))
        }
      }
    )
  ) %>%
  select(
    -polygon_replacement_cells,
    -bboxdiag,
    -grts_address_next,
    -contains("level3")
  ) %>%
  relocate(replacement_cells, .after = grts_address_final)



# distribution of the number of replacement cells per sampling unit:
stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
  mutate(nrcells = map_int(replacement_cells, nrow)) %>%
  pull(nrcells) %>%
  summary()

# plotting some examples using terra's plot method
plot_replacement_example <- function(
    min_nr_replacement_cells,
    max_nr_replacement_cells
) {
  stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
    mutate(nrcells = map_int(replacement_cells, nrow)) %>%
    filter(between(
      nrcells,
      min_nr_replacement_cells,
      max_nr_replacement_cells
    )) %>%
    slice_sample(n = 1) %>%
    (\(df) {cat(as.character(df$stratum), df$grts_address); df}) %>%
    pluck("replacement_cells", 1) %>%
    pull(cellnr_replac) %>%
    {grts_mh[., drop = FALSE]} %>%
    plot()
}
plot_replacement_example(65, 80)
plot_replacement_example(64, 64)
plot_replacement_example(40, 45)
plot_replacement_example(30, 35)
plot_replacement_example(12, 20)
plot_replacement_example(5, 8)

# we may like to have a single vector of all replacement cell numbers
cellnrs_replacement <-
  stratum_schemepstargetpanel_spsamples_terr_replacementcells %>%
  select(replacement_cells) %>%
  unnest(replacement_cells) %>%
  distinct(cellnr_replac) %>%
  pull(cellnr_replac)

# generate sf points object of all replacement cell centers
coords <- xyFromCell(grts_mh, cellnrs_replacement)
tibble(
  cellnr = cellnrs_replacement,
  grts_address = grts_mh[cellnrs_replacement][, 1],
  x = coords[, "x"],
  y = coords[, "y"]
) %>%
  st_as_sf(coords = c("x", "y"), crs = crs(grts_mh))

# SpatRaster of all replacement cells; note the use of the cells argument:
units_cell_replacement_rast <-
  filter_grtsraster_by_address(
    spatrast = grts_mh,
    spatrast_index = grts_mh_index,
    cells = cellnrs_replacement
  )
global(units_cell_replacement_rast, "notNA")[1, 1] == length(cellnrs_replacement)







## FAG occasions, field activities and variables ------------------------

# field activities (FAs) per field activity group (FAG) in the active modules
# and schemes (considered without the spatial overlap between core and non-core
# schemes). A FAG represents the field activities that must happen during the
# same location visit.
fag_fa <-
  mod_scheme_field_activity %>%
  semi_join(mod_scheme_yrs_moco_ps, join_by(module, scheme)) %>%
  distinct(field_activity_group, field_activity) %>%
  arrange(field_activity_group, field_activity) %>%
  inner_join(
    field_activities,
    join_by(field_activity),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  )

# Field activity sequences define the sequence of activities needed for some
# objective (determining a variable). An activity sequence may be used by
# different schemes, and a single scheme may combine more than one, since
# multiple variables are determined by a single scheme.
faseqs <-
  mod_scheme_field_activity %>%
  semi_join(mod_scheme_yrs_moco_ps, join_by(module, scheme)) %>%
  distinct(activity_sequence, in_aquatic_subset, scheme) %>%
  summarize(
    schemes = str_flatten(scheme, collapse = ", "),
    .by = c(activity_sequence, in_aquatic_subset)
  )

# faseqs_fag_fa shows the individual FAs and FAGs for each field activity
# sequence
faseqs_fag_fa <-
  field_activity_sequences %>%
  semi_join(faseqs, join_by(activity_sequence)) %>%
  inner_join(
    field_activities,
    join_by(field_activity),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  )

# Note that following has a more elaborate set of (partially non-field)
# activities:
actseqs_actgroups_acts <-
  activity_sequences %>%
  semi_join(faseqs, join_by(activity_sequence)) %>%
  inner_join(
    activities %>%
      select(activity, activity_name),
    join_by(activity),
    relationship = "many-to-one",
    unmatched = c("error", "drop")
  )


fag_stratum_grts_calendar

# fag_stratum_grts_calendar defines the needed visits of the spatial sampling
# units and is organized at the FAG level. The rank is an indication of the
# needed order of different FAGs at one location, in the same cycle. In some
# cases repetitions do happen for certain FAGs in a scheme, not all FAGs, as
# prescribed by the date interval.

# Below code brings the FAG calendar at the resolution of each field activity.
fag_fa_stratum_grts_calendar <-
  fag_stratum_grts_calendar %>%
  inner_join(
    fag_fa,
    join_by(field_activity_group),
    relationship = "many-to-many",
    unmatched = c("error", "drop")
  ) %>%
  select(-c(typelevel_certain:inaccessible))

# Note that both calendar objects have a scheme_moco_ps column that makes clear
# which scheme x module combo x panel set the FAG is serving. This may be a
# SUBSET of the same information at the level of the spatial sampling unit
# without considering FAG occasions, since not all field activities necessarily
# serve all schemes.

# Link between field activities and their protocol
fa_protocol <-
  field_activities %>%
  inner_join(
    activities %>%
      select(activity, protocol),
    join_by(field_activity == activity),
    relationship = "one-to-one",
    unmatched = c("error", "drop")
  )

# List of variables / variable sets to be collected in the field (will expand
# when mod_scheme_vars expands). Note 1: currently only target variables are
# involved in mod_scheme_vars. Note 2: this only concerns MNE, so it still
# misses the LSVI field measurement of the LSVITERR & LSVIAQ field activities.
scheme_moco_fa_fieldvar <-
  mod_scheme_vars %>%
  # bring to module combo level
  inner_join(
    mod_scheme_yrs_moco_ps %>%
      distinct(module, scheme, module_combo_code),
    join_by(module, scheme),
    relationship = "many-to-one",
    unmatched = "drop"
  ) %>%
  relocate(module_combo_code, .after = scheme) %>%
  # field activities only
  semi_join(
    field_activities,
    join_by(main_datacollection_method == field_activity)
  ) %>%
  select(
    -module,
    field_activity = main_datacollection_method
  ) %>%
  # make unique after dropping module:
  distinct(
    scheme,
    module_combo_code,
    field_activity,
    variable_set,
    # # not including variable: the (target) variable is either the same as the
    # # measurement variable, or it is an aggregated variable which we don't
    # # measure as such in the field
    # variable,
    measurement_var
  ) %>%
  # variables with the SAMP field activity are variables to be determined in the
  # lab, so not relevant for the fieldwork (but the sampling protocol is)
  filter(!str_detect(field_activity, "SAMP"))








## Processing the FAG calendar wrt prioritizing fieldwork in 2025 ----

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

# Derive an object where stratum x scheme_ps_targetpanels is flattened per
# location x FAG occasion. Beware that in reality, more locations will emerge
# due to local replacement, so this is misleading for counting & planning (but
# useful in spatial visualization)
fag_grts_calendar_2025_attribs <-
  fag_stratum_grts_calendar_2025_attribs %>%
  mutate(
    stratum_scheme_ps_targetpanels = str_c(
      stratum,
      " (",
      grts_join_method,
      ") ",
      " [",
      scheme_ps_targetpanels,
      "]"
    ),
    .keep = "unused"
  ) %>%
  summarize(
    stratum_scheme_ps_targetpanels =
      str_flatten(
        unique(stratum_scheme_ps_targetpanels),
        collapse = " \u2588 "
      ) %>%
      factor(),
    .by = !stratum_scheme_ps_targetpanels
  ) %>%
  relocate(stratum_scheme_ps_targetpanels)

# A simple derived spatial object (as points; see earlier for the actual unit
# geometries). Points are still repeated because of different date_interval &
# FAG values at the same location.
fag_grts_calendar_2025_attribs_sf <-
  fag_grts_calendar_2025_attribs %>%
  add_point_coords_grts(
    grts_var = "grts_address_final",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )

# prioritization of fieldwork 2025:
fieldwork_2025_prioritization <-
  fag_stratum_grts_calendar_2025_attribs %>%
  mutate(
    priority = case_when(
      str_detect(
        scheme_ps_targetpanels,
        "GW_03\\.3:(PS1PANEL(09|10|11|12)|PS2PANEL0[56])|SURF_03\\.4_[a-z]+:PS\\dPANEL03"
      ) ~ 1L,
      str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 2L,
      str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL07|PS2PANEL03)") ~ 3L,
      str_detect(scheme_ps_targetpanels, "GW_03\\.3:PS1PANEL0[56]") ~ 4L,
      .default = 5L
    ),
    wait_watersurface = str_detect(stratum, "^31|^2190_a$"),
    wait_3260 = stratum == "3260",
    wait_7220 = str_detect(stratum, "^7220")
  )

# overview fieldwork prioritization 2025 according to schemes & panels:
fieldwork_2025_targetpanels_prioritization_count <-
  fieldwork_2025_prioritization %>%
  count(
    scheme_ps_targetpanels,
    priority,
    wait_watersurface,
    wait_3260,
    wait_7220,
    field_activity_group
  ) %>%
  arrange(priority, wait_watersurface, wait_3260, wait_7220) %>%
  pivot_wider(names_from = field_activity_group, values_from = n)


gs_id <- "1RXhqlK8nu_BdIiYEbjhjoNnu82wnn6zGfQSdzyi-afI"

# WRITE PIVOT TABLE TO GSHEET:
if (FALSE) {
  fieldwork_2025_targetpanels_prioritization_count %>%
    write_sheet(
      ss = gs_id,
      sheet = "fieldwork_2025_targetpanels_prioritization_count"
    )
}

# overview fieldwork prioritization 2025 according to date intervals:
fieldwork_2025_dates_prioritization_count <-
  fieldwork_2025_prioritization %>%
  count(
    date_interval,
    date_end,
    priority,
    wait_watersurface,
    wait_3260,
    wait_7220,
    field_activity_group
  ) %>%
  arrange(date_end, priority, wait_watersurface, wait_3260, wait_7220) %>%
  select(-date_end) %>%
  pivot_wider(names_from = field_activity_group, values_from = n)

# WRITE PIVOT TABLE TO GSHEET:
if (FALSE) {
  fieldwork_2025_dates_prioritization_count %>%
    mutate(date_interval = as.character(date_interval)) %>%
    write_sheet(
      ss = gs_id,
      sheet = "fieldwork_2025_dates_prioritization_count"
    )
}







## Making selections for orthophoto assessments in 2025 ----------------------

# Making a list of terrestrial locations to be assessed using orthophotos in
# 2025. The procedure evaluates somewhat larger areas in which the unit is
# situated, so we rather have a polygon evaluation which says: can this be the
# targeted stratum or not? Because of expected negative results and hence the
# need for replacements at polygon level (dropping the unit without a local
# field replacement), the locations that are scheduled for field evaluation in
# both 2025 and 2026 are provided for orthophoto evaluation.
orthophoto_2025_stratum_grts <-
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
  # only keep cell-based types (aquatic & 7220 will be more reliable or simply
  # not possible to evaluate on orthophoto)
  filter(str_detect(grts_join_method, "cell")) %>%
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
  relocate(grts_address_final, .after = grts_address) %>%
  relocate(grts_join_method, .after = stratum) %>%
  select(-module_combo_code) %>%
  distinct() %>%
  mutate(
    scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    ),
    loceval_year = ifelse(year(date_start) < 2025, 2025, year(date_start)) %>%
      as.integer()
  ) %>%
  select(-scheme, -targetpanel, -date_start) %>%
  relocate(panel_set, .after = grts_join_method) %>%
  # temporarily nest scheme_ps_targetpanel in order to properly calculate median
  # addresses
  nest(scheme_ps_targetpanels = scheme_ps_targetpanel) %>%
  # set priorities based on loceval_year; for 2026 differentiate according to
  # GRTS address (because lower GRTS addresses have more chance to end up as
  # replacement). The latter is done within spatial poststratum & panel set
  mutate(
    priority_orthophoto = case_when(
      loceval_year == 2025 ~ 1L,
      grts_address <= median(grts_address) ~ 2L,
      .default = 3L
    ),
    .by = c(stratum, loceval_year, panel_set, sp_poststratum)
  ) %>%
  unnest(scheme_ps_targetpanels) %>%
  # collapse panel_set since this may sometimes have different values for the
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
      stratum,
      grts_join_method,
      grts_address,
      grts_address_final,
      sp_poststratum
    )
  ) %>%
  arrange(
    loceval_year,
    priority_orthophoto,
    stratum,
    sp_poststratum,
    grts_address
  )

# unit geometries (cells):
orthophoto_2025_cells <-
  units_cell_polygon %>%
  inner_join(
    orthophoto_2025_stratum_grts,
    join_by(grts_address_final),
    relationship = "one-to-many",
    unmatched = c("drop", "error")
  ) %>%
  relocate(grts_address_final, .after = grts_address) %>%
  relocate(geometry, .after = last_col()) %>%
  arrange(
    loceval_year,
    priority_orthophoto,
    stratum,
    sp_poststratum,
    grts_address
  )

# cell centers:
orthophoto_2025_cell_centers <-
  orthophoto_2025_stratum_grts %>%
  add_point_coords_grts(
    grts_var = "grts_address_final",
    spatrast = grts_mh,
    spatrast_index = grts_mh_index
  )











## Comparing object hashes with reference to verify reproducibility ----------

hashfile <- file.path(projroot, "fieldworg_hashes.csv")
ref_hashes <- read_csv(hashfile, col_types = "cc")
available_obj <- ls()
different_hashes <-
  ref_hashes %>%
  rename(xxh64sum_ref = xxh64sum) %>%
  filter(name %in% available_obj) %>%
  mutate(
    xxh64sum_current = map_chr(name, \(x) {
      # terra objects need special handling;
      # https://github.com/rspatial/terra/issues/1844
      if (inherits(eval(str2lang(x)), c("SpatRaster", "SpatVector"))) {
        x <- paste0("terra::wrap(", x, ")")
      }
      digest::digest(eval(str2lang(x)), algo = "xxhash64")
    })
  ) %>%
  filter(xxh64sum_current != xxh64sum_ref)
if (nrow(different_hashes) > 0) {
  warning(
    "Different hashes detected than expected.",
    "\nPlease inspect the object `different_hashes`."
  )
} else {
  message("All loaded objects are identical to their reference :-)")
}
