
#' Calculate flow direction
#'
#' Calculate the putative flow direction at a given point
#' based on the elevation/slope in the buffer area around it.
#' All calculations will be performed in CRS 31370, hence the output
#' flow vector will be in meters.
#'
#' @details this is the slope-averaged flow direction between
#' cells in a coarse raster grid within a given radius around the location
#' (but excluding the outer rim of cells, where no slope is queried).
#' It uses `terra::terrain(coarse_raster, v = "flowdir", neighbors = 8)`.
#'
#' @param location the point (or polygon) of interest;
#'        an `sf` object of which the `sf::st_coordinates` are used.
#' @param flow_range the buffer extent (in meters) around the location,
#'        which is used to query elevation and calculate flow.
#'        Units are those of the coordinates.
#' @param flow_cellsize the width of a cell in the resampled raster
#'        across which elevation is averaged to calculate flow.
#'        Units are those of the coordinates.
#' @param save_plot_filepath if this is not NA, a summary map of the
#'        flow calculation will be saved as "png" image to the given path.
#'
#' @return c(dx,dy) vector (in meters) of the average flow direction in a
#'        circular area around the location.
#'
#' @examples
#' \dontrun{
#'   location <- sf::st_sfc(sf::st_point(c(225598, 182350), dim = "XY"))
#'   sf::st_crs(location) <- 31370
#'   calculate_flow_direction(location, flow_range = 1024, flow_cellsize = 32)
#' }
#'
calculate_flow_direction <- function(
    location,
    flow_range = 256,
    flow_cellsize = 32,
    save_plot_filepath = NA) {

  # location_raw <- location # currently not necessary to store the data in raw CRS

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("magrittr" = require("magrittr"))
  stopifnot("inbospatial" = require("inbospatial"))
  stopifnot("terra" = require("terra"))

  source(here::here("..", "R", "geometry_helpers.R"))
  source(here::here("..", "R", "spatial_helpers.R"))
  # all calculations will be performed in CRS 31370
  assert_31370(location)

  # only the coordinates are relevant ("xy", but could be "lon/lat")
  xy <- as.data.frame(
      sf::st_coordinates(location)
    ) %>%
    dplyr::rename_with(tolower)

  ### Query DHMV
  # (elevation model of Flanders)
  # within a buffer area
  bbox <- sf::st_bbox(
     c(xmin = min(xy[1]) - flow_range,
       xmax = max(xy[1]) + flow_range,
       ymin = min(xy[2]) - flow_range,
       ymax = max(xy[2]) + flow_range
       ),
     crs = sf::st_crs(31370)
  )

  location_raster <- inbospatial::get_coverage_wcs(
    wcs = "dhmv",
    bbox = bbox,
    layername = "DHMVII_DTM_1m",
    version = "2.0.1",
    wcs_crs = "EPSG:31370",
    resolution = 1
  )

  ### Resample
  # to get a coarse grid
  n_grid <- as.integer(flow_range / flow_cellsize)

  # resample within the buffer range
  coarse_grid <- terra::rast(
    nrows = n_grid, ncols = n_grid,
    xmin = min(xy[1]) - flow_range,
    xmax = max(xy[1]) + flow_range,
    ymin = min(xy[2]) - flow_range,
    ymax = max(xy[2]) + flow_range
  )
  terra::crs(coarse_grid) <- "EPSG:31370"
  coarse_raster <- terra::resample(
    location_raster, coarse_grid,
    method = "lanczos" # method = "bilinear"
  )

  ### calculations
  # slope and flow, using terra::terrain
  slope <- terra::terrain(coarse_raster, v = "slope")
  flow <- terra::terrain(coarse_raster, v = "flowdir", neighbors = 8)

  flow_df <- terra::as.data.frame(flow, xy = TRUE) %>%
    dplyr::left_join(
      terra::as.data.frame(slope, xy = TRUE),
      dplyr::join_by(x, y)
    ) %>%
    dplyr::filter(!is.na(slope))

  flow_sf <- sf::st_as_sf(flow_df, coords = c("x", "y"), crs = 31370)


  flow_df <- cbind(
      sf::st_drop_geometry(flow_sf),
      dplyr::as_tibble(sf::st_coordinates(flow_sf))
    ) %>%
    rename(c("x" = "X", "y" = "Y"))

  fpx <- flow_df[["x"]]
  fpy <- flow_df[["y"]]
  fpz <- flow_df[["flowdir"]]
  fpv <- flow_df[["slope"]]

  # convert direction to angles...
  direction <- 2*pi/8 * log2(fpz)
  direction[!is.finite(direction)] <- NA

  # ... convert direction angles to "dx", "dy"
  dx <- +1*cos(direction)
  dy <- -1*sin(direction)


  ### compute average flow of coarse cells within radius
  # exclude the outer rows of cells (where no slope is queried)
  sel <- within_radius(fpx, fpy, r = flow_range - flow_cellsize)
  flow_vector <- c(average_flow(dx, fpv, sel), average_flow(dy, fpv, sel))

  ### optionally store a quiver plot on a map for vizualization
  if (!is.na(save_plot_filepath)) {

    png(save_plot_filepath,
      width = 120,
      height = 120,
      units = "mm",
      res = 300
    )

    # raster background
    plot(location_raster)

    # flow per cell
    pracma::quiver(
      x = fpx[sel],
      y = fpy[sel],
      u = dx[sel],
      v = dy[sel],
      scale = 8,
      col = "gray"
      )

    # average flow
    pracma::quiver(
      x = xy[[1]],
      y = xy[[2]],
      u = flow_cellsize * flow_vector[[1]],
      v = flow_cellsize * flow_vector[[2]],
      scale = 3,
      col = "darkorange"
    )

    dev.off()
  }

  return(flow_vector)

} # /calculate_flow_direction
