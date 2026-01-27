
# # comment by @FV:
# Selecting the missing polygons from the habitatmap. Using terra to read and
# filter, because it can handle some exotic geometries from habitatmap out of
# the box (to do this with sf, see /src/miscellaneous/habitatmap.Rmd in the
# interim branch of n2khab-preprocessing, but this is more laborious)
# https://github.com/inbo/n2khab-preprocessing/blob/main/src/miscellaneous/habitatmap.Rmd

# pkgFile = "/home/falk/Downloads/terra_1.8-80.tar.gz"
# install.packages(pkgs=pkgFile, type="source", repos=NULL)
# remotes::install_github("rspatial/terra")

library("dplyr")
library("sf")
library("terra")
# library("n2khab")
sessionInfo()

# habmap_gpkg <- file.path(n2khab::locate_n2khab_data(), "10_raw/habitatmap/habitatmap.gpkg")
# habmap <- terra::vect(habmap_gpkg)

# idea: read via `sf`; looped subset; find erroneous rows

habmap_file <- "/home/falk/data/n2khab_data/10_raw/habitatmap/habitatmap.gpkg"
habmap_raw <- sf::st_read(habmap_file)
# habmap <- terra::vect(habmap_sf)


# terra::is.valid() --> apply to geometries
# row_nr = 2
geometry_type <- habmap_raw %>% sf::st_geometry_type()
levels(geometry_type)
habmap_sf <- cbind(habmap_raw, geometry_type)

for (i in seq_len(1000)) {
  message(i)
  set.seed(i)
  habmap_excerpt <- habmap_sf %>%
    select(OBJECTID, geometry_type)

  habmap_excerpt <- bind_rows(
    habmap_excerpt %>%
      filter(geometry_type == "MULTIPOLYGON") %>%
      sample_n(100),
    habmap_excerpt %>%
      filter(geometry_type == "MULTIPOLYGON") %>%
      sample_n(100)
    )

  habmap_excerpt %>%
    sf::st_write("data/excerpt.gpkg", append = FALSE)

  terra::vect("data/excerpt.gpkg")
}

takes_too_long <- TRUE
if (isFALSE(takes_too_long)) {
  pb <- txtProgressBar(
    min = 0, max = nrow(habmap_sf),
    initial = 0, style = 1
  )

  habmap_errors <- function(row_nr) {
    if (row_nr %% 1000 == 0) message(glue::glue("{row_nr}/{nrow(habmap_sf)}"))
    setTxtProgressBar(pb, row_nr)
    tryCatch(
    {terra::vect(habmap_sf[row_nr,])},
    error = function(cond) {
      message(habmap_sf[row_nr, ])
      return(TRUE)
    })
    return(FALSE)
  }

  has_errors <- lapply(
    seq_len(nrow(habmap_sf)),
    FUN = habmap_errors
  )
  close(pb) # close the progress bar

  habmap_sf <- cbind(habmap_sf, has_errors)
  #terra::vect()
}

# # iteration
# habmap_subset <- habmap_sf[9000:10000, ]
# habmap_valid <- sf::st_is_valid(habmap_subset)
#
# dump_filename <- "./data/habmap_invalids.gpkg"
# sf::st_write(habmap_subset[!habmap_valid, ], dump_filename, append = FALSE)

# saveRDS(habmap_sf, file = "./data/habitatmap_sf.rds")
dump_filename <- "./data/habmap_via_sf.gpkg"

if (isFALSE(takes_too_long)) {
  n <- nrow(habmap_sf)
  step <- 1000
  step_seq <- seq(1, n+1, length.out = as.integer(round(n/step)+1))

  # dump and read in a loop
  for (i in step_seq) {
    habmap_subset <- habmap_sf[i:i+step, ]
    sf::st_write(habmap_subset, dump_filename, append = FALSE, quiet = TRUE)

    # habmap_reload <- sf::st_read(dump_filename, quiet = TRUE)
    habmap_reload <- terra::vect(dump_filename)
  }
}

sf::st_write(habmap_raw, dump_filename, append = FALSE, quiet = FALSE)



habmap_reload <- terra::vect(dump_filename)

habmap_reload %>% sf::st_geometry_type() %>% dplyr::count()
habmap_sf %>% dplyr::as_tibble() %>% count(geometry_type)

musus <- habmap_sf %>% filter(geometry_type == "MULTISURFACE")
valid_musus <- sf::st_make_valid(musus)
# mapview::mapview(habmap_reload)

st_write(
  musus,
  './data/habitatmap_musus.gpkg',
  layer = "habitatmap_musus",
  driver = "GPKG",
  delete_dsn = TRUE
)

gdalUtilities::ogr2ogr(
  './data/habitatmap_musus.gpkg',
  dst_datasource_name = './data/habitatmap_musus_corrected.gpkg',
  explodecollections = T,
  nlt = 'CONVERT_TO_LINEAR'
)


corrected_musus <- sf::st_read("./data/habitatmap_musus_corrected.gpkg")


habmap_path <- file.path(
    n2khab::locate_n2khab_data(),
    "10_raw/habitatmap"
  )
in_file <- file.path(habmap_path, "habitatmap.gpkg")
out_file <- file.path(habmap_path, "habitatmap_fixed.gpkg")

if (file.exists(out_file)) file.remove(out_file)

gdalUtilities::ogr2ogr(
  in_file,
  dst_datasource_name = out_file,
  explodecollections = T,
  nlt = 'CONVERT_TO_LINEAR'
)

packageVersion("terra")
# habmap_vect <- terra::vect(out_file) # :)
