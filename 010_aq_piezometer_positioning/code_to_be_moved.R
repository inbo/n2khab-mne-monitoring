conflictRules("n2khab", exclude = c("read_schemes", "read_scheme_types"))
library(dplyr)
library(tidyr)
library(stringr)
library(sf)
library(n2khab)
library(n2khabmon)
library(googledrive)

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


# IDs and geometries of the units of aquatic types are defined by below code
# - for watersurface types: wsh_pol
# - for type 7220, partim rivulets: habspring_units_aquatic
# - for type 3260: segm_3260
# =============================================================================

# Manually check data source versions (something to be automated by n2khab
# package in the future, based on preset versions)
# - watersurfaces_hab: version watersurfaces_hab_v6
# - habitatstreams: version habitatstreams_2023
# - habitatsprings: version habitatsprings_2020v2
# - flanders: version "flanders_2018-05-16"
file.path(
  locate_n2khab_data(),
  c(
    "20_processed/watersurfaces_hab",
    "10_raw/habitatsprings",
    "10_raw/habitatstreams",
    "10_raw/flanders"
  )
) %>%
  list.files(full.names = TRUE) %>%
  xxh64sum() %>%
  .[sort(names(.))] %>%
  identical(c(
    flanders.dbf = "d21a599325723682",
    flanders.prj = "2f10404ffd869596",
    flanders.shp = "72fff53084b356be",
    flanders.shx = "1880e141bbcdc6ca",
    habitatsprings.geojson = "7268c26f52fcefe4",
    habitatstreams.dbf = "dee7a620e3bcae0a",
    habitatstreams.lyr = "a120f92d80c92a3a",
    habitatstreams.prj = "7e64ff1751a50937",
    habitatstreams.shp = "5a7d7cddcc52c5df",
    habitatstreams.shx = "b2087e6affe744f4",
    habitatstreams.sld = "2f192b84b4df99e9",
    watersurfaces_hab.gpkg = "e2920c4932008387"
  )) %>%
  stopifnot()

# Generating wsh_pol (unit ID defined by polygon_id)
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
wsh_pol

# Temporary approach to generate segm_3260 (i.e. it will miss a part and some
# may be false positives)
# (unit ID defined by unit_id)
habstream <- read_habitatstreams()
segm_3260 <-
  read_watercourse_100mseg(element = "lines")[habstream, ] %>%
  unite(unit_id, vhag_code, rank)
segm_3260

# Generating habspring_units_aquatic (unit ID defined by unit_id)
flanders_buffer <-
  read_admin_areas(dsn = "flanders") %>%
  st_buffer(40)
habspring_units_aquatic <-
  # following function will be adapted to support the latest version of the data
  # source (just released); for now use version habitatsprings_2020v2
  read_habitatsprings(units_7220 = TRUE) %>%
  .[flanders_buffer, ] %>%
  filter(system_type != "mire")
habspring_units_aquatic



# Define the unit IDs per sample support for aquatic strata in groundwater
# schemes of the considered MNE modules
# =============================================================================

# Download and load a few R objects from the POC (these would currently take too
# much code to regenerate here)
path <- file.path(tempdir(), "objects_for_aq_piezometers_panfl_pan5.RData")
drive_download(as_id("1Z93w-C3XRQ8756W3835JPfxggGEstjKR"), path = path)
env_extradata <- new.env()
load(path, envir = env_extradata)
ls(envir = env_extradata)

# Below object can be used to filter the foregoing geospatial objects, taking
# into account that:
# - rows with sample_support_code 'watersurface' relate to the IDs in wsh_pol
# - rows with sample_support_code 'watercourse_segment' relate to the IDs in
# segm_3260
# - rows with sample_support_code 'spring' relate to the IDs in
# habspring_units_aquatic
stratum_units_grts_aquatic_gw_spsamples_spares <-
  # units per stratum:
  get("stratum_units_non_cell_n2khab", envir = env_extradata) %>%
  # joining GRTS address per unit. A few non-unique GRTS addresses exist, hence
  # 'many-to-one'. See further.
  inner_join(
    get("units_non_cell_n2khab_grts", envir = env_extradata),
    join_by(sample_support_code, unit_id),
    relationship = "many-to-one",
    unmatched = "error"
  ) %>%
  filter(
    # other 'non-cell' types exist so these must be dropped:
    sample_support_code %in% c(
      "watersurface",
      "watercourse_segment",
      "spring"
    ),
    # terrestrial spring units must also be excluded:
    unit_id %in% habspring_units_aquatic$unit_id |
      sample_support_code != "spring"
  ) %>%
  rename(grts_address_final = grts_address) %>%
  # join with samples ('sample_status' defines whether location is 'in the
  # sample' or is a 'spare unit' (spare units = a bunch of 'next' GRTS addresses
  # in the available GRTS series for a stratum))
  inner_join(
    get(
      "scheme_moco_ps_stratum_sppost_spsamples_spares_sf",
      envir = env_extradata
    ) %>%
      st_drop_geometry() %>%
      # only use the samples of groundwater schemes
      filter(str_detect(scheme, "^GW")) %>%
      rename(grts_address_drawn = grts_address) %>%
      # collapse module combos and schemes; hereby select the 'prior'
      # sample_status ("in_sample") across module combos and schemes:
      summarize(
        sample_status = sample_status %>% droplevels() %>% levels() %>%  first(),
        .by = c(
          stratum,
          grts_address_drawn,
          grts_address_final
        )
      ) %>%
      mutate(sample_status = factor(sample_status)),
    join_by(stratum, grts_address_final),
    # A few non-unique GRTS addresses exist, hence 'many-to-one'. We will apply
    # a quick-fix below to meet the requirement of 'one unit sampled per GRTS
    # address', but at least the selection will need further alignment with the
    # (likewise) MHQ solution (to be continued).
    relationship = "many-to-one",
    unmatched = "drop"
  ) %>%
  arrange(sample_support_code, stratum, grts_address_drawn, unit_id) %>%
  # for now, de-duplicate units with the same GRTS address by selecting the 1st
  slice(1, .by = c(stratum, sample_support_code, grts_address_final)) %>%
  select(-grts_address_drawn)
stratum_units_grts_aquatic_gw_spsamples_spares

# Checking that all retained unit IDs from the samples are represented in the
# geospatial objects
stratum_units_grts_aquatic_gw_spsamples_spares %>%
  filter(sample_support_code == "watersurface") %>%
  {all(.$unit_id %in% wsh_pol$polygon_id)} %>%
  stopifnot()

stratum_units_grts_aquatic_gw_spsamples_spares %>%
  filter(sample_support_code == "watercourse_segment") %>%
  {all(.$unit_id %in% segm_3260$unit_id)} %>%
  stopifnot()

stratum_units_grts_aquatic_gw_spsamples_spares %>%
  filter(sample_support_code == "spring") %>%
  {all(.$unit_id %in% habspring_units_aquatic$unit_id)} %>%
  stopifnot()




# Adding some possible inspiration (in Dutch) from a former selection of
# Watina data for analysis
# =============================================================================

# Voor aquatische objecten (excl. 7220) wordt een buffer van 30 meter gebruikt:
# grondwater in de nabije omgeving wordt er beschouwd in relatie tot het
# oppervlaktewater. Voor waterplassen wordt daarbij het watervlak zelf niet in
# rekening gebracht: hier worden dus ringen rond de plas gecreëerd. Voor type
# 7220 wordt een straal van 40 meter gebruikt omdat de locaties slechts als een
# punt zijn gedigitaliseerd.
